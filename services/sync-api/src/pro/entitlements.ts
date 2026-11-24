import type { Context } from 'hono';
import { createMiddleware } from 'hono/factory';
import { SignJWT, importJWK, type CryptoKey as JoseKey, type JWK } from 'jose';

import { idpFetch, verifyIdpJws } from '../auth/oidc';
import type { AppEnv, Env } from '../env';
import { randomToken, sha256Hex } from '../lib/crypto';
import { ApiError } from '../lib/errors';

/**
 * Quyền lợi TsuDEV Pro (ADR-0016, PRODUCT_POLICY 7.4). Nguồn sự thật: JWS ES256 do tsudev.com ký, lấy qua kênh RP
 * `GET {ENTITLEMENTS_URL}/{sub}` với client assertion `private_key_jwt` (RFC 7523). Máy chủ KHÔNG tin cờ từ app.
 * Đệm trong D1 ≤ 24 giờ (và không quá `exp` của JWS); tsudev.com lỗi mà đệm đã cũ ⇒ 503 (app vẫn chạy cục bộ).
 */

const ENT_CACHE_MS = 24 * 3600 * 1000;
/** Mỗi mã cài đặt báo lại tsudev.com tối đa 1 lần / 24 giờ - đủ để `devices_30d` đếm đúng. */
const INSTALLATION_REPORT_MS = 24 * 3600 * 1000;
/** Pro hết hạn: còn kéo + xuất 90 ngày rồi xoá bản mã trên máy chủ (PRODUCT_POLICY 7.2). */
export const PRO_GRACE_MS = 90 * 24 * 3600 * 1000;
const JWS_MAX_TTL_S = 7 * 24 * 3600;
const INSTALLATION_RE = /^[A-Za-z0-9_-]{22}$/;
const PLATFORMS = new Set(['android', 'ios', 'windows', 'macos', 'linux', 'web']);
const BADGES = new Set(['pro', 'donor', 'both', 'none']);

type Badge = 'pro' | 'donor' | 'both' | 'none';

export interface Entitlement {
  status: 'ok' | 'unknown_subject';
  jws: string | null;
  /** mili giây Unix; 0 = chưa từng có Pro. */
  proUntil: number;
  badge: Badge;
  devices30d: number;
  jwsExp: number;
  fetchedAt: number;
}

interface Row {
  status: 'ok' | 'unknown_subject';
  jws: string | null;
  pro_until: number;
  badge: Badge;
  devices_30d: number;
  jws_exp: number;
  fetched_at: number;
}

const fromRow = (r: Row): Entitlement => ({
  status: r.status,
  jws: r.jws,
  proUntil: r.pro_until,
  badge: r.badge,
  devices30d: r.devices_30d,
  jwsExp: r.jws_exp,
  fetchedAt: r.fetched_at,
});

export const isPro = (e: Entitlement | null, at = Date.now()) => !!e && e.status === 'ok' && e.proUntil > at;
export const enforcing = (env: Env) => env.PRO_ENFORCE === 'on';

const fresh = (e: Entitlement, at: number) => e.fetchedAt > at - ENT_CACHE_MS && (e.status !== 'ok' || e.jwsExp > at);

export interface Caller {
  installation?: string | null;
  platform?: string | null;
}

/** Header của app: `X-Tsu-Installation` (22 ký tự base64url) + `X-Tsu-Platform`. Sai định dạng ⇒ bỏ qua. */
export function callerOf(c: Context<AppEnv>): Caller {
  const inst = c.req.header('X-Tsu-Installation');
  const plat = c.req.header('X-Tsu-Platform')?.toLowerCase();
  return {
    installation: inst && INSTALLATION_RE.test(inst) ? inst : null,
    platform: plat && PLATFORMS.has(plat) ? plat : null,
  };
}

export async function cachedEntitlement(env: Env, userId: string): Promise<Entitlement | null> {
  const r = await env.DB.prepare(
    'SELECT status, jws, pro_until, badge, devices_30d, jws_exp, fetched_at FROM entitlements WHERE user_id = ?',
  )
    .bind(userId)
    .first<Row>();
  return r ? fromRow(r) : null;
}

/**
 * Quyền lợi hiện tại của một tài khoản. Gọi tsudev.com khi: chưa có đệm, đệm quá 24 giờ / quá `exp`, `force`, hoặc
 * mã cài đặt của thiết bị đang gọi chưa được báo trong 24 giờ. Lỗi mạng/5xx ⇒ dùng đệm còn hạn, không thì 503.
 */
