import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

import { purgeLapsedPro } from '../src/maintenance';
import { call, entState, entitlementFor, fakeEnvelope, fixture, json, login } from './helpers';

/**
 * T7 / ADR-0016 - gate TsuDEV Pro ở máy chủ (PRODUCT_POLICY 7.4 + checklist mục 8): 402 `pro_required` cho đẩy/tải
 * lên khi không Pro, JWS sai khoá/aud/typ/sub bị từ chối, đệm ≤ 24 giờ, kéo vẫn mở, dọn bản mã sau 90 ngày.
 */

type Auth = Record<string, string>;
const DAY_S = 86_400;
const now = () => Math.floor(Date.now() / 1000);

const req = async (path: string, auth: Auth, body?: unknown, method = 'POST', extra: Auth = {}) => {
  const res = await call(path, body === undefined ? { method, headers: { ...auth, ...extra } } : json(body, { ...auth, ...extra }, method));
  return { status: res.status, body: (await res.json()) as any, headers: res.headers };
};
const push = (auth: Auth, extra: Auth = {}) =>
  req('/api/v1/sync/push', auth, { records: [{ id: crypto.randomUUID(), type: 'txn', wallet_id: null, sealed: fakeEnvelope() }] }, 'POST', extra);
const callsFor = (sub: string) => entState.calls.filter((c) => c.sub === sub).length;
const dropCache = (userId: string) => env.DB.prepare('UPDATE entitlements SET fetched_at = 0 WHERE user_id = ?').bind(userId).run();
const userIdOf = async (sub: string) =>
  (await env.DB.prepare('SELECT id FROM users WHERE oidc_sub = ?').bind(sub).first<{ id: string }>())!.id;

/** Đăng nhập với quyền lợi đặt TRƯỚC (máy chủ quyền lợi giả trả theo `sub`). */
async function account(e: Parameters<typeof entitlementFor>[1]) {
  const sub = `user-${crypto.randomUUID()}`;
  entitlementFor(sub, e);
  return login(sub);
}

