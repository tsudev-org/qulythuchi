import { createLocalJWKSet, jwtVerify, type JSONWebKeySet, type JWTPayload } from 'jose';

import type { Env } from '../env';
import { ApiError } from '../lib/errors';

/**
 * Bên tin cậy (RP) OIDC của tsudev.com. Chỉ Authorization Code + PKCE S256,
 * client công khai `qulythuchi`, redirect DUY NHẤT `${PUBLIC_ORIGIN}/auth/callback`.
 * Cấu hình đọc từ discovery (không ghi cứng endpoint); JWKS cache theo `kid`,
 * gặp `kid` lạ thì tải lại (tối đa 1 lần/phút) - AUTH_AND_ACCOUNT.md mục 2.
 */
export interface Discovery {
  issuer: string;
  authorization_endpoint: string;
  token_endpoint: string;
  userinfo_endpoint: string;
  jwks_uri: string;
  end_session_endpoint?: string;
}

type Fetcher = (input: string, init?: RequestInit) => Promise<Response>;
let fetcher: Fetcher = (input, init) => fetch(input, init);

/** Chỉ dùng trong test: thay IdP thật bằng IdP giả. */
export function setOidcFetcher(f: Fetcher) {
  fetcher = f;
  discoveryCache = null;
  jwksCache = null;
  providersCache = null;
}

let discoveryCache: { issuer: string; value: Discovery; at: number } | null = null;
let jwksCache: { uri: string; keys: JSONWebKeySet; at: number } | null = null;
const DISCOVERY_TTL = 60 * 60 * 1000;
const JWKS_MIN_REFRESH = 60 * 1000;

async function getJson<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetcher(url, { ...init, signal: AbortSignal.timeout(10_000) });
  if (!res.ok) throw new ApiError(502, 'idp_unavailable', `Máy chủ tài khoản TsuDEV trả lỗi ${res.status}.`);
  return res.json<T>();
}

export async function discovery(env: Env): Promise<Discovery> {
  if (discoveryCache && discoveryCache.issuer === env.OIDC_ISSUER && Date.now() - discoveryCache.at < DISCOVERY_TTL) {
    return discoveryCache.value;
  }
  const value = await getJson<Discovery>(`${env.OIDC_ISSUER}/.well-known/openid-configuration`);
  if (value.issuer !== env.OIDC_ISSUER) {
    throw new ApiError(502, 'idp_misconfigured', 'Cấu hình nhà cung cấp danh tính không khớp issuer.');
  }
  discoveryCache = { issuer: env.OIDC_ISSUER, value, at: Date.now() };
  return value;
}

async function jwks(uri: string, force: boolean): Promise<JSONWebKeySet> {
  const cached = jwksCache?.uri === uri ? jwksCache : null;
  if (cached && (!force || Date.now() - cached.at < JWKS_MIN_REFRESH)) return cached.keys;
  const keys = await getJson<JSONWebKeySet>(uri);
  jwksCache = { uri, keys, at: Date.now() };
  return keys;
}

export function redirectUri(env: Env) {
  return `${env.PUBLIC_ORIGIN}/auth/callback`;
}

/**
 * Mọi lối liên kết quy ước cho phép gợi ý (AUTH_AND_ACCOUNT.md mục 3 + 3.2), ĐÚNG thứ tự hiển thị: Google, Apple,
 * GitHub. Đây chỉ là danh sách trắng cho `idp_hint`; lối nào thực sự có nút do IdP quyết ([idpProviders]).
 */
export const LOGIN_PROVIDERS = ['google', 'apple', 'github'] as const;
export type LoginProvider = (typeof LOGIN_PROVIDERS)[number];

const PROVIDER_NAMES: Record<LoginProvider, string> = { google: 'Google', apple: 'Apple', github: 'GitHub' };
/**
 * Dùng khi IdP chưa trả được danh sách (endpoint chưa có / lỗi mạng) và chưa có bản tốt trước đó: hai lối IdP đã chạy
 * từ ngày đầu. KHÔNG BAO GIỜ có Apple - nút Apple chỉ hiện khi chính IdP báo đã bật (mục 3.2: không nút chết).
 */
