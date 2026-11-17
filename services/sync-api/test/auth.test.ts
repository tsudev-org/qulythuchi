import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

import { isAllowedAppRedirect, safeReturnTo } from '../src/auth/redirects';
import { pkceChallenge, randomToken } from '../src/lib/crypto';
import { appLogin, call, cookieValue, fakeIdp, json, login } from './helpers';

describe('đích quay về', () => {
  it('chỉ nhận scheme app và vòng lặp 127.0.0.1 khớp tuyệt đối', () => {
    expect(isAllowedAppRedirect('com.tsudev.qulythuchi:/auth/callback')).toBe(true);
    expect(isAllowedAppRedirect('http://127.0.0.1:53111/callback')).toBe(true);
    for (const bad of [
      'http://localhost:53111/callback',
      'http://127.0.0.1:53111/callback/x',
      'http://127.0.0.1:80/callback',
      'https://evil.example/callback',
      'com.tsudev.qulythuchi:/auth/callback?x=1',
      'com.tsudev.qulythuchi.evil:/auth/callback',
      'http://127.0.0.1.evil.example:53111/callback',
    ]) {
      expect(isAllowedAppRedirect(bad), bad).toBe(false);
    }
  });

  it('return_to chỉ là đường dẫn tương đối cùng gốc', () => {
    expect(safeReturnTo('/app/bao-cao')).toBe('/app/bao-cao');
    for (const bad of ['//evil.example', 'https://evil.example', '/\\evil', 'javascript:alert(1)', '/a\r\nb', undefined]) {
      expect(safeReturnTo(bad)).toBe('/app/');
    }
  });
});