export async function getEntitlement(env: Env, userId: string, caller: Caller = {}, opts: { force?: boolean } = {}) {
  const at = Date.now();
  const cached = await cachedEntitlement(env, userId);
  const instHash = caller.installation ? await sha256Hex(`tsu-inst|${caller.installation}`) : null;
  let needReport = false;
  if (instHash) {
    const seen = await env.DB.prepare('SELECT reported_at FROM installations_seen WHERE user_id = ? AND installation_hash = ?')
      .bind(userId, instHash)
      .first<{ reported_at: number }>();
    needReport = !seen || seen.reported_at < at - INSTALLATION_REPORT_MS;
  }
  if (cached && fresh(cached, at) && !opts.force && !needReport) return cached;

  const user = await env.DB.prepare('SELECT oidc_sub FROM users WHERE id = ?').bind(userId).first<{ oidc_sub: string }>();
  if (!user || user.oidc_sub.startsWith('deleted:')) throw new ApiError(401, 'unauthenticated', 'Tài khoản không còn tồn tại.');

  let next: Entitlement;
  try {
    next = await fetchEntitlement(env, user.oidc_sub, caller, cached);
  } catch (e) {
    if (cached && fresh(cached, at)) return cached;
    if (e instanceof ApiError) throw e;
    console.error('entitlements', e instanceof Error ? e.name : 'error');
    throw unavailable();
  }
  const stmts = [
    env.DB.prepare(
      `INSERT INTO entitlements (user_id, status, jws, pro_until, badge, devices_30d, jws_exp, fetched_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
       ON CONFLICT(user_id) DO UPDATE SET status = ?2, jws = ?3, pro_until = ?4, badge = ?5, devices_30d = ?6,
         jws_exp = ?7, fetched_at = ?8`,
    ).bind(userId, next.status, next.jws, next.proUntil, next.badge, next.devices30d, next.jwsExp, next.fetchedAt),
  ];
  if (instHash) {
    stmts.push(
      env.DB.prepare(
        `INSERT INTO installations_seen (user_id, installation_hash, reported_at) VALUES (?1, ?2, ?3)
         ON CONFLICT(user_id, installation_hash) DO UPDATE SET reported_at = ?3`,
      ).bind(userId, instHash, at),
    );
  }
  await env.DB.batch(stmts);
  return next;
}

const unavailable = () =>
  new ApiError(503, 'entitlements_unavailable', 'Chưa kiểm được gói TsuDEV Pro. Dữ liệu vẫn an toàn trên máy, hãy thử lại sau.');

let signingKey: { jwk: string; key: JoseKey | Uint8Array } | null = null;

/**
 * Client assertion `private_key_jwt`: iss = sub = client_id, aud = URL của kênh được gọi (khớp tuyệt đối - kênh RP
 * `ENTITLEMENTS_URL` hoặc kênh trạng thái `ENTITLEMENTS_STATUS_URL`), 120 giây (≤ 300), `jti` ngẫu nhiên một lần.
 */
export async function clientAssertion(env: Env, aud: string = env.ENTITLEMENTS_URL): Promise<string> {
  const raw = env.RP_PRIVATE_JWK;
  if (!raw) throw unavailable();
  if (signingKey?.jwk !== raw) {
    const jwk = JSON.parse(raw) as JWK;
    if (jwk.kty !== 'EC' || jwk.crv !== 'P-256' || !jwk.d) throw unavailable();
    signingKey = { jwk: raw, key: await importJWK(jwk, 'ES256') };
  }
  const header: { alg: 'ES256'; typ: 'JWT'; kid?: string } = { alg: 'ES256', typ: 'JWT' };
  const kid = (JSON.parse(raw) as JWK).kid;
  if (kid) header.kid = kid;
  return new SignJWT({})
    .setProtectedHeader(header)
    .setIssuer(env.OIDC_CLIENT_ID)
    .setSubject(env.OIDC_CLIENT_ID)
    .setAudience(aud)
    .setIssuedAt()
    .setExpirationTime('120s')
    .setJti(randomToken(24))
    .sign(signingKey.key);
}

