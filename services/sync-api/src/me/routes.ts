import { Hono } from 'hono';

import { requireUser } from '../auth/middleware';
import type { AppEnv } from '../env';
import { audit } from '../lib/audit';
import { base64 } from '../lib/crypto';
import { ApiError, badRequest } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { UUID } from '../lib/validate';
import { ACCOUNT_FILE_QUOTA } from '../files/routes';
import { ACCOUNT_RECORD_QUOTA } from '../sync/routes';

/** Ân hạn xóa tài khoản (AUTH_AND_ACCOUNT.md mục 12). */
export const DELETION_GRACE_MS = 30 * 24 * 60 * 60 * 1000;

interface UserRow {
  id: string;
  email: string | null;
  email_verified: number;
  display_name: string | null;
  avatar_url: string | null;
  deletion_requested_at: number | null;
}

function iso(ms: number) {
  return new Date(ms).toISOString();
}

export const meRoutes = new Hono<AppEnv>();

meRoutes.use('/api/v1/me', requireUser);
meRoutes.use('/api/v1/me/*', requireUser);

meRoutes.get('/api/v1/me', async (c) => {
  const { userId, deviceId } = c.get('auth');
  const u = await c.env.DB.prepare(
    'SELECT id, email, email_verified, display_name, avatar_url, deletion_requested_at FROM users WHERE id = ?',
  )
    .bind(userId)
    .first<UserRow>();
  if (!u) throw new ApiError(401, 'unauthenticated', 'Tài khoản không còn tồn tại.');
  const deletionAt = u.deletion_requested_at === null ? null : u.deletion_requested_at + DELETION_GRACE_MS;
  return c.json({
    id: u.id,
    email: u.email,
    display_name: u.display_name ?? u.email ?? 'Người dùng',
    avatar_url: u.avatar_url,
    // Hạng B: xác minh email do tsudev.com quản lý; ở đây chỉ phản chiếu.
    email_verified: u.email_verified === 1,
    status: deletionAt === null ? 'active' : 'pending_deletion',
    deletion: deletionAt === null ? null : { scheduled_at: iso(deletionAt), days_remaining: Math.max(0, Math.ceil((deletionAt - Date.now()) / 86_400_000)) },
    device_id: deviceId,
  });
});

meRoutes.get('/api/v1/me/usage', async (c) => {
  const { userId } = c.get('auth');
  const [rec, files] = await c.env.DB.batch<{ n: number; bytes: number }>([
    c.env.DB.prepare('SELECT COUNT(*) AS n, COALESCE(SUM(size), 0) AS bytes FROM records WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('SELECT COUNT(*) AS n, COALESCE(SUM(size), 0) AS bytes FROM files WHERE user_id = ?').bind(userId),
  ]);
  const r = rec?.results[0];
  const f = files?.results[0];
  return c.json({
    records: { count: r?.n ?? 0, bytes: r?.bytes ?? 0, quota_bytes: ACCOUNT_RECORD_QUOTA },
    files: { count: f?.n ?? 0, bytes: f?.bytes ?? 0, quota_bytes: ACCOUNT_FILE_QUOTA },
  });
});

meRoutes.get('/api/v1/me/devices', async (c) => {
  const { userId, deviceId } = c.get('auth');
  const rows = await c.env.DB.prepare(
    `SELECT id, name, platform, created_at, last_seen_at FROM devices
     WHERE user_id = ? AND revoked_at IS NULL ORDER BY last_seen_at DESC`,
  )
    .bind(userId)
    .all<{ id: string; name: string; platform: string; created_at: number; last_seen_at: number }>();
  return c.json({
    devices: rows.results.map((d) => ({
      id: d.id,
      name: d.name,
      platform: d.platform,
      created_at: iso(d.created_at),
      last_seen_at: iso(d.last_seen_at),
      current: d.id === deviceId,
    })),
  });
});

/** Thu hồi một thiết bị của CHÍNH MÌNH (chống IDOR: điều kiện user_id lấy từ phiên). */
meRoutes.delete('/api/v1/me/devices/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = c.req.param('id');
  if (!UUID.test(id)) throw badRequest();
  const db = c.env.DB;
  const res = await db
    .prepare('UPDATE devices SET revoked_at = ? WHERE id = ? AND user_id = ? AND revoked_at IS NULL')
    .bind(Date.now(), id, userId)
    .run();
  if (res.meta.changes !== 1) throw new ApiError(404, 'not_found', 'Không tìm thấy thiết bị.');
  await db.batch([
    db.prepare('DELETE FROM refresh_tokens WHERE device_id = ?').bind(id),
    db.prepare('DELETE FROM web_sessions WHERE device_id = ?').bind(id),
  ]);
  await audit(c, userId, 'device_revoked', id);
  return c.body(null, 204);
});

