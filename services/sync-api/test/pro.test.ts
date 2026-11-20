import { env } from 'cloudflare:workers';
import { beforeEach, describe, expect, it } from 'vitest';

import { purgeLapsedPro } from '../src/maintenance';
import { RP_AUD, RP_STATUS_AUD, call, entState, entitlementFor, fakeEnvelope, fixture, json, login, playState, statusFor, statusState } from './helpers';

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
    // Tệp của ví chung cũng theo Pro của CHỦ ví (P7b, ADR-0017).
    const sealed = new Uint8Array(4 + 24 + 65536 + 16);
    sealed.set([0x51, 0x54, 0x01, 0x01], 0);
    const fput = await call(`/api/v1/wallets/${walletId}/files/${crypto.randomUUID()}`, {
      method: 'PUT',
      headers: { ...member.auth, 'Content-Length': String(sealed.length) },
      body: sealed,
    });
    expect(fput.status).toBe(402);
    expect(((await fput.json()) as any).reason).toBe('owner_no_pro');
    // Rời ví luôn được, không cần Pro.
    expect((await req(`/api/v1/wallets/${walletId}/members/me`, member.auth, undefined, 'DELETE')).status).toBe(200);
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

/**
 * PRO2 / ADR-0018 - xoá bản mã vì hết Pro CÓ XÁC MINH (PRODUCT_POLICY v1.2.0 mục 7.4 "Kênh trạng thái"): hỏi
 * `POST /api/rp/entitlements/status` ngay trước mọi lần xoá; đã gia hạn ⇒ giữ + cập nhật hạn; lỗi/unknown ⇒ hoãn 24 giờ.
 */