const FALLBACK_PROVIDERS: readonly LoginProvider[] = ['google', 'github'];
const PROVIDERS_TTL = 5 * 60 * 1000;
const PROVIDERS_RETRY = 60 * 1000;

export interface IdpProviderList {
  providers: { id: LoginProvider; name: string }[];
  /** `idp` = vừa lấy/đệm từ IdP; `fallback` = IdP không trả được, đang dùng danh sách dự phòng. */
  source: 'idp' | 'fallback';
}

let providersCache: { issuer: string; value: IdpProviderList; at: number } | null = null;

function listOf(ids: Iterable<LoginProvider>, source: IdpProviderList['source']): IdpProviderList {
  const set = new Set(ids);
  return { providers: LOGIN_PROVIDERS.filter((id) => set.has(id)).map((id) => ({ id, name: PROVIDER_NAMES[id] })), source };
}

/**
 * Nhà cung cấp IdP tsudev.com ĐANG BẬT (`GET {gốc issuer}/api/v1/auth/providers`, AUTH_AND_ACCOUNT mục 3.2 + 15).
 * Chỉ giữ id nằm trong [LOGIN_PROVIDERS] (IdP có thêm lối lạ ⇒ bỏ qua, không dựng nút lạ). Đệm 5 phút; lỗi ⇒ giữ
 * bản tốt cũ (thử lại sau 1 phút), chưa từng có ⇒ dự phòng Google + GitHub.
 */
export async function idpProviders(env: Env): Promise<IdpProviderList> {
  const now = Date.now();
  const cached = providersCache?.issuer === env.OIDC_ISSUER ? providersCache : null;
  if (cached && now - cached.at < (cached.value.source === 'idp' ? PROVIDERS_TTL : PROVIDERS_RETRY)) return cached.value;
  let value: IdpProviderList;
  try {
    const body = await getJson<{ providers?: unknown }>(`${new URL(env.OIDC_ISSUER).origin}/api/v1/auth/providers`);
    if (!Array.isArray(body.providers)) throw new Error('bad_body');
    const ids = body.providers
      .map((p) => (p && typeof p === 'object' ? (p as { idp_hint?: unknown; id?: unknown }).idp_hint ?? (p as { id?: unknown }).id : null))
      .filter((id): id is LoginProvider => typeof id === 'string' && (LOGIN_PROVIDERS as readonly string[]).includes(id));
    value = listOf(ids, 'idp');
  } catch {
    if (cached?.value.source === 'idp') {
      // Giữ bản tốt cũ nhưng hỏi lại sau 1 phút thay vì dội IdP mỗi yêu cầu.
      providersCache = { issuer: env.OIDC_ISSUER, value: cached.value, at: now - PROVIDERS_TTL + PROVIDERS_RETRY };
      return cached.value;
    }
    value = listOf(FALLBACK_PROVIDERS, 'fallback');
  }
  providersCache = { issuer: env.OIDC_ISSUER, value, at: now };
  return value;
}

export async function authorizationUrl(
  env: Env,
  p: { state: string; nonce: string; challenge: string; provider?: LoginProvider },
) {
  const d = await discovery(env);
  const url = new URL(d.authorization_endpoint);
  url.search = new URLSearchParams({
    response_type: 'code',
    client_id: env.OIDC_CLIENT_ID,
    redirect_uri: redirectUri(env),
    scope: 'openid profile email',
    state: p.state,
    nonce: p.nonce,
    code_challenge: p.challenge,
    code_challenge_method: 'S256',
    // Gợi ý tsudev.com mở thẳng lối Google/Apple/GitHub; IdP chưa hỗ trợ thì bỏ qua tham số lạ (vẫn hiện đủ 3 lối).
    ...(p.provider ? { idp_hint: p.provider } : {}),
  }).toString();
  return url.toString();
}

export interface IdentityClaims {
  sub: string;
  email: string | null;
  emailVerified: boolean;
  name: string | null;
  picture: string | null;
}

