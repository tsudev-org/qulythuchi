import { getCookie } from 'hono/cookie';
import { createMiddleware } from 'hono/factory';

import type { AppEnv } from '../env';
import { ApiError } from '../lib/errors';
import { sha256Hex } from '../lib/crypto';
import { CSRF_HEADER, SESSION_COOKIE, verifyAccessToken } from './tokens';

/**
 * Xác thực mọi đường `/api/v1/*` cần tài khoản:
 * - App: `Authorization: Bearer <access token>`; thiết bị bị thu hồi ⇒ 401 ngay (kiểm D1 mỗi lượt).
 * - Web: cookie `__Host-qt_session` (HttpOnly, Secure, SameSite=Strict). Phương thức ghi ĐÒI `Origin` đúng gốc +
 *   header `X-Qt-Csrf: 1`.
 */
export const requireUser = createMiddleware<AppEnv>(async (c, next) => {
  const header = c.req.header('Authorization');
  if (header?.startsWith('Bearer ')) {
    const { userId, deviceId } = await verifyAccessToken(c.env, header.slice(7).trim());
    const device = await c.env.DB.prepare(
      `SELECT d.revoked_at, u.deletion_requested_at FROM devices d JOIN users u ON u.id = d.user_id
       WHERE d.id = ? AND d.user_id = ?`,
    )
      .bind(deviceId, userId)
      .first<{ revoked_at: number | null; deletion_requested_at: number | null }>();
    if (!device || device.revoked_at !== null) {
      throw new ApiError(401, 'device_revoked', 'Thiết bị này đã bị đăng xuất khỏi tài khoản.');
    }
    c.set('auth', { userId, deviceId, via: 'bearer', pendingDeletion: device.deletion_requested_at !== null });
    await next();
    return;
  }
  const cookie = getCookie(c, SESSION_COOKIE);
  if (!cookie) throw new ApiError(401, 'unauthenticated', 'Bạn cần đăng nhập.');
  const method = c.req.method;
  if (method !== 'GET' && method !== 'HEAD') {
    if (c.req.header('Origin') !== c.env.PUBLIC_ORIGIN || c.req.header(CSRF_HEADER) !== '1') {
      throw new ApiError(403, 'csrf', 'Yêu cầu bị chặn vì không đến từ trang Quly Thu Chi.');
    }
  }
  const row = await c.env.DB.prepare(
    `SELECT s.user_id, s.device_id, u.deletion_requested_at FROM web_sessions s JOIN devices d ON d.id = s.device_id
     JOIN users u ON u.id = s.user_id WHERE s.token_hash = ? AND s.expires_at > ? AND d.revoked_at IS NULL`,
  )
    .bind(await sha256Hex(cookie), Date.now())
    .first<{ user_id: string; device_id: string; deletion_requested_at: number | null }>();
  if (!row) throw new ApiError(401, 'unauthenticated', 'Phiên đăng nhập đã hết hạn.');
  c.set('auth', {
    userId: row.user_id,
    deviceId: row.device_id,
    via: 'cookie',
    pendingDeletion: row.deletion_requested_at !== null,
  });
  await next();
});

/** Tài khoản đang chờ xóa (ân hạn 30 ngày) chỉ được đọc/xuất dữ liệu và hủy yêu cầu xóa - không ghi thêm. */
export const blockIfDeleting = createMiddleware<AppEnv>(async (c, next) => {
  if (c.req.method !== 'GET' && c.req.method !== 'HEAD' && c.get('auth').pendingDeletion) {
    throw new ApiError(403, 'pending_deletion', 'Tài khoản đang chờ xóa. Hủy yêu cầu xóa để tiếp tục đồng bộ.');
  }
  await next();
});