describe('đăng nhập app (PKCE + mã một lần)', () => {
  it('đi trọn luồng, cấp token, gọi được /me', async () => {
    const idp = await fakeIdp();
    const r = await appLogin(idp);
    expect(r.start.status).toBe(302);
    expect(r.authorize.searchParams.get('code_challenge_method')).toBe('S256');
    expect(r.authorize.searchParams.get('client_id')).toBe('qulythuchi');
    expect(r.authorize.searchParams.get('redirect_uri')).toBe('https://qulythuchi.tsudev.com/auth/callback');
    expect(r.back.searchParams.get('state')).toBe(r.appState);
    expect(r.token.status).toBe(200);
    expect(r.body.refresh_token).toMatch(/^qtr_/);
    expect(r.body.expires_in).toBe(900);
    const me = await call('/api/v1/me', { headers: { Authorization: `Bearer ${r.body.access_token}` } });
    expect(me.status).toBe(200);
    const body: any = await me.json();
    expect(body.display_name).toBe('Người Dùng');
    expect(body.status).toBe('active');
    expect(body.device_id).toBe(r.body.device_id);
  });

  it('từ chối redirect_uri ngoài danh sách mà KHÔNG chuyển hướng', async () => {
    await fakeIdp();
    const res = await call(
      '/auth/app/start?redirect_uri=https%3A%2F%2Fevil.example%2Fcb&state=aaaaaaaaaaaaaaaaaaaa&code_challenge=' +
        'a'.repeat(43) +
        '&code_challenge_method=S256',
    );
    expect(res.status).toBe(400);
    expect(res.headers.get('Location')).toBeNull();
  });

  it('callback thiếu cookie gắn trình duyệt bị chặn (chống CSRF đăng nhập)', async () => {
    await fakeIdp();
    const start = await call('/auth/web/start');
    const state = new URL(start.headers.get('Location')!).searchParams.get('state');
    const res = await call(`/auth/callback?code=idp-code&state=${state}`);
    expect(res.status).toBe(400);
  });

  it('state sai bị từ chối; state chỉ dùng được một lần', async () => {
    await fakeIdp();
    const start = await call('/auth/web/start');
    const binder = cookieValue(start, '__Host-qt_login')!;
    const state = new URL(start.headers.get('Location')!).searchParams.get('state')!;
    const wrong = await call('/auth/callback?code=idp-code&state=khong-dung', { headers: { Cookie: `__Host-qt_login=${binder}` } });
    expect(wrong.status).toBe(400);
    const ok = await call(`/auth/callback?code=idp-code&state=${state}`, { headers: { Cookie: `__Host-qt_login=${binder}` } });
    expect(ok.status).toBe(401); // idp.nonce chưa đặt ⇒ id_token sai nonce
    const again = await call(`/auth/callback?code=idp-code&state=${state}`, { headers: { Cookie: `__Host-qt_login=${binder}` } });
    expect(again.status).toBe(400);
  });

  it('id_token sai nonce hoặc sai audience bị từ chối', async () => {
    for (const opt of [{ tamperNonce: true }, { wrongAud: true }]) {
      const idp = await fakeIdp(opt);
      const r = await appLogin(idp);
      expect(r.cb.status).toBe(401);
    }
  });

  it('mã một lần không dùng lại được và đòi đúng code_verifier', async () => {
    const idp = await fakeIdp();
    const r = await appLogin(idp);
    const reuse = await call(
      '/api/v1/auth/token',
      json({
        grant_type: 'authorization_code',
        code: r.back.searchParams.get('code'),
        code_verifier: r.verifier,
        redirect_uri: 'http://127.0.0.1:53111/callback',
        device_name: 'x',
        platform: 'linux',
      }),
    );
    expect(reuse.status).toBe(400);

    // Lượt mới: lấy mã mới rồi đổi bằng verifier SAI (kẻ chặn được mã nhưng không có verifier).
    const verifier = randomToken(48);
    const start = await call(
      `/auth/app/start?${new URLSearchParams({
        redirect_uri: 'com.tsudev.qulythuchi:/auth/callback',
        state: randomToken(20),
        code_challenge: await pkceChallenge(verifier),
        code_challenge_method: 'S256',
      }).toString()}`,
    );
    const authorize = new URL(start.headers.get('Location')!);
    idp.nonce = authorize.searchParams.get('nonce')!;
    const cb = await call(`/auth/callback?code=idp-code&state=${authorize.searchParams.get('state')}`, {
      headers: { Cookie: `__Host-qt_login=${cookieValue(start, '__Host-qt_login')}` },
    });
    const back = new URL(cb.headers.get('Location')!);
    expect(back.protocol).toBe('com.tsudev.qulythuchi:');
    const bad = await call(
      '/api/v1/auth/token',
      json({
        grant_type: 'authorization_code',
        code: back.searchParams.get('code'),
        code_verifier: randomToken(48),
        redirect_uri: 'com.tsudev.qulythuchi:/auth/callback',
        device_name: 'x',
        platform: 'android',
      }),
    );
    expect(bad.status).toBe(400);
  });

  it('refresh xoay vòng; dùng lại token cũ ⇒ thu hồi cả thiết bị', async () => {
    const { body, auth } = await login();
    const first = await call('/api/v1/auth/token', json({ grant_type: 'refresh_token', refresh_token: body.refresh_token }));
    expect(first.status).toBe(200);
    const rotated: any = await first.json();
    expect(rotated.refresh_token).not.toBe(body.refresh_token);
    const replay = await call('/api/v1/auth/token', json({ grant_type: 'refresh_token', refresh_token: body.refresh_token }));
    expect(replay.status).toBe(401);
    // Cả token mới lẫn access token cũ đều mất hiệu lực.
    const next = await call('/api/v1/auth/token', json({ grant_type: 'refresh_token', refresh_token: rotated.refresh_token }));
    expect(next.status).toBe(401);
    expect((await call('/api/v1/me', { headers: auth })).status).toBe(401);
    const events = await env.DB.prepare("SELECT COUNT(*) AS n FROM audit_log WHERE event = 'refresh_reuse_revoked'").first<{ n: number }>();
    expect(events!.n).toBeGreaterThan(0);
  });

  it('đăng xuất thu hồi thiết bị', async () => {
    const { body, auth } = await login();
    expect((await call('/api/v1/auth/logout', json({ refresh_token: body.refresh_token }))).status).toBe(204);
    expect((await call('/api/v1/me', { headers: auth })).status).toBe(401);
  });

  it('access token giả mạo hoặc thiếu ⇒ 401', async () => {
    const { body } = await login();
    const parts = String(body.access_token).split('.');
    const forged = `${parts[0]}.${btoa(JSON.stringify({ sub: 'other', did: 'x' })).replace(/=+$/, '')}.${parts[2]}`;
    expect((await call('/api/v1/me', { headers: { Authorization: `Bearer ${forged}` } })).status).toBe(401);
    expect((await call('/api/v1/me')).status).toBe(401);
    expect((await call('/api/v1/sync/pull')).status).toBe(401);
  });
});