describe('TsuDEV Pro - xoá có xác minh qua kênh trạng thái', () => {
  // D1 dùng chung cả bộ test: tài khoản của tệp/ca khác (có bản ghi, không đệm quyền lợi) cũng là ứng viên, và `LIMIT`
  // không thứ tự có thể bỏ sót tài khoản của ca đang chạy. Đánh dấu mọi tài khoản cũ là "vừa hỏi" trước mỗi ca.
  beforeEach(async () => {
    await env.DB.prepare(
      `INSERT INTO pro_purge_checks (user_id, checked_at) SELECT id, ?1 FROM users WHERE 1
       ON CONFLICT(user_id) DO UPDATE SET checked_at = ?1`,
    )
      .bind(Date.now())
      .run();
  });
  /** Tài khoản có 1 bản ghi trên máy chủ, đệm cục bộ ghi `pro_until` đã quá 90 ngày (ứng viên xoá). */
  async function lapsed() {
    const u = await account({});
    expect((await push(u.auth)).status).toBe(200);
    const id = await userIdOf(u.sub);
    await env.DB.prepare('UPDATE entitlements SET pro_until = ? WHERE user_id = ?').bind(1000, id).run();
    return { ...u, id };
  }
  const records = async (id: string) =>
    (await env.DB.prepare('SELECT COUNT(*) AS n FROM records WHERE user_id = ?').bind(id).first<{ n: number }>())!.n;
  const cachedUntil = async (id: string) =>
    (await env.DB.prepare('SELECT pro_until FROM entitlements WHERE user_id = ?').bind(id).first<{ pro_until: number }>())!.pro_until;
  const statusCalls = (sub: string) => statusState.calls.filter((c) => c.subs.includes(sub)).length;
  const audit = async (id: string) =>
    (await env.DB.prepare("SELECT detail FROM audit_log WHERE user_id = ? AND event = 'pro_data_purged'").bind(id).all<{ detail: string }>()).results;
  const run = () => purgeLapsedPro(env, Date.now(), 50);

  it('hết hạn thật (ok quá 90 ngày) ⇒ xoá; tài khoản tsudev đã xoá (deleted) ⇒ xoá; luôn hỏi kênh trạng thái trước', async () => {
    const expired = await lapsed();
    const deleted = await lapsed();
    statusFor(expired.sub, { status: 'ok', pro_until: now() - 91 * DAY_S });
    statusFor(deleted.sub, { status: 'deleted' });
    await run();
    expect(statusCalls(expired.sub)).toBe(1);
    expect(statusCalls(deleted.sub)).toBe(1);
    expect(await records(expired.id)).toBe(0);
    expect(await records(deleted.id)).toBe(0);
    expect(await audit(expired.id)).toEqual([{ detail: 'verified:ok' }]);
    expect(await audit(deleted.id)).toEqual([{ detail: 'verified:deleted' }]);
  });

  it('gia hạn trên web mà không mở app (kênh RP 404 vì grant quá 30 ngày) ⇒ KHÔNG xoá + cập nhật hạn đã đệm', async () => {
    const u = await lapsed();
    const renewedUntil = now() + 300 * DAY_S;
    entitlementFor(u.sub, { httpStatus: 404 });
    statusFor(u.sub, { status: 'ok', pro_until: renewedUntil });
    const rpBefore = callsFor(u.sub);
    await run();
    expect(await records(u.id)).toBe(1);
    expect(await cachedUntil(u.id)).toBe(renewedUntil * 1000);
    expect(await audit(u.id)).toEqual([]);
    // Không dựa vào kênh RP `GET /{sub}` để quyết định xoá.
    expect(callsFor(u.sub)).toBe(rpBefore);
    // Hạn mới ⇒ không còn là ứng viên, lượt sau không hỏi lại.
    await env.DB.prepare('UPDATE pro_purge_checks SET checked_at = 0 WHERE user_id = ?').bind(u.id).run();
    await run();
    expect(statusCalls(u.sub)).toBe(1);
  });

  it('hết Pro mới 30 ngày (ok, còn trong 90 ngày) ⇒ giữ, cập nhật hạn', async () => {
    const u = await lapsed();
    statusFor(u.sub, { status: 'ok', pro_until: now() - 30 * DAY_S });
    await run();
    expect(await records(u.id)).toBe(1);
    expect(await cachedUntil(u.id)).toBe((now() - 30 * DAY_S) * 1000);
  });

  it('kênh lỗi / hết giờ / khung sai / 404 / unknown_subject / thiếu mục ⇒ hoãn, không hỏi lại trong 24 giờ; sau 24 giờ hỏi lại', async () => {
    const cases = ['http500', 'timeout', 'bad_body', 'http404', 'unknown_subject', 'omit'] as const;
    for (const c of cases) {
      const u = await lapsed();
      statusFor(u.sub, { status: 'ok', pro_until: now() - 200 * DAY_S });
      if (c === 'unknown_subject' || c === 'omit') statusFor(u.sub, { status: c });
      else statusState.mode = c;
      try {
        await run();
        await run();
      } finally {
        statusState.mode = 'ok';
      }
      expect(await records(u.id), c).toBe(1);
      expect(statusCalls(u.sub), c).toBe(1);
      expect(await audit(u.id), c).toEqual([]);
      // 25 giờ sau: hỏi lại; lần này tsudev.com xác nhận hết hạn ⇒ xoá.
      statusFor(u.sub, { status: 'ok', pro_until: now() - 200 * DAY_S });
      await env.DB.prepare('UPDATE pro_purge_checks SET checked_at = ? WHERE user_id = ?').bind(Date.now() - 25 * 3600_000, u.id).run();
      await run();
      expect(statusCalls(u.sub), c).toBe(2);
      expect(await records(u.id), c).toBe(0);
    }
  });

  it('client assertion của kênh trạng thái: iss = sub = client_id, aud = đúng URL kênh, exp ≤ 300 giây, jti một lần', async () => {
    const a = await lapsed();
    const b = await lapsed();
    statusFor(a.sub, { status: 'unknown_subject' });
    statusFor(b.sub, { status: 'unknown_subject' });
    const from = statusState.calls.length;
    await purgeLapsedPro(env, Date.now(), 50);
    await env.DB.prepare('UPDATE pro_purge_checks SET checked_at = 0 WHERE user_id IN (?, ?)').bind(a.id, b.id).run();
    await purgeLapsedPro(env, Date.now(), 50);
    const mine = statusState.calls.slice(from).filter((c) => c.subs.includes(a.sub));
    expect(mine).toHaveLength(2);
    for (const c of mine) {
      expect(c.ok).toBe(true);
      expect(c.clientId).toBe('qulythuchi');
      expect(c.claims).toMatchObject({ iss: 'qulythuchi', sub: 'qulythuchi', aud: RP_STATUS_AUD });
      expect((c.claims.exp as number) - (c.claims.iat as number)).toBeLessThanOrEqual(300);
      expect(typeof c.claims.jti).toBe('string');
      expect(c.subs.length).toBeLessThanOrEqual(100);
    }
    expect(mine[0]!.claims.jti).not.toBe(mine[1]!.claims.jti);
    expect(await records(a.id)).toBe(1);
  });

  it('chưa cấu hình kênh trạng thái ⇒ không xoá theo đệm, không gọi tsudev.com', async () => {
    const u = await lapsed();
    statusFor(u.sub, { status: 'deleted' });
    const e = env as { ENTITLEMENTS_STATUS_URL?: string };
    const saved = e.ENTITLEMENTS_STATUS_URL;
    delete e.ENTITLEMENTS_STATUS_URL;
    try {
      await run();
    } finally {
      e.ENTITLEMENTS_STATUS_URL = saved;
    }
    expect(statusCalls(u.sub)).toBe(0);
    expect(await records(u.id)).toBe(1);
  });
});

