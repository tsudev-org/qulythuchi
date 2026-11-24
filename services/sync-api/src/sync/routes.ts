import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { z } from 'zod';

import { blockIfDeleting, requireUser } from '../auth/middleware';
import type { AppEnv } from '../env';
import { base64, fromBase64, sha256Hex } from '../lib/crypto';
import { ApiError, badRequest } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { RECORD_TYPE, UUID, isEnvelope } from '../lib/validate';
import { requirePro } from '../pro/entitlements';

/**
 * Đồng bộ bản mã (ADR-0004, ADR-0010). Máy chủ KHÔNG đọc được nội dung: chỉ kiểm khung phong bì, lưu, gán `rev`.
 * Hợp nhất theo trường chạy trên thiết bị; thiết bị kéo trước, hợp nhất, rồi đẩy bản đầy đủ.
 */

/** Một bản ghi tối đa 64 KiB bản mã (giao dịch thường ~0,5-1 KB). */
export const MAX_RECORD_BYTES = 64 * 1024;
/** Khối đệm bản ghi 256 B (ADR-0007) ⇒ phong bì bản ghi ngắn nhất = 44 + 256 byte. */
const RECORD_MIN_PADDED = 256;
export const MAX_BATCH = 200;
/** Hạn mức bản ghi mỗi tài khoản Pro (ADR-0016: 200 MiB - lịch sử giao dịch nhiều năm). */
export const ACCOUNT_RECORD_QUOTA = 200 * 1024 * 1024;
const PUSH_BODY_LIMIT = 4 * 1024 * 1024;

const recordIn = z.object({
  id: z.string().regex(UUID),
  type: z.string().regex(RECORD_TYPE),
  wallet_id: z.string().regex(UUID).nullable(),
  // Cho dư gấp đôi để bản ghi quá cỡ bị từ chối RIÊNG (too_large) thay vì làm hỏng cả lô.
  sealed: z.string().max(MAX_RECORD_BYTES * 3),
  deleted: z.boolean().default(false),
});

const pushBody = z.object({ records: z.array(recordIn).min(1).max(MAX_BATCH) });

interface ExistingRow {
  id: string;
  type: string;
  wallet_id: string | null;
  digest: string;
  rev: number;
  size: number;
}

interface RecordRow {
  id: string;
  type: string;
  wallet_id: string | null;
  sealed: ArrayBuffer;
  deleted: number;
  rev: number;
}

type PushResult =
  | { id: string; status: 'applied' | 'unchanged'; rev: number }
  | { id: string; status: 'rejected'; reason: 'invalid_envelope' | 'too_large' | 'identity_mismatch' | 'duplicate' | 'quota' | 'shared_wallet' };

export const syncRoutes = new Hono<AppEnv>();

syncRoutes.use('/api/v1/sync/*', requireUser, blockIfDeleting);

