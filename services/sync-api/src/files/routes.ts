import { Hono, type Context } from 'hono';

import { blockIfDeleting, requireUser } from '../auth/middleware';
import type { AppEnv } from '../env';
import { badRequest, ApiError } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { ENVELOPE_HEADER, ENVELOPE_OVERHEAD, UUID } from '../lib/validate';
import { assertPro, requirePro } from '../pro/entitlements';

/**
 * Tệp đính kèm (ảnh hóa đơn...) ĐÃ mã hóa ở máy khách (phong bì v1, khối đệm 4096 - ADR-0007).
 * Đi xuyên Worker thay vì URL ký trước của R2 (ADR-0010 mục 4): quyền kiểm ở MỌI lượt tải, không cần cấp khóa S3.
 * Khóa R2: `u/<user_id>/<file_id>` - không thể đọc chéo tài khoản vì user_id lấy từ phiên, không từ URL.
 * Tệp của VÍ CHUNG (P7b, ADR-0017): `w/<wallet_id>/<file_id>`, bảng `wallet_files`, đường `/api/v1/wallets/:wid/files/:id`
 * - kiểm thành viên từ phiên; người ngoài 404; người xem chỉ đọc; ghi theo Pro của chủ ví; tính vào hạn mức chủ ví.
 */
const MAX_FILE_BYTES = 10 * 1024 * 1024;
export const ACCOUNT_FILE_QUOTA = 1024 * 1024 * 1024;
const FILE_MIN_PADDED = 4096;

export const filesRoutes = new Hono<AppEnv>();

filesRoutes.use('/api/v1/files/*', requireUser, blockIfDeleting);
filesRoutes.use('/api/v1/wallets/:wid/files/*', requireUser, blockIfDeleting);

const objectKey = (userId: string, id: string) => `u/${userId}/${id}`;
const walletObjectKey = (walletId: string, id: string) => `w/${walletId}/${id}`;

/** Byte tệp tính vào hạn mức của [ownerId]: tệp cá nhân + tệp trong các ví chung người đó làm chủ. */
async function fileBytesUsed(db: D1Database, ownerId: string): Promise<number> {
  const row = await db
    .prepare(
      `SELECT (SELECT COALESCE(SUM(size), 0) FROM files WHERE user_id = ?1)
            + (SELECT COALESCE(SUM(f.size), 0) FROM wallet_files f JOIN shared_wallets w ON w.id = f.wallet_id
                WHERE w.owner_id = ?1) AS bytes`,
    )
    .bind(ownerId)
    .first<{ bytes: number }>();
  return row?.bytes ?? 0;
}

/** Xóa mọi đối tượng R2 dưới [prefix] (theo trang 500). */
export async function deleteR2Prefix(bucket: R2Bucket, prefix: string) {
  for (;;) {
    const page = await bucket.list({ prefix, limit: 500 });
    if (page.objects.length) await bucket.delete(page.objects.map((o) => o.key));
    if (!page.truncated) break;
  }
}

/** Xóa tệp R2 của mọi ví chung [ownerId] làm chủ - gọi TRƯỚC khi xóa dòng shared_wallets (CASCADE không đụng R2). */
export async function deleteOwnedWalletFiles(env: { DB: D1Database; FILES: R2Bucket }, ownerId: string) {
  const owned = await env.DB.prepare('SELECT id FROM shared_wallets WHERE owner_id = ?').bind(ownerId).all<{ id: string }>();
  for (const w of owned.results) await deleteR2Prefix(env.FILES, `w/${w.id}/`);
}

/** Đọc + kiểm thân tệp đã khai Content-Length (chung cho tệp cá nhân và tệp ví). */
function declaredLength(c: Context<AppEnv>): number {
  const declared = Number(c.req.header('Content-Length'));
  if (!Number.isInteger(declared) || declared <= 0) throw new ApiError(411, 'length_required', 'Thiếu kích thước tệp.');
  if (declared > MAX_FILE_BYTES) throw new ApiError(413, 'too_large', 'Tệp quá lớn (tối đa 10 MB).');
  if (declared < ENVELOPE_OVERHEAD + FILE_MIN_PADDED) throw badRequest('Tệp không phải bản mã hợp lệ.');
  return declared;
}

async function sealedBody(c: Context<AppEnv>, declared: number): Promise<Uint8Array> {
  const body = new Uint8Array(await c.req.arrayBuffer());
  if (body.length !== declared || !ENVELOPE_HEADER.every((b, i) => body[i] === b)) {
    throw badRequest('Tệp không phải bản mã hợp lệ.');
  }
  return body;
}

function download(obj: R2ObjectBody): Response {
  return new Response(obj.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Length': String(obj.size),
      'Content-Disposition': 'attachment',
      'Cache-Control': 'private, no-store',
    },
  });
}

function fileId(raw: string): string {
  if (!UUID.test(raw)) throw badRequest('Mã tệp không hợp lệ.');
  return raw;
}