describe('đăng nhập web (cookie)', () => {
  async function webLogin() {
    const idp = await fakeIdp();
    const start = await call('/auth/web/start?return_to=%2Fapp%2Fbao-cao');
    const authorize = new URL(start.headers.get('Location')!);
    idp.nonce = authorize.searchParams.get('nonce')!;
    const binder = cookieValue(start, '__Host-qt_login')!;
    const cb = await call(`/auth/callback?code=idp-code&state=${authorize.searchParams.get('state')}`, {
      headers: { Cookie: `__Host-qt_login=${binder}` },
    });
    return { cb, session: cookieValue(cb, '__Host-qt_session')! };
  }

  it('đặt cookie __Host- HttpOnly Secure SameSite=Strict và quay về return_to', async () => {
    const { cb, session } = await webLogin();
    expect(cb.status).toBe(302);
    expect(cb.headers.get('Location')).toBe('/app/bao-cao');
    const set = cb.headers.getSetCookie().find((c) => c.startsWith('__Host-qt_session='))!;
    expect(set).toMatch(/HttpOnly/);
    expect(set).toMatch(/Secure/);
    expect(set).toMatch(/SameSite=Strict/);
    expect(set).toMatch(/Path=\//);
    const status: any = await (await call('/api/v1/auth/status', { headers: { Cookie: `__Host-qt_session=${session}` } })).json();
    expect(status.signed_in).toBe(true);
  });

  it('ghi bằng cookie đòi Origin đúng + header CSRF', async () => {
    const { session } = await webLogin();
    const cookie = `__Host-qt_session=${session}`;
    const body = { records: [] };
    const noCsrf = await call('/api/v1/sync/push', json(body, { Cookie: cookie }));
    expect(noCsrf.status).toBe(403);
    const evil = await call('/api/v1/sync/push', json(body, { Cookie: cookie, Origin: 'https://evil.example', 'X-Qt-Csrf': '1' }));
    expect(evil.status).toBe(403);
    const ok = await call('/api/v1/sync/push', json(body, { Cookie: cookie, Origin: 'https://qulythuchi.tsudev.com', 'X-Qt-Csrf': '1' }));
    expect(ok.status).toBe(400); // qua CSRF, rơi vào kiểm gói rỗng
    expect((await call('/api/v1/me', { headers: { Cookie: cookie } })).status).toBe(200);
  });

  it('đăng xuất web thu hồi phiên', async () => {
    const { session } = await webLogin();
    const cookie = `__Host-qt_session=${session}`;
    const out = await call('/api/v1/auth/web-logout', {
      method: 'POST',
      headers: { Cookie: cookie, Origin: 'https://qulythuchi.tsudev.com', 'X-Qt-Csrf': '1' },
    });
    expect(out.status).toBe(204);
    expect((await call('/api/v1/me', { headers: { Cookie: cookie } })).status).toBe(401);
  });
});

describe('giới hạn tần suất', () => {
  it('đăng nhập dồn dập từ một IP bị chặn 429', async () => {
    await fakeIdp();
    let last = 0;
    for (let i = 0; i < 32; i++) {
      last = (await call('/auth/web/start', { headers: { 'CF-Connecting-IP': '203.0.113.9' } })).status;
    }
    expect(last).toBe(429);
  });
});