// Đẩy cần TsuDEV Pro (ADR-0016); kéo luôn mở để Pro hết hạn vẫn lấy lại được dữ liệu trong 90 ngày.
syncRoutes.post('/api/v1/sync/push', bodyLimit({ maxSize: PUSH_BODY_LIMIT }), requirePro, async (c) => {
  const { userId, deviceId } = c.get('auth');
  await rateLimit(c.env.DB, `push:${userId}`, 120, 60_000);
  const parsed = pushBody.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) throw badRequest('Gói đồng bộ không hợp lệ.');
  const db = c.env.DB;

  const ids = parsed.data.records.map((r) => r.id);
  const existing = new Map<string, ExistingRow>();
  for (let i = 0; i < ids.length; i += 90) {
    const chunk = ids.slice(i, i + 90);
    const rows = await db
      .prepare(
        `SELECT id, type, wallet_id, digest, rev, size FROM records WHERE user_id = ? AND id IN (${chunk.map(() => '?').join(',')})`,
      )
      .bind(userId, ...chunk)
      .all<ExistingRow>();
    for (const r of rows.results) existing.set(r.id, r);
  }
  const usage = await db
    .prepare('SELECT COALESCE(SUM(size), 0) AS bytes FROM records WHERE user_id = ?')
    .bind(userId)
    .first<{ bytes: number }>();
  let bytes = usage?.bytes ?? 0;
  // Ví đã chia sẻ có không gian riêng (ADR-0015): bản ghi của nó không được quay lại không gian tài khoản (thiết bị cũ
  // chưa biết ví đã chia sẻ ⇒ từ chối, máy khách mới đẩy sang /wallets/:id/push).
  const walletIds = [...new Set(parsed.data.records.map((r) => r.wallet_id).filter((w): w is string => w !== null))];
  const shared = new Set<string>();
  for (let i = 0; i < walletIds.length; i += 90) {
    const chunk = walletIds.slice(i, i + 90);
    const rows = await db
      .prepare(`SELECT id FROM shared_wallets WHERE id IN (${chunk.map(() => '?').join(',')})`)
      .bind(...chunk)
      .all<{ id: string }>();
    for (const r of rows.results) shared.add(r.id);
  }

  const results: PushResult[] = [];
  const writes: D1PreparedStatement[] = [];
  const pending: { index: number; id: string }[] = [];
  const seen = new Set<string>();
  const t = Date.now();

  for (const r of parsed.data.records) {
    if (seen.has(r.id)) {
      results.push({ id: r.id, status: 'rejected', reason: 'duplicate' });
      continue;
    }
    seen.add(r.id);
    if (r.wallet_id !== null && shared.has(r.wallet_id)) {
      results.push({ id: r.id, status: 'rejected', reason: 'shared_wallet' });
      continue;
    }
    const sealed = fromBase64(r.sealed);
    if (!sealed || !isEnvelope(sealed, RECORD_MIN_PADDED)) {
      results.push({ id: r.id, status: 'rejected', reason: 'invalid_envelope' });
      continue;
    }
    if (sealed.length > MAX_RECORD_BYTES) {
      results.push({ id: r.id, status: 'rejected', reason: 'too_large' });
      continue;
    }
    const prev = existing.get(r.id);
    // Danh tính (id, loại, ví) nằm trong AAD của phong bì - không bao giờ đổi được sau khi tạo.
    if (prev && (prev.type !== r.type || prev.wallet_id !== r.wallet_id)) {
      results.push({ id: r.id, status: 'rejected', reason: 'identity_mismatch' });
      continue;
    }
    const digest = await sha256Hex(sealed);
    if (prev?.digest === digest) {
      // Đẩy lại y hệt (mất phản hồi, thử lại) ⇒ lũy đẳng, không tốn rev.
      results.push({ id: r.id, status: 'unchanged', rev: prev.rev });
      continue;
    }
    const nextBytes = bytes - (prev?.size ?? 0) + sealed.length;
    if (nextBytes > ACCOUNT_RECORD_QUOTA) {
      results.push({ id: r.id, status: 'rejected', reason: 'quota' });
      continue;
    }
    bytes = nextBytes;
    // rev lấy từ bộ đếm tài khoản TRONG cùng giao tác (D1 batch tuần tự hóa) ⇒ không trùng rev giữa hai lượt đẩy
    // song song, con trỏ kéo không bao giờ nhảy qua bản ghi.
    writes.push(
      db.prepare('UPDATE users SET rev = rev + 1 WHERE id = ?').bind(userId),
      db
        .prepare(
          `INSERT INTO records (user_id, id, type, wallet_id, sealed, size, digest, deleted, rev, updated_at, device_id)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, (SELECT rev FROM users WHERE id = ?1), ?9, ?10)
           ON CONFLICT(user_id, id) DO UPDATE SET sealed = excluded.sealed, size = excluded.size, digest = excluded.digest,
             deleted = excluded.deleted, rev = excluded.rev, updated_at = excluded.updated_at, device_id = excluded.device_id
           RETURNING rev`,
        )
        .bind(userId, r.id, r.type, r.wallet_id, sealed, sealed.length, digest, r.deleted ? 1 : 0, t, deviceId),
    );
    pending.push({ index: results.length, id: r.id });
    results.push({ id: r.id, status: 'applied', rev: 0 });
  }

  if (writes.length) {
    const out = await db.batch<{ rev: number }>(writes);
    pending.forEach((p, k) => {
      const rev = out[k * 2 + 1]?.results[0]?.rev;
      if (rev === undefined) throw new ApiError(500, 'internal', 'Máy chủ gặp lỗi. Hãy thử lại sau.');
      results[p.index] = { id: p.id, status: 'applied', rev };
    });
  }
  return c.json({ results });
});

const pullQuery = z.object({
  since: z.coerce.number().int().min(0).default(0),
  limit: z.coerce.number().int().min(1).max(500).default(200),
});

syncRoutes.get('/api/v1/sync/pull', async (c) => {
  const { userId, deviceId } = c.get('auth');
  await rateLimit(c.env.DB, `pull:${userId}`, 240, 60_000);
  const q = pullQuery.safeParse(c.req.query());
  if (!q.success) throw badRequest('Tham số không hợp lệ.');
  const { since, limit } = q.data;
  const rows = await c.env.DB.prepare(
    'SELECT id, type, wallet_id, sealed, deleted, rev FROM records WHERE user_id = ? AND rev > ? ORDER BY rev LIMIT ?',
  )
    .bind(userId, since, limit + 1)
    .all<RecordRow>();
  const page = rows.results.slice(0, limit);
  const hasMore = rows.results.length > limit;
  const cursor = page.at(-1)?.rev ?? since;
  // Hỏi từ `since` = thiết bị xác nhận đã LƯU mọi thứ tới `since` ⇒ mốc an toàn cho dọn bia mộ (không dùng `cursor`:
  // trang này có thể chưa kịp lưu).
  await c.env.DB.prepare('UPDATE devices SET pulled_rev = MAX(pulled_rev, ?), last_seen_at = ? WHERE id = ? AND user_id = ?')
    .bind(since, Date.now(), deviceId, userId)
    .run();
  return c.json({
    records: page.map((r) => ({
      id: r.id,
      type: r.type,
      wallet_id: r.wallet_id,
      sealed: base64(new Uint8Array(r.sealed)),
      deleted: r.deleted === 1,
      rev: r.rev,
    })),
    cursor,
    has_more: hasMore,
  });
});