describe('TsuDEV Pro - biên nhận Google Play (ADR-0019)', () => {
  const token = 'tok_' + 'a'.repeat(40);
  it('chuyển đúng sub + mã sản phẩm lên tsudev.com bằng client assertion aud = URL kênh; thành công ⇒ làm mới quyền lợi', async () => {
    const u = await account({ proUntil: 0, badge: 'none' });
    playState.mode = 200;
    const before = callsFor(u.sub);
    const r = await req('/api/v1/me/purchases/play', u.auth, { product_id: 'tsudev_pro', purchase_token: token });
    expect(r.status).toBe(200);
    expect(r.body).toEqual({ verified: true });
    const last = playState.calls.at(-1)!;
    expect(last.body).toEqual({ client_id: 'qulythuchi', sub: u.sub, packageName: 'com.tsudev.qulythuchi', productId: 'tsudev_pro', purchaseToken: token });
    expect(last.claims).toMatchObject({ iss: 'qulythuchi', sub: 'qulythuchi', aud: `${RP_AUD}/play` });
    expect(callsFor(u.sub)).toBe(before + 1);
  });

  it('mã sản phẩm lạ (kể cả gói tháng cũ) hoặc mã mua sai dạng ⇒ 400, không gọi tsudev.com', async () => {
    const u = await account({});
    const n = playState.calls.length;
    for (const body of [
      { product_id: 'thang', purchase_token: token },
      { product_id: 'tsudev_pro_thang', purchase_token: token },
      { product_id: 'tsudev_pro', purchase_token: 'ngắn' },
      { product_id: 'ung_ho_20k' },
    ]) {
      expect((await req('/api/v1/me/purchases/play', u.auth, body)).status).toBe(400);
    }
    expect(playState.calls.length).toBe(n);
  });

  it('tsudev.com từ chối biên nhận ⇒ 400 purchase_invalid; kênh chưa có/sập ⇒ 503 purchase_unavailable', async () => {
    const u = await account({});
    playState.mode = 422;
    expect((await req('/api/v1/me/purchases/play', u.auth, { product_id: 'ung_ho_50k', purchase_token: token })).body.code).toBe('purchase_invalid');
    for (const mode of [405, 404, 500]) {
      playState.mode = mode;
      const r = await req('/api/v1/me/purchases/play', u.auth, { product_id: 'tsudev_pro', purchase_token: token });
      expect(r.status).toBe(503);
      expect(r.body.code).toBe('purchase_unavailable');
    }
    playState.mode = 200;
  });

  it('chưa đăng nhập ⇒ 401', async () => {
    expect((await call('/api/v1/me/purchases/play', json({ product_id: 'tsudev_pro', purchase_token: token }))).status).toBe(401);
  });
});

describe('Huy hiệu thành viên ví chung', () => {
  it('trả badge từ đệm quyền lợi còn hạn; Pro đã hết ⇒ tắt phần Pro, giữ Ủng hộ', async () => {
    const owner = await account({ badge: 'both' });
    expect((await push(owner.auth)).status).toBe(200); // tạo đệm quyền lợi
    expect((await req('/api/v1/keys/account', owner.auth, { bundle: fixture.bundle }, 'PUT')).status).toBe(200);
    const wid = crypto.randomUUID();
    expect((await req('/api/v1/wallets', owner.auth, { wallet_id: wid, wrapped: fakeEnvelope(48) })).status).toBe(200);
    const list = async () => {
      const r = await req('/api/v1/wallets', owner.auth, undefined, 'GET');
      return r.body.wallets.find((w: any) => w.wallet_id === wid).members[0].badge;
    };
    expect(await list()).toBe('both');
    const uid = await userIdOf(owner.sub);
    await env.DB.prepare('UPDATE entitlements SET pro_until = ? WHERE user_id = ?').bind(Date.now() - 1000, uid).run();
    expect(await list()).toBe('donor');
    await env.DB.prepare('UPDATE entitlements SET jws_exp = 0 WHERE user_id = ?').bind(uid).run();
    expect(await list()).toBe('none');
  });
});
