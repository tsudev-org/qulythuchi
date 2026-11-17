import { describe, expect, it } from 'vitest';

import { call, fakeEnvelope, fixture, json, login } from './helpers';

const put = (path: string, auth: Record<string, string>, body: unknown) => call(path, json(body, auth, 'PUT'));

describe('gói khóa tài khoản', () => {
  it('nhận gói khóa THẬT của lõi; chỉ trả sau khi đăng nhập', async () => {
    expect((await call('/api/v1/keys')).status).toBe(401);
    const { auth } = await login();
    const empty: any = await (await call('/api/v1/keys', { headers: auth })).json();
    expect(empty.account).toBeNull();
    expect((await put('/api/v1/keys/account', auth, { bundle: fixture.bundle, if_absent: true })).status).toBe(200);
    const got: any = await (await call('/api/v1/keys', { headers: auth })).json();
    expect(got.account.bundle).toEqual(fixture.bundle);
  });

  it('if_absent: thiết bị thứ hai không tạo được khóa chủ thứ hai (409)', async () => {
    const { auth } = await login();
    await put('/api/v1/keys/account', auth, { bundle: fixture.bundle, if_absent: true });
    const other = { ...fixture.bundle, mkPw: fixture.bundle.mkRc };
    const res = await put('/api/v1/keys/account', auth, { bundle: other, if_absent: true });
    expect(res.status).toBe(409);
    expect(((await res.json()) as any).code).toBe('bundle_exists');
    // Đổi mật khẩu (không if_absent) thì thay được.
    expect((await put('/api/v1/keys/account', auth, { bundle: other })).status).toBe(200);
    const got: any = await (await call('/api/v1/keys', { headers: auth })).json();
    expect(got.account.bundle.mkPw).toBe(fixture.bundle.mkRc);
  });

  it('từ chối Argon2id dưới sàn, trường lạ, khóa sai cỡ, phiên bản lạ', async () => {
    const { auth } = await login();
    const b = fixture.bundle;
    for (const bad of [
      { ...b, kdf: { ...b.kdf, ops: 1 } },
      { ...b, kdf: { ...b.kdf, mem: 8 * 1024 * 1024 } },
      { ...b, kdf: { ...b.kdf, alg: 'pbkdf2' } },
      { ...b, extra: 'x' },
      { ...b, boxPk: btoa('short') },
      { ...b, kemPk: 'không phải base64' },
      { ...b, v: 2 },
    ]) {
      expect((await put('/api/v1/keys/account', auth, { bundle: bad })).status).toBe(400);
    }
  });
});

describe('khóa ví', () => {
  it('lưu và trả khóa ví đã bọc THẬT; từ chối khung sai', async () => {
    const { auth } = await login();
    expect((await put('/api/v1/keys/wallets', auth, { keys: [fixture.wallet_key] })).status).toBe(200);
    const got: any = await (await call('/api/v1/keys', { headers: auth })).json();
    expect(got.wallets).toEqual([expect.objectContaining(fixture.wallet_key)]);
    for (const bad of [
      { wallet_id: 'abc', wrapped: fixture.wallet_key.wrapped },
      { wallet_id: crypto.randomUUID(), wrapped: btoa('x'.repeat(100)) },
      { wallet_id: crypto.randomUUID(), wrapped: fakeEnvelope(16) },
    ]) {
      expect((await put('/api/v1/keys/wallets', auth, { keys: [bad] })).status).toBe(400);
    }
  });

  it('B không thấy khóa của A', async () => {
    const a = await login();
    const b = await login();
    await put('/api/v1/keys/wallets', a.auth, { keys: [fixture.wallet_key] });
    await put('/api/v1/keys/account', a.auth, { bundle: fixture.bundle });
    const got: any = await (await call('/api/v1/keys', { headers: b.auth })).json();
    expect(got).toEqual({ account: null, wallets: [] });
  });
});
