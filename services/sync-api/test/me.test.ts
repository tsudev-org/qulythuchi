import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

import { cleanup, purgeDeletedAccounts } from '../src/maintenance';
import { DELETION_GRACE_MS } from '../src/me/routes';
import { call, fakeEnvelope, fixture, json, login } from './helpers';

describe('thiết bị', () => {
  it('liệt kê thiết bị, đánh dấu thiết bị hiện tại', async () => {
    const { auth, body } = await login();
    const res: any = await (await call('/api/v1/me/devices', { headers: auth })).json();
    expect(res.devices).toEqual([expect.objectContaining({ id: body.device_id, name: 'Pixel thử', platform: 'android', current: true })]);
  });

  it('thu hồi thiết bị khác của mình ⇒ token của nó mất hiệu lực ngay', async () => {
    const sub = `user-${crypto.randomUUID()}`;
    const one = await login(sub);
    const two = await login(sub);
    expect((await call(`/api/v1/me/devices/${two.body.device_id}`, { method: 'DELETE', headers: one.auth })).status).toBe(204);
    expect((await call('/api/v1/me', { headers: two.auth })).status).toBe(401);
    const refresh = await call('/api/v1/auth/token', json({ grant_type: 'refresh_token', refresh_token: two.body.refresh_token }));
    expect(refresh.status).toBe(401);
  });

  it('IDOR: A không thu hồi được thiết bị của B', async () => {
    const a = await login();
    const b = await login();
    expect((await call(`/api/v1/me/devices/${b.body.device_id}`, { method: 'DELETE', headers: a.auth })).status).toBe(404);
    expect((await call('/api/v1/me', { headers: b.auth })).status).toBe(200);
  });
});

describe('dung lượng và xuất dữ liệu', () => {
  it('báo dung lượng và xuất toàn bộ bản mã', async () => {
    const { auth } = await login();
    await call('/api/v1/sync/push', json({ records: fixture.records }, auth));
    await call('/api/v1/keys/account', json({ bundle: fixture.bundle }, auth, 'PUT'));
    const usage: any = await (await call('/api/v1/me/usage', { headers: auth })).json();
    expect(usage.records).toMatchObject({ count: 2, bytes: 600 });
    const exp = await call('/api/v1/me/export', { headers: auth });
    expect(exp.headers.get('Content-Disposition')).toMatch(/attachment/);
    const body: any = await exp.json();
    expect(body.format).toBe('qulythuchi-server-export');
    expect(body.records.map((r: any) => r.sealed)).toEqual(fixture.records.map((r) => r.sealed));
    expect(body.account_bundle).toEqual(fixture.bundle);
  });
});

describe('xóa tài khoản (ân hạn 30 ngày)', () => {
  it('yêu cầu xóa ⇒ chỉ đọc; hủy ⇒ ghi lại được', async () => {
    const { auth } = await login();
    expect((await call('/api/v1/me/deletion', { method: 'POST', headers: auth })).status).toBe(202);
    const me: any = await (await call('/api/v1/me', { headers: auth })).json();
    expect(me.status).toBe('pending_deletion');
    expect(me.deletion.days_remaining).toBe(30);
    const rec = [{ id: crypto.randomUUID(), type: 'txn', wallet_id: null, sealed: fakeEnvelope() }];
    const blocked = await call('/api/v1/sync/push', json({ records: rec }, auth));
    expect(blocked.status).toBe(403);
    expect((await call('/api/v1/sync/pull', { headers: auth })).status).toBe(200);
    expect((await call('/api/v1/me/deletion', { method: 'DELETE', headers: auth })).status).toBe(200);
    expect((await call('/api/v1/sync/push', json({ records: rec }, auth))).status).toBe(200);
  });

  it('hết ân hạn ⇒ xóa sạch bản mã/khóa/tệp, ẩn danh hóa; đăng nhập lại là tài khoản MỚI trống', async () => {
    const sub = `user-${crypto.randomUUID()}`;
    const { auth } = await login(sub);
    await call('/api/v1/sync/push', json({ records: fixture.records }, auth));
    await call('/api/v1/keys/account', json({ bundle: fixture.bundle }, auth, 'PUT'));
    const fileId = crypto.randomUUID();
    const file = new Uint8Array(4 + 24 + 4096 + 16);
    file.set([0x51, 0x54, 0x01, 0x01], 0);
    await call(`/api/v1/files/${fileId}`, { method: 'PUT', headers: { ...auth, 'Content-Length': String(file.length) }, body: file });
    await call('/api/v1/me/deletion', { method: 'POST', headers: auth });
    const me: any = await (await call('/api/v1/me', { headers: auth })).json();

    await purgeDeletedAccounts(env, Date.now() + DELETION_GRACE_MS - 60_000);
    expect((await call('/api/v1/sync/pull', { headers: auth })).status).toBe(200); // chưa hết hạn

    await purgeDeletedAccounts(env, Date.now() + DELETION_GRACE_MS + 60_000);
    for (const t of ['records', 'account_bundles', 'wallet_keys', 'files', 'devices']) {
      const n = await env.DB.prepare(`SELECT COUNT(*) AS n FROM ${t} WHERE user_id = ?`).bind(me.id).first<{ n: number }>();
      expect(n!.n, t).toBe(0);
    }
    expect(await env.FILES.get(`u/${me.id}/${fileId}`)).toBeNull();
    const u = await env.DB.prepare('SELECT email, display_name, oidc_sub FROM users WHERE id = ?').bind(me.id).first<any>();
    expect(u).toEqual({ email: null, display_name: null, oidc_sub: `deleted:${me.id}` });
    expect((await call('/api/v1/me', { headers: auth })).status).toBe(401);

    const again = await login(sub);
    const fresh: any = await (await call('/api/v1/me', { headers: again.auth })).json();
    expect(fresh.id).not.toBe(me.id);
    expect(((await (await call('/api/v1/sync/pull', { headers: again.auth })).json()) as any).records).toHaveLength(0);
  });
});

describe('dọn bia mộ', () => {
  it('chỉ xóa bia mộ > 90 ngày mà mọi thiết bị đã kéo qua', async () => {
    const { auth, body } = await login();
    const tomb = crypto.randomUUID();
    const live = crypto.randomUUID();
    const r: any = await (
      await call(
        '/api/v1/sync/push',
        json({ records: [
          { id: tomb, type: 'txn', wallet_id: null, sealed: fakeEnvelope(), deleted: true },
          { id: live, type: 'txn', wallet_id: null, sealed: fakeEnvelope() },
        ] }, auth),
      )
    ).json();
    const later = Date.now() + 91 * 24 * 3600 * 1000;
    await cleanup(env, later);
    const count = async () => (await env.DB.prepare('SELECT COUNT(*) AS n FROM records WHERE user_id = (SELECT user_id FROM devices WHERE id = ?)').bind(body.device_id).first<{ n: number }>())!.n;
    expect(await count()).toBe(2); // thiết bị chưa kéo qua
    await call(`/api/v1/sync/pull?since=${r.results[1].rev}`, { headers: auth });
    await cleanup(env, later);
    expect(await count()).toBe(1);
  });
});