describe('TsuDEV Pro - gate máy chủ', () => {
  it('chưa có Pro: đẩy/tải tệp/tạo ví chung/bật email ⇒ 402 pro_required; kéo, xuất, khoá vẫn mở', async () => {
    const u = await account({ proUntil: 0, badge: 'none' });
    const p = await push(u.auth);
    expect(p.status).toBe(402);
    expect(p.body).toMatchObject({ error: 'pro_required', code: 'pro_required', reason: 'no_pro' });

    const file = await call(`/api/v1/files/${crypto.randomUUID()}`, {
      method: 'PUT',
      headers: { ...u.auth, 'Content-Length': '400' },
      body: new Uint8Array(400),
    });
    expect(file.status).toBe(402);
    expect((await req('/api/v1/wallets', u.auth, { wallet_id: crypto.randomUUID(), wrapped: fakeEnvelope(48) })).status).toBe(402);
    expect((await req('/api/v1/inbox/address', u.auth, {})).status).toBe(402);

    expect((await req('/api/v1/sync/pull?since=0', u.auth, undefined, 'GET')).status).toBe(200);
    expect((await req('/api/v1/me/export', u.auth, undefined, 'GET')).status).toBe(200);
    // Gói khoá vẫn lên được: cần để tham gia ví chung người khác mời (miễn phí, Q5).
    expect((await req('/api/v1/keys/account', u.auth, { bundle: fixture.bundle }, 'PUT')).status).toBe(200);
  });

  it('có Pro: đẩy được; đệm 24 giờ không hỏi lại tsudev.com; thiết bị mới được báo kèm mã cài đặt', async () => {
    const u = await account({ devices: 2 });
    const inst1 = 'AAAAAAAAAAAAAAAAAAAAAA';
    const inst2 = 'BBBBBBBBBBBBBBBBBBBBBB';
    expect((await push(u.auth, { 'X-Tsu-Installation': inst1, 'X-Tsu-Platform': 'Android' })).status).toBe(200);
    const after1 = callsFor(u.sub);
    expect(after1).toBe(1);
    expect(entState.calls.at(-1)).toMatchObject({ installation: inst1, platform: 'android' });
    expect((await push(u.auth, { 'X-Tsu-Installation': inst1 })).status).toBe(200);
    expect((await push(u.auth)).status).toBe(200);
    expect(callsFor(u.sub)).toBe(1);
    // Mã cài đặt khác ⇒ báo một lần; mã sai định dạng bị bỏ qua (không gửi đi, không gọi thêm).
    expect((await push(u.auth, { 'X-Tsu-Installation': inst2 })).status).toBe(200);
    expect(callsFor(u.sub)).toBe(2);
    expect((await push(u.auth, { 'X-Tsu-Installation': 'ngan-qua' })).status).toBe(200);
    expect(callsFor(u.sub)).toBe(2);

    const e = await req('/api/v1/me/entitlements', u.auth, undefined, 'GET');
    expect(e.status).toBe(200);
    expect(e.body).toMatchObject({ enforce: true, status: 'ok', pro: true, can_sync: true, badge: 'pro', devices_30d: 2, server_data_until: null });
    expect(typeof e.body.jws).toBe('string');
    expect(e.body.jws.split('.')).toHaveLength(3);
  });

  it('JWS sai khoá / sai aud / sai typ / sai sub ⇒ không cấp quyền (503, không đệm)', async () => {
    for (const tamper of ['key', 'aud', 'typ', 'sub'] as const) {
      const u = await account({ tamper });
      const p = await push(u.auth);
      expect(p.status, tamper).toBe(503);
      expect(p.body.code).toBe('entitlements_unavailable');
      const row = await env.DB.prepare('SELECT COUNT(*) AS n FROM entitlements WHERE user_id = ?').bind(await userIdOf(u.sub)).first<{ n: number }>();
      expect(row!.n).toBe(0);
    }
  });

  it('Pro đã hết hạn ⇒ 402, kéo vẫn được, báo mốc xoá bản mã sau 90 ngày', async () => {
    const until = now() - 10 * DAY_S;
    const u = await account({ proUntil: until });
    expect((await push(u.auth)).status).toBe(402);
    expect((await req('/api/v1/sync/pull?since=0', u.auth, undefined, 'GET')).status).toBe(200);
    const e = await req('/api/v1/me/entitlements', u.auth, undefined, 'GET');
    expect(e.body).toMatchObject({ pro: false, can_sync: false, pro_until: new Date(until * 1000).toISOString() });
    expect(e.body.server_data_until).toBe(new Date((until + 90 * DAY_S) * 1000).toISOString());
  });

  it('tsudev.com sập: đệm còn hạn thì dùng tiếp; không có đệm ⇒ 503 (không 402)', async () => {
    const u = await account({});
    expect((await push(u.auth)).status).toBe(200);
    entitlementFor(u.sub, { httpStatus: 500 });
    await env.DB.prepare('UPDATE entitlements SET fetched_at = ? WHERE user_id = ?').bind(Date.now() - 3600_000, await userIdOf(u.sub)).run();
    // Bắt buộc hỏi lại (mã cài đặt mới) nhưng tsudev.com lỗi ⇒ dùng đệm 1 giờ tuổi.
    expect((await push(u.auth, { 'X-Tsu-Installation': 'CCCCCCCCCCCCCCCCCCCCCC' })).status).toBe(200);
    await dropCache(await userIdOf(u.sub));
    const p = await push(u.auth);
    expect(p.status).toBe(503);
  });

  it('tsudev.com không nhận tài khoản (Grant hết hạn) ⇒ 402 reason=reauth; đăng nhập lại thì hỏi lại', async () => {
    const u = await account({ httpStatus: 404 });
    const p = await push(u.auth);
    expect(p.status).toBe(402);
    expect(p.body.reason).toBe('reauth');
    expect((await req('/api/v1/me/entitlements', u.auth, undefined, 'GET')).body.status).toBe('reauth');
    entitlementFor(u.sub, {});
    const again = await login(u.sub);
    expect((await push(again.auth)).status).toBe(200);
  });

  it('ví chung chạy bằng Pro của chủ ví: thành viên miễn phí ghi được; chủ ví hết Pro ⇒ 402 owner_no_pro', async () => {
    const owner = await account({});
    expect((await req('/api/v1/keys/account', owner.auth, { bundle: fixture.bundle }, 'PUT')).status).toBe(200);
    const walletId = crypto.randomUUID();
    expect((await req('/api/v1/wallets', owner.auth, { wallet_id: walletId, wrapped: fakeEnvelope(48) })).status).toBe(200);
    const member = await account({ proUntil: 0 });
    expect((await req('/api/v1/keys/account', member.auth, { bundle: fixture.shared.member_bundle }, 'PUT')).status).toBe(200);
    const inviteId = crypto.randomUUID();
    expect((await req(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: inviteId, role: 'editor' })).status).toBe(200);
    const proof = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(32))));
    expect((await req(`/api/v1/invites/${inviteId}/accept`, member.auth, { proof })).status).toBe(200);

    const share = new Uint8Array(3 + 1120 + 92);
    crypto.getRandomValues(share);
    share.set([0x51, 0x53, 0x01], 0);
    const wrapped = btoa(String.fromCharCode(...share));
    expect((await req(`/api/v1/wallets/${walletId}/members`, owner.auth, { invite_id: inviteId, key_ver: 1, wrapped })).status).toBe(200);

    const wpush = (auth: Auth) =>
      req(`/api/v1/wallets/${walletId}/push`, auth, { key_ver: 1, records: [{ id: crypto.randomUUID(), type: 'txn', sealed: fakeEnvelope() }] });
    expect((await wpush(member.auth)).status).toBe(200);

    entitlementFor(owner.sub, { proUntil: now() - DAY_S });
    await dropCache(await userIdOf(owner.sub));
    const p = await wpush(member.auth);
    expect(p.status).toBe(402);
    expect(p.body.reason).toBe('owner_no_pro');
    // Rời ví luôn được, không cần Pro.
    expect((await req(`/api/v1/wallets/${walletId}/members/me`, member.auth, undefined, 'DELETE')).status).toBe(200);
  });

  it('dọn bản mã: hết Pro quá 90 ngày ⇒ xoá; còn trong 90 ngày hoặc còn Pro ⇒ giữ; hỏi lại tsudev.com trước khi xoá', async () => {
    const mk = async (pushAs: Parameters<typeof entitlementFor>[1], later: Parameters<typeof entitlementFor>[1]) => {
      const u = await account(pushAs);
      expect((await push(u.auth)).status).toBe(200);
      entitlementFor(u.sub, later);
      const id = await userIdOf(u.sub);
      await dropCache(id);
      await env.DB.prepare('UPDATE entitlements SET pro_until = ? WHERE user_id = ?').bind(1000, id).run();
      return id;
    };
    const gone = await mk({}, { proUntil: now() - 91 * DAY_S });
    const recent = await mk({}, { proUntil: now() - 30 * DAY_S });
    const renewed = await mk({}, {});
    for (let i = 0; i < 20; i++) await purgeLapsedPro(env, Date.now(), 50);
    const count = async (id: string) =>
      (await env.DB.prepare('SELECT COUNT(*) AS n FROM records WHERE user_id = ?').bind(id).first<{ n: number }>())!.n;
    expect(await count(gone)).toBe(0);
    expect(await count(recent)).toBe(1);
    expect(await count(renewed)).toBe(1);
    const audit = await env.DB.prepare("SELECT COUNT(*) AS n FROM audit_log WHERE user_id = ? AND event = 'pro_data_purged'").bind(gone).first<{ n: number }>();
    expect(audit!.n).toBe(1);
  });

  it('PRO_ENFORCE=off: không gọi tsudev.com, đồng bộ mở như trước (bản chưa bật Pro)', async () => {
    const e = env as { PRO_ENFORCE: string };
    e.PRO_ENFORCE = 'off';
    try {
      const u = await account({ proUntil: 0 });
      expect((await push(u.auth)).status).toBe(200);
      expect(callsFor(u.sub)).toBe(0);
      const ent = await req('/api/v1/me/entitlements', u.auth, undefined, 'GET');
      // Có khoá RP ⇒ vẫn đọc quyền lợi để hiện huy hiệu, nhưng không chặn.
      expect(ent.body).toMatchObject({ enforce: false, pro: false, can_sync: true });
    } finally {
      e.PRO_ENFORCE = 'on';
    }
  });
});