async function fetchEntitlement(env: Env, sub: string, caller: Caller, prev: Entitlement | null): Promise<Entitlement> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${await clientAssertion(env)}`,
    Accept: 'application/json',
  };
  if (caller.installation) headers['X-Tsu-Installation'] = caller.installation;
  if (caller.platform) headers['X-Tsu-Platform'] = caller.platform;
  const res = await idpFetch(`${env.ENTITLEMENTS_URL}/${encodeURIComponent(sub)}`, { headers });
  const at = Date.now();
  if (res.status === 404) {
    // Grant OIDC của tài khoản với client này đã hết hạn (tsudev.com: 30 ngày) ⇒ cần đăng nhập lại. Giữ `pro_until`
    // đã biết để tính mốc xoá, nhưng KHÔNG coi là Pro.
    return {
      status: 'unknown_subject',
      jws: null,
      proUntil: prev?.proUntil ?? 0,
      badge: 'none',
      devices30d: prev?.devices30d ?? 0,
      jwsExp: 0,
      fetchedAt: at,
    };
  }
  if (!res.ok) throw new Error(`entitlements_${res.status}`);
  const body = await res.json<{ jws?: unknown }>();
  if (typeof body.jws !== 'string' || body.jws.length > 4096) throw new Error('entitlements_bad_body');
  const p = await verifyIdpJws(env, body.jws, { typ: 'tsu-ent+jwt' });
  if (p.sub !== sub || typeof p.exp !== 'number' || typeof p.iat !== 'number' || p.exp - p.iat > JWS_MAX_TTL_S + 60) {
    throw new Error('entitlements_bad_claims');
  }
  const proUntil = p.pro_until;
  const devices = p.devices_30d;
  const badge = typeof p.badge === 'string' && BADGES.has(p.badge) ? (p.badge as Badge) : 'none';
  if (typeof proUntil !== 'number' || !Number.isFinite(proUntil) || proUntil < 0) throw new Error('entitlements_bad_claims');
  return {
    status: 'ok',
    jws: body.jws,
    proUntil: Math.floor(proUntil) * 1000,
    badge,
    devices30d: typeof devices === 'number' && Number.isFinite(devices) ? Math.max(0, Math.floor(devices)) : 0,
    jwsExp: p.exp * 1000,
    fetchedAt: at,
  };
}

function proRequired(reason: 'no_pro' | 'reauth' | 'owner_no_pro' = 'no_pro') {
  const message =
    reason === 'reauth'
      ? 'Hãy đăng nhập lại để kiểm gói TsuDEV Pro.'
      : reason === 'owner_no_pro'
        ? 'Chủ ví chung chưa có TsuDEV Pro nên chưa đồng bộ được ví này.'
        : 'Đồng bộ và sao lưu đám mây cần TsuDEV Pro. Dữ liệu vẫn lưu đầy đủ trên thiết bị này.';
  return new ApiError(402, 'pro_required', message, { reason });
}

/** Ném 402 nếu tài khoản không có Pro còn hạn (khi PRO_ENFORCE=on). */
export async function assertPro(c: Context<AppEnv>, userId: string, reasonIfMissing: 'no_pro' | 'owner_no_pro' = 'no_pro') {
  if (!enforcing(c.env)) return;
  const self = userId === c.get('auth').userId;
  const e = await getEntitlement(c.env, userId, self ? callerOf(c) : {});
  if (isPro(e)) return;
  throw proRequired(self && e.status === 'unknown_subject' ? 'reauth' : reasonIfMissing);
}

/** Middleware: lượt ghi lên máy chủ của chính người gọi cần Pro. */
export const requirePro = createMiddleware<AppEnv>(async (c, next) => {
  await assertPro(c, c.get('auth').userId);
  await next();
});

/** Kết quả kênh trạng thái cho một `sub` (PRODUCT_POLICY 7.4). `proUntil`: mili giây Unix; 0 = chưa từng có Pro. */
export type SubjectStatus = { status: 'ok'; proUntil: number } | { status: 'deleted' } | { status: 'unknown_subject' };

/** Trần `subs` mỗi lần hỏi kênh trạng thái (PRODUCT_POLICY 7.4). */
export const STATUS_MAX_SUBS = 100;
const STATUS_TIMEOUT_MS = 10_000;

/**
 * Hỏi kênh trạng thái tsudev.com (`POST ENTITLEMENTS_STATUS_URL`, ADR-0018) - KHÔNG phụ thuộc grant OIDC 30 ngày như
 * kênh RP `GET /{sub}`. Chỉ trả `pro_until`/`deleted`/`unknown_subject`, không email/huy hiệu. Mọi lỗi (chưa cấu hình,
 * mạng, hết giờ, HTTP ≠ 200, khung sai) ⇒ ném lỗi để bên gọi HOÃN; mục lạ/thiếu cho một `sub` ⇒ `unknown_subject`.
 */
export async function fetchSubjectStatus(env: Env, subs: string[]): Promise<Map<string, SubjectStatus>> {
  const url = env.ENTITLEMENTS_STATUS_URL;
  if (!url || !env.RP_PRIVATE_JWK) throw new Error('status_unconfigured');
  if (subs.length === 0 || subs.length > STATUS_MAX_SUBS) throw new Error('status_bad_request');
  const res = await idpFetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${await clientAssertion(env, url)}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ client_id: env.OIDC_CLIENT_ID, subs }),
    signal: AbortSignal.timeout(STATUS_TIMEOUT_MS),
  });
  if (res.status !== 200) throw new Error(`status_${res.status}`);
  const body = await res.json<{ results?: unknown }>().catch(() => null);
  const results = body?.results;
  if (!results || typeof results !== 'object' || Array.isArray(results)) throw new Error('status_bad_body');
  const out = new Map<string, SubjectStatus>();
  for (const sub of subs) {
    const r = Object.hasOwn(results, sub) ? (results as Record<string, unknown>)[sub] : undefined;
    const st = r && typeof r === 'object' ? (r as { status?: unknown; pro_until?: unknown }) : {};
    if (st.status === 'ok' && typeof st.pro_until === 'number' && Number.isFinite(st.pro_until) && st.pro_until >= 0) {
      out.set(sub, { status: 'ok', proUntil: Math.floor(st.pro_until) * 1000 });
    } else if (st.status === 'deleted') {
      out.set(sub, { status: 'deleted' });
    } else {
      out.set(sub, { status: 'unknown_subject' });
    }
  }
  return out;
}