// Tải tệp lên cần TsuDEV Pro (ADR-0016); tải về/xoá luôn mở.
filesRoutes.put('/api/v1/files/:id', requirePro, async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  await rateLimit(c.env.DB, `files-w:${userId}`, 60, 60_000);
  const walletId = c.req.query('wallet_id') ?? null;
  if (walletId !== null && !UUID.test(walletId)) throw badRequest('Mã ví không hợp lệ.');
  const declared = declaredLength(c);
  if (walletId !== null) {
    const shared = await c.env.DB.prepare('SELECT 1 AS x FROM shared_wallets WHERE id = ?').bind(walletId).first();
    // Tệp của ví chung phải nằm ở không gian ví (thành viên khác mới đọc được) - như /sync/push.
    if (shared) throw new ApiError(409, 'shared_wallet', 'Ví này là ví chung, hãy tải tệp lên không gian của ví.');
  }

  const existing = await c.env.DB.prepare('SELECT size FROM files WHERE user_id = ? AND id = ?')
    .bind(userId, id)
    .first<{ size: number }>();
  // Tệp đính kèm là bất biến (nội dung đổi = tệp mới): tải lại cùng id là lũy đẳng, không ghi đè.
  if (existing) return c.json({ id, size: existing.size, status: 'unchanged' });
  if ((await fileBytesUsed(c.env.DB, userId)) + declared > ACCOUNT_FILE_QUOTA) {
    throw new ApiError(507, 'quota', 'Đã hết dung lượng tệp đính kèm của tài khoản.');
  }

  const body = await sealedBody(c, declared);
  await c.env.FILES.put(objectKey(userId, id), body, {
    httpMetadata: { contentType: 'application/octet-stream' },
  });
  await c.env.DB.prepare('INSERT INTO files (user_id, id, wallet_id, size, created_at) VALUES (?, ?, ?, ?, ?)')
    .bind(userId, id, walletId, body.length, Date.now())
    .run();
  return c.json({ id, size: body.length, status: 'stored' }, 201);
});

filesRoutes.get('/api/v1/files/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  await rateLimit(c.env.DB, `files-r:${userId}`, 300, 60_000);
  const row = await c.env.DB.prepare('SELECT size FROM files WHERE user_id = ? AND id = ?').bind(userId, id).first();
  const obj = row ? await c.env.FILES.get(objectKey(userId, id)) : null;
  if (!obj) throw new ApiError(404, 'not_found', 'Không tìm thấy tệp.');
  return download(obj);
});

filesRoutes.delete('/api/v1/files/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  const row = await c.env.DB.prepare('DELETE FROM files WHERE user_id = ? AND id = ? RETURNING id').bind(userId, id).first();
  if (row) await c.env.FILES.delete(objectKey(userId, id));
  return c.body(null, 204);
});

// ------------------------------------------------------------------ Tệp của ví chung (P7b, ADR-0017)

type Role = 'owner' | 'editor' | 'viewer';

/** Thành viên ví từ phiên; không phải thành viên ⇒ 404 như ví không tồn tại. */
async function walletMember(c: Context<AppEnv>): Promise<{ wid: string; role: Role; owner_id: string }> {
  const wid = c.req.param('wid') ?? '';
  if (!UUID.test(wid)) throw new ApiError(404, 'not_found', 'Không tìm thấy ví chung.');
  const row = await c.env.DB.prepare(
    `SELECT m.role, w.owner_id FROM wallet_members m JOIN shared_wallets w ON w.id = m.wallet_id
      WHERE m.wallet_id = ? AND m.user_id = ?`,
  )
    .bind(wid, c.get('auth').userId)
    .first<{ role: Role; owner_id: string }>();
  if (!row) throw new ApiError(404, 'not_found', 'Không tìm thấy ví chung.');
  return { wid, ...row };
}

const readOnly = () => new ApiError(403, 'read_only', 'Bạn chỉ có quyền xem ví này.');

filesRoutes.put('/api/v1/wallets/:wid/files/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  await rateLimit(c.env.DB, `files-w:${userId}`, 60, 60_000);
  const m = await walletMember(c);
  if (m.role === 'viewer') throw readOnly();
  // Ví chung chạy bằng Pro của CHỦ ví (ADR-0016 Q5), như /wallets/:wid/push.
  await assertPro(c, m.owner_id, 'owner_no_pro');
  const declared = declaredLength(c);
  const existing = await c.env.DB.prepare('SELECT size FROM wallet_files WHERE wallet_id = ? AND id = ?')
    .bind(m.wid, id)
    .first<{ size: number }>();
  if (existing) return c.json({ id, size: existing.size, status: 'unchanged' });
  if ((await fileBytesUsed(c.env.DB, m.owner_id)) + declared > ACCOUNT_FILE_QUOTA) {
    throw new ApiError(507, 'quota', 'Chủ ví đã hết dung lượng tệp đính kèm.');
  }
  const body = await sealedBody(c, declared);
  await c.env.FILES.put(walletObjectKey(m.wid, id), body, { httpMetadata: { contentType: 'application/octet-stream' } });
  await c.env.DB.prepare(
    'INSERT INTO wallet_files (wallet_id, id, size, uploader_id, created_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT DO NOTHING',
  )
    .bind(m.wid, id, body.length, userId, Date.now())
    .run();
  return c.json({ id, size: body.length, status: 'stored' }, 201);
});

filesRoutes.get('/api/v1/wallets/:wid/files/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  await rateLimit(c.env.DB, `files-r:${userId}`, 300, 60_000);
  const m = await walletMember(c);
  const row = await c.env.DB.prepare('SELECT 1 AS x FROM wallet_files WHERE wallet_id = ? AND id = ?').bind(m.wid, id).first();
  const obj = row ? await c.env.FILES.get(walletObjectKey(m.wid, id)) : null;
  if (!obj) throw new ApiError(404, 'not_found', 'Không tìm thấy tệp.');
  return download(obj);
});

filesRoutes.delete('/api/v1/wallets/:wid/files/:id', async (c) => {
  const id = fileId(c.req.param('id'));
  const m = await walletMember(c);
  if (m.role === 'viewer') throw readOnly();
  const row = await c.env.DB.prepare('DELETE FROM wallet_files WHERE wallet_id = ? AND id = ? RETURNING id').bind(m.wid, id).first();
  if (row) await c.env.FILES.delete(walletObjectKey(m.wid, id));
  return c.body(null, 204);
});