/**
 * Xuất mọi dữ liệu máy chủ đang giữ của tài khoản (JSON) - quyền mang dữ liệu đi trước khi xóa. Toàn bộ vẫn là bản
 * mã: máy chủ không có gì khác để trả. Tệp đính kèm tải riêng qua `/api/v1/files/:id`.
 */
meRoutes.get('/api/v1/me/export', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `export:${userId}`, 5, 3_600_000);
  const db = c.env.DB;
  const [user, bundle, wallets, records, files] = await db.batch<Record<string, unknown>>([
    db.prepare('SELECT id, email, display_name, created_at FROM users WHERE id = ?').bind(userId),
    db.prepare('SELECT bundle FROM account_bundles WHERE user_id = ?').bind(userId),
    db.prepare('SELECT wallet_id, wrapped FROM wallet_keys WHERE user_id = ?').bind(userId),
    db.prepare('SELECT id, type, wallet_id, sealed, deleted, rev FROM records WHERE user_id = ? ORDER BY rev').bind(userId),
    db.prepare('SELECT id, wallet_id, size, created_at FROM files WHERE user_id = ?').bind(userId),
  ]);
  const b = bundle?.results[0]?.bundle;
  const body = {
    format: 'qulythuchi-server-export',
    v: 1,
    exported_at: new Date().toISOString(),
    user: user?.results[0] ?? null,
    account_bundle: typeof b === 'string' ? (JSON.parse(b) as unknown) : null,
    wallet_keys: (wallets?.results ?? []).map((w) => ({ wallet_id: w.wallet_id, wrapped: base64(new Uint8Array(w.wrapped as ArrayBuffer)) })),
    records: (records?.results ?? []).map((r) => ({
      id: r.id,
      type: r.type,
      wallet_id: r.wallet_id,
      sealed: base64(new Uint8Array(r.sealed as ArrayBuffer)),
      deleted: r.deleted === 1,
      rev: r.rev,
    })),
    files: files?.results ?? [],
  };
  return c.json(body, 200, { 'Content-Disposition': 'attachment; filename="qulythuchi-may-chu.json"' });
});

meRoutes.post('/api/v1/me/deletion', async (c) => {
  const { userId, deviceId } = c.get('auth');
  const t = Date.now();
  await c.env.DB.prepare('UPDATE users SET deletion_requested_at = ? WHERE id = ? AND deletion_requested_at IS NULL')
    .bind(t, userId)
    .run();
  await audit(c, userId, 'deletion_requested', deviceId);
  const row = await c.env.DB.prepare('SELECT deletion_requested_at FROM users WHERE id = ?')
    .bind(userId)
    .first<{ deletion_requested_at: number }>();
  return c.json({ status: 'pending_deletion', scheduled_at: iso((row?.deletion_requested_at ?? t) + DELETION_GRACE_MS) }, 202);
});

meRoutes.delete('/api/v1/me/deletion', async (c) => {
  const { userId, deviceId } = c.get('auth');
  await c.env.DB.prepare('UPDATE users SET deletion_requested_at = NULL WHERE id = ?').bind(userId).run();
  await audit(c, userId, 'deletion_cancelled', deviceId);
  return c.json({ status: 'active' });
});