/** Đổi mã lấy token (máy chủ - máy chủ), kiểm id_token, đọc userinfo. */
export async function exchangeCode(env: Env, code: string, verifier: string, nonce: string): Promise<IdentityClaims> {
  const d = await discovery(env);
  const res = await fetcher(d.token_endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri(env),
      client_id: env.OIDC_CLIENT_ID,
      code_verifier: verifier,
    }).toString(),
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) throw new ApiError(401, 'idp_rejected', 'tsudev.com từ chối mã đăng nhập (có thể đã hết hạn). Hãy thử lại.');
  const tokens = await res.json<{ id_token?: string; access_token?: string }>();
  const idToken = tokens.id_token;
  if (!idToken || !tokens.access_token) throw new ApiError(502, 'idp_bad_response', 'Phản hồi đăng nhập thiếu token.');

  let payload: JWTPayload;
  const verify = async (force: boolean) =>
    (
      await jwtVerify(idToken, createLocalJWKSet(await jwks(d.jwks_uri, force)), {
        issuer: env.OIDC_ISSUER,
        audience: env.OIDC_CLIENT_ID,
        algorithms: ['ES256'],
        maxTokenAge: '15m',
        clockTolerance: 30,
      })
    ).payload;
  try {
    payload = await verify(false);
  } catch (e) {
    if ((e as { code?: string }).code !== 'ERR_JWKS_NO_MATCHING_KEY') throw invalidToken();
    try {
      payload = await verify(true);
    } catch {
      throw invalidToken();
    }
  }
  if (payload.nonce !== nonce || typeof payload.sub !== 'string') throw invalidToken();

  // Hồ sơ lấy ở userinfo (id_token của tsudev chỉ chở `sub`), và sub phải trùng.
  const info = await getJson<Record<string, unknown>>(d.userinfo_endpoint, {
    headers: { Authorization: `Bearer ${tokens.access_token}`, Accept: 'application/json' },
  });
  if (info.sub !== payload.sub) throw invalidToken();
  const str = (v: unknown) => (typeof v === 'string' && v.length <= 512 ? v : null);
  const picture = str(info.picture);
  return {
    sub: payload.sub,
    email: str(info.email),
    emailVerified: info.email_verified === true,
    name: str(info.name) ?? str(info.preferred_username),
    picture: picture && picture.startsWith('https://') ? picture : null,
  };
}

/** Gọi tsudev.com qua cùng bộ fetch với OIDC (test thay bằng IdP giả qua `setOidcFetcher`). */
export function idpFetch(input: string, init?: RequestInit): Promise<Response> {
  return fetcher(input, { ...init, signal: init?.signal ?? AbortSignal.timeout(10_000) });
}

/**
 * Kiểm một JWS do tsudev.com ký bằng khoá OIDC (JWKS lấy từ discovery, chọn theo `kid`, gặp `kid` lạ thì tải lại).
 * Chỉ nhận ES256, đúng `iss` = issuer, `aud` = client của mình. Sai bất kỳ điểm nào ⇒ ném lỗi của jose.
 */
export async function verifyIdpJws(env: Env, token: string, opts: { typ?: string; maxTokenAge?: string }): Promise<JWTPayload> {
  const d = await discovery(env);
  const verify = async (force: boolean) =>
    (
      await jwtVerify(token, createLocalJWKSet(await jwks(d.jwks_uri, force)), {
        issuer: env.OIDC_ISSUER,
        audience: env.OIDC_CLIENT_ID,
        algorithms: ['ES256'],
        requiredClaims: ['exp', 'iat', 'sub'],
        clockTolerance: 30,
        ...(opts.typ ? { typ: opts.typ } : {}),
        ...(opts.maxTokenAge ? { maxTokenAge: opts.maxTokenAge } : {}),
      })
    ).payload;
  try {
    return await verify(false);
  } catch (e) {
    if ((e as { code?: string }).code !== 'ERR_JWKS_NO_MATCHING_KEY') throw e;
    return verify(true);
  }
}

function invalidToken() {
  return new ApiError(401, 'invalid_id_token', 'Không xác minh được danh tính trả về từ tsudev.com.');
}
