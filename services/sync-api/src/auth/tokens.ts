import { SignJWT, jwtVerify } from 'jose';

import type { Env } from '../env';
import { ApiError } from '../lib/errors';
import { randomToken, sha256Hex } from '../lib/crypto';

/** ADR-0003: access JWT 15 phút + refresh mờ xoay vòng 30 ngày. */
export const ACCESS_TTL_S = 15 * 60;
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;
export const WEB_SESSION_TTL_MS = 14 * 24 * 60 * 60 * 1000;
const AUDIENCE = 'qulythuchi-api';

/** Tiền tố để công cụ quét bí mật nhận ra refresh token nếu lỡ lọt vào log/mã. */
export const REFRESH_PREFIX = 'qtr_';

function key(env: Env) {
  if (!env.SESSION_SECRET || env.SESSION_SECRET.length < 32) {
    // Cố ý ồn ào: thiếu secret thì không cấp/kiểm được token nào.
    throw new ApiError(503, 'server_misconfigured', 'Máy chủ chưa cấu hình khóa phiên.');
  }
  return new TextEncoder().encode(env.SESSION_SECRET);
}

export async function issueAccessToken(env: Env, userId: string, deviceId: string): Promise<string> {
  return new SignJWT({ did: deviceId })
    .setProtectedHeader({ alg: 'HS256', typ: 'at+jwt' })
    .setIssuer(env.PUBLIC_ORIGIN)
    .setAudience(AUDIENCE)
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${ACCESS_TTL_S}s`)
    .setJti(randomToken(12))
    .sign(key(env));
}

export async function verifyAccessToken(env: Env, token: string): Promise<{ userId: string; deviceId: string }> {
  try {
    const { payload } = await jwtVerify(token, key(env), {
      issuer: env.PUBLIC_ORIGIN,
      audience: AUDIENCE,
      algorithms: ['HS256'],
      typ: 'at+jwt',
    });
    if (typeof payload.sub !== 'string' || typeof payload.did !== 'string') throw new Error('claims');
    return { userId: payload.sub, deviceId: payload.did };
  } catch (e) {
    if (e instanceof ApiError) throw e;
    throw new ApiError(401, 'invalid_token', 'Phiên đăng nhập đã hết hạn.');
  }
}

/** Refresh token mờ; máy chủ chỉ lưu SHA-256. */
export async function newRefreshToken(db: D1Database, userId: string, deviceId: string): Promise<string> {
  const token = `${REFRESH_PREFIX}${randomToken(32)}`;
  const t = Date.now();
  await db
    .prepare('INSERT INTO refresh_tokens (token_hash, device_id, user_id, created_at, expires_at) VALUES (?, ?, ?, ?, ?)')
    .bind(await sha256Hex(token), deviceId, userId, t, t + REFRESH_TTL_MS)
    .run();
  return token;
}

/** Phiên web = một thiết bị nền tảng `web` + cookie mờ (chỉ lưu băm). */
export async function newWebSession(db: D1Database, userId: string, userAgent: string | undefined): Promise<string> {
  const token = randomToken(32);
  const deviceId = crypto.randomUUID();
  const t = Date.now();
  await db.batch([
    db
      .prepare('INSERT INTO devices (id, user_id, name, platform, created_at, last_seen_at) VALUES (?, ?, ?, ?, ?, ?)')
      .bind(deviceId, userId, browserName(userAgent), 'web', t, t),
    db
      .prepare('INSERT INTO web_sessions (token_hash, user_id, device_id, created_at, expires_at) VALUES (?, ?, ?, ?, ?)')
      .bind(await sha256Hex(token), userId, deviceId, t, t + WEB_SESSION_TTL_MS),
  ]);
  return token;
}

/** Tên hiển thị thô cho phiên web, chỉ từ danh sách cố định (không lưu nguyên User-Agent). */
function browserName(ua: string | undefined): string {
  const s = ua ?? '';
  const browser = /Edg\//.test(s) ? 'Edge' : /Firefox\//.test(s) ? 'Firefox' : /Chrome\//.test(s) ? 'Chrome' : /Safari\//.test(s) ? 'Safari' : 'Trình duyệt';
  const os = /Android/.test(s) ? 'Android' : /iPhone|iPad/.test(s) ? 'iOS' : /Windows/.test(s) ? 'Windows' : /Mac OS X/.test(s) ? 'macOS' : /Linux/.test(s) ? 'Linux' : '';
  return os ? `${browser} trên ${os}` : browser;
}

export const SESSION_COOKIE = '__Host-qt_session';
export const LOGIN_COOKIE = '__Host-qt_login';
/** Header chống CSRF bắt buộc cho mọi lượt ghi bằng cookie. */
export const CSRF_HEADER = 'X-Qt-Csrf';
