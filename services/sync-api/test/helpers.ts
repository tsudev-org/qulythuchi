import { createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import { env } from 'cloudflare:workers';
import { SignJWT, exportJWK, generateKeyPair, jwtVerify, type CryptoKey } from 'jose';

import { setOidcFetcher } from '../src/auth/oidc';
import { pkceChallenge, randomToken } from '../src/lib/crypto';
import worker from '../src/index';
import fixture from './fixtures/core-v1.json';

export { fixture };

export const ISSUER = 'https://idp.test/oidc';
export const ORIGIN = 'https://qulythuchi.tsudev.com';

/**
 * Máy chủ quyền lợi giả (kênh RP tsudev.com, PRODUCT_POLICY 7.4). Mặc định MỌI tài khoản có Pro còn hạn để các test
 * đồng bộ cũ chạy nguyên; test Pro đặt riêng theo `sub` qua `entitlementFor`.
 */
export interface FakeEnt {
  /** giây Unix; 0 = chưa từng có Pro. */
  proUntil?: number;
  badge?: 'pro' | 'donor' | 'both' | 'none';
  devices?: number;
  /** Trả mã HTTP này thay vì JWS (404 = unknown_subject, 500 = sập). */
  httpStatus?: number;
  /** Làm hỏng JWS: ký bằng khoá lạ / sai aud / sai typ / sai sub. */
  tamper?: 'key' | 'aud' | 'typ' | 'sub';
}
export const entState = {
  bySub: new Map<string, FakeEnt>(),
  calls: [] as { sub: string; installation: string | null; platform: string | null }[],
};
/** Lỗi chập chờn của IdP giả: url ⇒ hàng mã HTTP trả TRƯỚC khi trả bình thường (mỗi lần gọi lấy một mã). */
export const flakyIdp = new Map<string, number[]>();
export const idpCalls: string[] = [];

/** `GET https://idp.test/api/v1/auth/providers` của IdP giả: thân trả về, hoặc mã HTTP lỗi. */
export const providersState = {
  body: { providers: [{ id: 'google', name: 'Google', idp_hint: 'google' }, { id: 'github', name: 'GitHub', idp_hint: 'github' }] } as unknown,
  status: 200,
  calls: 0,
};
export function entitlementFor(sub: string, e: FakeEnt) {
  entState.bySub.set(sub, e);
}
export const RP_AUD = 'https://idp.test/api/rp/entitlements';
export const RP_STATUS_AUD = `${RP_AUD}/status`;

/**
 * Kênh trạng thái giả (`POST /api/rp/entitlements/status`, PRODUCT_POLICY 7.4, ADR-0018). Không phụ thuộc grant: mặc
 * định trả `ok` với `pro_until` của `entitlementFor` (kể cả khi kênh RP đang 404); `statusFor` đặt riêng theo `sub`;
 * `statusState.mode` giả lập sự cố của cả kênh.
 */
export type FakeStatus = { status: 'ok'; pro_until: number } | { status: 'deleted' } | { status: 'unknown_subject' } | { status: 'omit' };
export const statusState = {
  mode: 'ok' as 'ok' | 'http500' | 'http404' | 'timeout' | 'bad_body',
  bySub: new Map<string, FakeStatus>(),
  calls: [] as { subs: string[]; clientId: unknown; claims: Record<string, unknown>; ok: boolean }[],
  jtis: new Set<string>(),
};
/** Kênh biên nhận Play giả (`POST /api/rp/entitlements/play`, ADR-0019 mục 4). `mode` = mã HTTP trả về. */
export const playState = {
  mode: 200 as number,
  calls: [] as { body: Record<string, unknown>; claims: Record<string, unknown> }[],
};
export function statusFor(sub: string, st: FakeStatus) {
  statusState.bySub.set(sub, st);
}

let rpKey: { publicKey: CryptoKey } | null = null;
async function ensureRpKey() {
  if (rpKey) return rpKey;
  const { privateKey, publicKey } = await generateKeyPair('ES256', { extractable: true });
  (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK = JSON.stringify({ ...(await exportJWK(privateKey)), kid: 'rp1' });
  rpKey = { publicKey };
  return rpKey;
}

/** IdP giả: ghi lại nonce của lần authorize gần nhất, ký id_token ES256. */
export async function fakeIdp(opts: { sub?: string; tamperNonce?: boolean; wrongAud?: boolean } = {}) {
  const { privateKey, publicKey } = await generateKeyPair('ES256');
  const jwk = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'ES256', use: 'sig' };
  const state = { nonce: '', sub: opts.sub ?? 'tsudev-user-1' };
  const rp = await ensureRpKey();
  setOidcFetcher(async (url, init) => {
    const json = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json' } });
    idpCalls.push(url);
    const flaky = flakyIdp.get(url)?.shift();
    if (flaky) return json({ error: 'flaky' }, flaky);
    if (url === 'https://idp.test/api/v1/auth/providers') {
      providersState.calls++;
      return json(providersState.body, providersState.status);
    }
    if (url === RP_STATUS_AUD) {
      const auth = new Headers(init?.headers).get('Authorization') ?? '';
      const body = JSON.parse(typeof init?.body === 'string' ? init.body : '{}') as { client_id?: unknown; subs?: string[] };
      const subs = Array.isArray(body.subs) ? body.subs : [];
      let claims: Record<string, unknown> = {};
      let ok: boolean;
      try {
        const v = await jwtVerify(auth.slice(7), rp.publicKey, { audience: RP_STATUS_AUD, issuer: 'qulythuchi', subject: 'qulythuchi', algorithms: ['ES256'] });
        claims = v.payload;
        const jti = v.payload.jti;
        ok = init?.method === 'POST' && !!jti && !statusState.jtis.has(jti) && !!v.payload.exp && v.payload.exp - Math.floor(Date.now() / 1000) <= 300;
        if (jti) statusState.jtis.add(jti);
      } catch {
        ok = false;
      }
      ok = ok && body.client_id === 'qulythuchi' && subs.length >= 1 && subs.length <= 100;
      statusState.calls.push({ subs, clientId: body.client_id, claims, ok });
      if (!ok) return json({ error: 'invalid_client' }, 401);
      if (statusState.mode === 'timeout') throw new DOMException('The operation was aborted due to timeout', 'TimeoutError');
      if (statusState.mode === 'http500') return json({ error: 'boom' }, 500);
      if (statusState.mode === 'http404') return json({ error: 'not_found' }, 404);
      if (statusState.mode === 'bad_body') return json({ result: [] });
      const results: Record<string, unknown> = {};
      for (const sub of subs) {
        const st = statusState.bySub.get(sub) ?? { status: 'ok', pro_until: entState.bySub.get(sub)?.proUntil ?? Math.floor(Date.now() / 1000) + 30 * 86400 };
        if (st.status !== 'omit') results[sub] = st;
      }
      return json({ results });
    }
    if (url === `${RP_AUD}/play`) {
      const auth = new Headers(init?.headers).get('Authorization') ?? '';
      try {
        const v = await jwtVerify(auth.slice(7), rp.publicKey, { audience: `${RP_AUD}/play`, issuer: 'qulythuchi', subject: 'qulythuchi', algorithms: ['ES256'] });
        playState.calls.push({ body: JSON.parse(init?.body as string) as Record<string, unknown>, claims: v.payload });
      } catch {
        return json({ error: 'invalid_client' }, 401);
      }
      return json(playState.mode === 200 ? { ok: true } : { error: 'x' }, playState.mode);
    }
    if (url.startsWith(`${RP_AUD}/`)) {
      const h = new Headers(init?.headers);
      const auth = h.get('Authorization') ?? '';
      try {
        const { payload } = await jwtVerify(auth.slice(7), rp.publicKey, { audience: RP_AUD, issuer: 'qulythuchi', subject: 'qulythuchi', algorithms: ['ES256'] });
        if (!payload.jti || !payload.exp || payload.exp - Math.floor(Date.now() / 1000) > 300) return json({ error: 'invalid_client' }, 401);
      } catch {
        return json({ error: 'invalid_client' }, 401);
      }
      const sub = decodeURIComponent(url.slice(RP_AUD.length + 1));
      entState.calls.push({ sub, installation: h.get('X-Tsu-Installation'), platform: h.get('X-Tsu-Platform') });
      const e = entState.bySub.get(sub) ?? {};
      if (e.httpStatus) return json({ error: e.httpStatus === 404 ? 'unknown_subject' : 'boom' }, e.httpStatus);
      const now = Math.floor(Date.now() / 1000);
      const signer = e.tamper === 'key' ? (await generateKeyPair('ES256')).privateKey : privateKey;
      const jws = await new SignJWT({
        pro_until: e.proUntil ?? now + 30 * 86400,
        pro_source: 'web',
        donor: false,
        badge: e.badge ?? 'pro',
        devices_30d: e.devices ?? 1,
      })
        .setProtectedHeader({ alg: 'ES256', kid: 'k1', typ: e.tamper === 'typ' ? 'JWT' : 'tsu-ent+jwt' })
        .setIssuer(ISSUER)
        .setAudience(e.tamper === 'aud' ? 'app-khac' : 'qulythuchi')
        .setSubject(e.tamper === 'sub' ? 'nguoi-khac' : sub)
        .setIssuedAt(now)
        .setExpirationTime(now + 7 * 86400)
        .sign(signer);
      return json({ jws });
    }
    if (url === `${ISSUER}/.well-known/openid-configuration`) {
      return json({
        issuer: ISSUER,
        authorization_endpoint: `${ISSUER}/auth`,
        token_endpoint: `${ISSUER}/token`,
        userinfo_endpoint: `${ISSUER}/me`,
        jwks_uri: `${ISSUER}/jwks`,
      });
    }
    if (url === `${ISSUER}/jwks`) return json({ keys: [jwk] });
    if (url === `${ISSUER}/token`) {
      const body = new URLSearchParams(init?.body as string);
      if (body.get('code') !== 'idp-code' || !body.get('code_verifier')) return json({ error: 'invalid_grant' }, 400);
      const idToken = await new SignJWT({ nonce: opts.tamperNonce ? 'other' : state.nonce })
        .setProtectedHeader({ alg: 'ES256', kid: 'k1' })
        .setIssuer(ISSUER)
        .setAudience(opts.wrongAud ? 'someone-else' : 'qulythuchi')
        .setSubject(state.sub)
        .setIssuedAt()
        .setExpirationTime('5m')
        .sign(privateKey);
      return json({ id_token: idToken, access_token: 'idp-access', token_type: 'Bearer' });
    }
    if (url === `${ISSUER}/me`) {
      return json({ sub: state.sub, email: 'nguoi.dung@vi.du', email_verified: true, name: 'Người Dùng', picture: 'https://cdn.example/a.png' });
    }
    return json({ error: 'not_found' }, 404);
  });
  return state;
}

export async function call(path: string, init: RequestInit = {}) {
  const ctx = createExecutionContext();
  const headers = new Headers(init.headers);
  if (!headers.has('CF-Connecting-IP')) headers.set('CF-Connecting-IP', `10.0.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}`);
  const res = await worker.fetch(new Request(`${ORIGIN}${path}`, { ...init, headers, redirect: 'manual' }), env, ctx);
  await waitOnExecutionContext(ctx);
  return res;
}

export function cookieValue(res: Response, name: string): string | null {
  for (const c of res.headers.getSetCookie()) {
    const [pair] = c.split(';');
    const [k, v] = pair!.split('=');
    if (k === name) return v ?? null;
  }
  return null;
}

/** Đi trọn luồng đăng nhập app, trả token. */
export async function appLogin(idp: { nonce: string }, redirectUri = 'http://127.0.0.1:53111/callback') {
  const verifier = randomToken(48);
  const appState = randomToken(20);
  const start = await call(
    `/auth/app/start?${new URLSearchParams({
      redirect_uri: redirectUri,
      state: appState,
      code_challenge: await pkceChallenge(verifier),
      code_challenge_method: 'S256',
    }).toString()}`,
  );
  const authorize = new URL(start.headers.get('Location')!);
  idp.nonce = authorize.searchParams.get('nonce')!;
  const binder = cookieValue(start, '__Host-qt_login')!;
  const cb = await call(`/auth/callback?code=idp-code&state=${authorize.searchParams.get('state')}`, {
    headers: { Cookie: `__Host-qt_login=${binder}` },
  });
  if (cb.status !== 302) return { start, authorize, cb, back: new URL('http://invalid/'), appState, verifier, token: cb, body: {} as Record<string, any> };
  const back = new URL(cb.headers.get('Location')!);
  const token = await call('/api/v1/auth/token', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'authorization_code',
      code: back.searchParams.get('code'),
      code_verifier: verifier,
      redirect_uri: redirectUri,
      device_name: 'Pixel thử',
      platform: 'android',
    }),
  });
  return { start, authorize, cb, back, appState, verifier, token, body: await token.json<Record<string, any>>() };
}

/** Đăng nhập app với một danh tính tsudev riêng, trả header Bearer. */
export async function login(sub = `user-${crypto.randomUUID()}`) {
  const idp = await fakeIdp({ sub });
  const r = await appLogin(idp);
  if (r.token.status !== 200) throw new Error(`đăng nhập thử thất bại ${r.token.status}`);
  return {
    sub,
    body: r.body,
    auth: { Authorization: `Bearer ${r.body.access_token}` } as Record<string, string>,
  };
}

export function json(body: unknown, headers: Record<string, string> = {}, method = 'POST'): RequestInit {
  return { method, headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) };
}

/** Phong bì v1 giả (đúng khung, nội dung ngẫu nhiên) cỡ [padded] byte bản rõ đã đệm. */
export function fakeEnvelope(padded = 256): string {
  const bytes = new Uint8Array(4 + 24 + padded + 16);
  for (let i = 0; i < bytes.length; i += 65536) crypto.getRandomValues(bytes.subarray(i, i + 65536));
  bytes.set([0x51, 0x54, 0x01, 0x01], 0);
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s);
}
