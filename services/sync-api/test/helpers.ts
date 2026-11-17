import { createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import { env } from 'cloudflare:workers';
import { SignJWT, exportJWK, generateKeyPair } from 'jose';

import { setOidcFetcher } from '../src/auth/oidc';
import { pkceChallenge, randomToken } from '../src/lib/crypto';
import worker from '../src/index';
import fixture from './fixtures/core-v1.json';

export { fixture };

export const ISSUER = 'https://idp.test/oidc';
export const ORIGIN = 'https://qulythuchi.tsudev.com';

/** IdP giả: ghi lại nonce của lần authorize gần nhất, ký id_token ES256. */
export async function fakeIdp(opts: { sub?: string; tamperNonce?: boolean; wrongAud?: boolean } = {}) {
  const { privateKey, publicKey } = await generateKeyPair('ES256');
  const jwk = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'ES256', use: 'sig' };
  const state = { nonce: '', sub: opts.sub ?? 'tsudev-user-1' };
  setOidcFetcher(async (url, init) => {
    const json = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json' } });
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
