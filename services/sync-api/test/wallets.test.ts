import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

import { purgeDeletedAccounts } from '../src/maintenance';
import { call, fakeEnvelope, fixture, json, login } from './helpers';

type Auth = Record<string, string>;

const get = async (path: string, auth: Auth) => {
  const res = await call(path, { headers: auth });
  return { status: res.status, body: (await res.json()) as any };
};
const post = async (path: string, auth: Auth, body: unknown, method = 'POST') => {
  const res = await call(path, json(body, auth, method));
  return { status: res.status, body: (await res.json()) as any };
};

/** Khối chia sẻ giả đúng khung ('QS' 01, 1215 byte). */
function fakeShare(): string {
  const b = new Uint8Array(3 + 1120 + 92);
  crypto.getRandomValues(b);
  b.set([0x51, 0x53, 0x01], 0);
  let s = '';
  for (const x of b) s += String.fromCharCode(x);
  return btoa(s);
}
const ownWrap = () => fakeEnvelope(48);
const proof = () => btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(32))));

async function userWithKeys(bundle: unknown = fixture.shared.member_bundle) {
  const u = await login();
  expect((await post('/api/v1/keys/account', u.auth, { bundle }, 'PUT')).status).toBe(200);
  return u;
}

/** Chủ ví + ví chung trống + một thành viên quyền [role]. */
async function sharedWallet(role: 'editor' | 'viewer' = 'editor') {
  const owner = await userWithKeys(fixture.bundle);
  const walletId = crypto.randomUUID();
  expect((await post('/api/v1/wallets', owner.auth, { wallet_id: walletId, wrapped: ownWrap() })).status).toBe(200);
  const member = await userWithKeys();
  const inviteId = crypto.randomUUID();
  expect((await post(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: inviteId, role })).status).toBe(200);
  expect((await post(`/api/v1/invites/${inviteId}/accept`, member.auth, { proof: proof() })).status).toBe(200);
  const list = await get('/api/v1/wallets', owner.auth);
  const memberId = list.body.wallets[0].invites[0].accepted.user_id as string;
  expect(
    (await post(`/api/v1/wallets/${walletId}/members`, owner.auth, { invite_id: inviteId, key_ver: 1, wrapped: fakeShare() })).status,
  ).toBe(200);
  return { owner, member, memberId, walletId };
}

const txn = (id = crypto.randomUUID()) => ({ id, type: 'txn', sealed: fakeEnvelope() });

describe('ví chung', () => {
  it('trọn luồng với dữ liệu THẬT của lõi: chia sẻ, chuyển bản ghi, mời, nhận, hoàn tất, đồng bộ', async () => {
    const owner = await userWithKeys(fixture.bundle);
    const walletId = fixture.wallet_key.wallet_id;
    expect((await post('/api/v1/sync/push', owner.auth, { records: fixture.records })).status).toBe(200);

    const created = await post('/api/v1/wallets', owner.auth, { wallet_id: walletId, wrapped: fixture.shared.owner_wrapped });
    expect(created.status).toBe(200);
    expect(created.body).toEqual({ wallet_id: walletId, key_ver: 1, rev: 2 });
    expect((await post('/api/v1/wallets', owner.auth, { wallet_id: walletId, wrapped: ownWrap() })).body.code).toBe('wallet_exists');
    // Bản ghi đã chuyển hẳn sang không gian ví, nguyên byte, theo thứ tự rev cũ.
    expect((await get('/api/v1/sync/pull', owner.auth)).body.records).toEqual([]);
    const pulled = await get(`/api/v1/wallets/${walletId}/pull`, owner.auth);
    expect(pulled.body.records.map((r: any) => [r.sealed, r.key_ver, r.rev])).toEqual([
      [fixture.records[0]!.sealed, 1, 1],
      [fixture.records[1]!.sealed, 1, 2],
    ]);
    // Thiết bị cũ còn đẩy vào không gian tài khoản ⇒ từ chối từng bản ghi.
    const old = await post('/api/v1/sync/push', owner.auth, { records: [{ ...fixture.records[0], sealed: fakeEnvelope() }] });
    expect(old.body.results[0]).toMatchObject({ status: 'rejected', reason: 'shared_wallet' });

    const member = await userWithKeys();
    const inviteId = fixture.shared.invite_id;
    const inv = await post(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: inviteId, role: 'editor' });
    expect(inv.status).toBe(200);
    expect((await get(`/api/v1/invites/${inviteId}`, owner.auth)).body.state).toBe('own');
    const info = await get(`/api/v1/invites/${inviteId}`, member.auth);
    expect(info.body).toMatchObject({ wallet_id: walletId, role: 'editor', state: 'open', owner_name: 'Người Dùng' });
    expect((await post(`/api/v1/invites/${inviteId}/accept`, owner.auth, { proof: fixture.shared.proof })).body.code).toBe(
      'already_member',
    );
    expect((await post(`/api/v1/invites/${inviteId}/accept`, member.auth, { proof: fixture.shared.proof })).status).toBe(200);
    expect((await get(`/api/v1/invites/${inviteId}`, member.auth)).body.state).toBe('accepted');
    const pending = await get('/api/v1/wallets', member.auth);
    expect(pending.body.wallets).toEqual([]);
    expect(pending.body.pending).toMatchObject([{ invite_id: inviteId, wallet_id: walletId, role: 'editor' }]);

    // Chủ ví thấy khóa công khai lấy từ gói khóa ĐÃ ĐĂNG KÝ của người nhận + bằng chứng nguyên vẹn.
    const ownerView = await get('/api/v1/wallets', owner.auth);
    const w = ownerView.body.wallets[0];
    expect(w).toMatchObject({ wallet_id: walletId, role: 'owner', key_ver: 1, rev: 2, needs_rotation: false });
    expect(w.shares).toEqual([{ key_ver: 1, wrapped: fixture.shared.owner_wrapped }]);
    expect(w.invites[0].accepted.kem_pk).toBe(fixture.shared.member_bundle.kemPk);
    expect(w.invites[0].accepted.proof).toBe(fixture.shared.proof);
    const memberId = w.invites[0].accepted.user_id;

    const done = await post(`/api/v1/wallets/${walletId}/members`, owner.auth, {
      invite_id: inviteId,
      key_ver: 1,
      wrapped: fixture.shared.member_share,
    });
    expect(done.body).toEqual({ user_id: memberId, role: 'editor' });
    const mv = (await get('/api/v1/wallets', member.auth)).body;
    expect(mv.pending).toEqual([]);
    expect(mv.wallets[0]).toMatchObject({ wallet_id: walletId, role: 'editor', key_ver: 1, invites: [], needs_rotation: false });
    expect(mv.wallets[0].shares).toEqual([{ key_ver: 1, wrapped: fixture.shared.member_share }]);
    expect(mv.wallets[0].members.map((m: any) => m.role)).toEqual(['owner', 'editor']);
    expect(mv.wallets[0].members[0].kem_pk).toBe(fixture.bundle.kemPk);
    expect((await get(`/api/v1/invites/${inviteId}`, member.auth)).status).toBe(404);

    const mp = await get(`/api/v1/wallets/${walletId}/pull?since=1`, member.auth);
    expect(mp.body.records.map((r: any) => r.id)).toEqual([fixture.records[1]!.id]);
    const pushed = await post(`/api/v1/wallets/${walletId}/push`, member.auth, { key_ver: 1, records: [txn()] });
    expect(pushed.body.results[0]).toMatchObject({ status: 'applied', rev: 3 });
  });

  it('quyền: người ghi không sửa thông tin ví, không mời; người xem không ghi; người ngoài không thấy gì', async () => {
    const { owner, member, memberId, walletId } = await sharedWallet('editor');
    const asWallet = { id: walletId, type: 'wallet', sealed: fakeEnvelope() };
    const r = await post(`/api/v1/wallets/${walletId}/push`, member.auth, { key_ver: 1, records: [asWallet, txn()] });
    expect(r.body.results.map((x: any) => x.reason ?? x.status)).toEqual(['forbidden', 'applied']);
    expect((await post(`/api/v1/wallets/${walletId}/push`, owner.auth, { key_ver: 1, records: [asWallet] })).body.results[0].status).toBe(
      'applied',
    );
    expect((await post(`/api/v1/wallets/${walletId}/invites`, member.auth, { invite_id: crypto.randomUUID(), role: 'viewer' })).status).toBe(
      403,
    );
    expect((await post(`/api/v1/wallets/${walletId}/members/${memberId}`, owner.auth, { role: 'viewer' }, 'PUT')).status).toBe(200);
    const ro = await post(`/api/v1/wallets/${walletId}/push`, member.auth, { key_ver: 1, records: [txn()] });
    expect([ro.status, ro.body.code]).toEqual([403, 'read_only']);
    expect((await get(`/api/v1/wallets/${walletId}/pull`, member.auth)).body.records).toHaveLength(2);

    const stranger = await userWithKeys();
    for (const res of [
      await get(`/api/v1/wallets/${walletId}/pull`, stranger.auth),
      await post(`/api/v1/wallets/${walletId}/push`, stranger.auth, { key_ver: 1, records: [txn()] }),
      await post(`/api/v1/wallets/${walletId}/invites`, stranger.auth, { invite_id: crypto.randomUUID(), role: 'editor' }),
      await post(`/api/v1/wallets/${walletId}/rotate`, stranger.auth, { key_ver: 2, shares: [] }),
    ]) {
      expect(res.status).toBe(res.status === 400 ? 400 : 404);
    }
    expect((await get('/api/v1/wallets', stranger.auth)).body.wallets).toEqual([]);
  });

  it('lời mời: một người dùng, hết hạn, cần khóa mã hóa, khung khóa sai bị từ chối', async () => {
    const owner = await userWithKeys(fixture.bundle);
    const walletId = crypto.randomUUID();
    await post('/api/v1/wallets', owner.auth, { wallet_id: walletId, wrapped: ownWrap() });
    const iid = crypto.randomUUID();
    await post(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: iid, role: 'viewer' });
    const noKeys = await login();
    expect((await post(`/api/v1/invites/${iid}/accept`, noKeys.auth, { proof: proof() })).body.code).toBe('no_keys');
    const a = await userWithKeys();
    const b = await userWithKeys();
    expect((await post(`/api/v1/invites/${iid}/accept`, a.auth, { proof: proof() })).status).toBe(200);
    expect((await post(`/api/v1/invites/${iid}/accept`, b.auth, { proof: proof() })).body.code).toBe('invite_taken');
    expect((await get(`/api/v1/invites/${iid}`, b.auth)).body.state).toBe('taken');
    expect((await post(`/api/v1/invites/${iid}/accept`, a.auth, { proof: 'abc' })).status).toBe(400);
    // Hoàn tất bằng bản bọc của chính mình (không phải khối 'QS') hoặc sai phiên bản ⇒ từ chối.
    expect((await post(`/api/v1/wallets/${walletId}/members`, owner.auth, { invite_id: iid, key_ver: 1, wrapped: ownWrap() })).status).toBe(
      400,
    );
    expect((await post(`/api/v1/wallets/${walletId}/members`, owner.auth, { invite_id: iid, key_ver: 2, wrapped: fakeShare() })).body.code).toBe(
      'stale_key',
    );
    // Lời mời chưa ai nhận thì không hoàn tất được.
    const open = crypto.randomUUID();
    await post(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: open, role: 'editor' });
    expect((await post(`/api/v1/wallets/${walletId}/members`, owner.auth, { invite_id: open, key_ver: 1, wrapped: fakeShare() })).status).toBe(
      404,
    );
    expect((await call(`/api/v1/wallets/${walletId}/invites/${open}`, { method: 'DELETE', headers: owner.auth })).status).toBe(200);
    expect((await get(`/api/v1/invites/${open}`, a.auth)).status).toBe(404);
    // Hết hạn.
    const late = crypto.randomUUID();
    await post(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: late, role: 'editor' });
    await env.DB.prepare('UPDATE wallet_invites SET expires_at = 1 WHERE id = ?').bind(late).run();
    expect((await post(`/api/v1/invites/${late}/accept`, b.auth, { proof: proof() })).body.code).toBe('invite_gone');
    // Ví không có khóa mã hóa, id dành riêng, khóa sai khung.
    const bare = await login();
    expect((await post('/api/v1/wallets', bare.auth, { wallet_id: crypto.randomUUID(), wrapped: ownWrap() })).body.code).toBe('no_keys');
    expect((await post('/api/v1/wallets', owner.auth, { wallet_id: '00000000-0000-4000-8000-000000000000', wrapped: ownWrap() })).status).toBe(
      400,
    );
    expect((await post('/api/v1/wallets', owner.auth, { wallet_id: crypto.randomUUID(), wrapped: fakeShare() })).status).toBe(400);
  });

  it('thu hồi = xoay khóa: đúng tập thành viên còn lại, người bị thu hồi mất quyền ngay, ghi bằng khóa cũ bị chặn', async () => {
    const { owner, member, memberId, walletId } = await sharedWallet('editor');
    const second = await userWithKeys();
    const iid = crypto.randomUUID();
    await post(`/api/v1/wallets/${walletId}/invites`, owner.auth, { invite_id: iid, role: 'viewer' });
    await post(`/api/v1/invites/${iid}/accept`, second.auth, { proof: proof() });
    const view = (await get('/api/v1/wallets', owner.auth)).body.wallets[0];
    const secondId = view.invites[0].accepted.user_id;
    await post(`/api/v1/wallets/${walletId}/members`, owner.auth, { invite_id: iid, key_ver: 1, wrapped: fakeShare() });
    const ownerId = view.owner_id;
    await post(`/api/v1/wallets/${walletId}/push`, member.auth, { key_ver: 1, records: [txn()] });

    const rotate = (body: unknown) => post(`/api/v1/wallets/${walletId}/rotate`, owner.auth, body);
    // Thiếu người còn lại / vẫn gửi khóa cho người bị thu hồi / sai phiên bản ⇒ từ chối, không đổi gì.
    expect((await rotate({ key_ver: 2, remove: [memberId], shares: [{ user_id: ownerId, wrapped: ownWrap() }] })).body.code).toBe(
      'members_changed',
    );
    expect(
      (
        await rotate({
          key_ver: 2,
          remove: [memberId],
          shares: [
            { user_id: ownerId, wrapped: ownWrap() },
            { user_id: secondId, wrapped: fakeShare() },
            { user_id: memberId, wrapped: fakeShare() },
          ],
        })
      ).body.code,
    ).toBe('members_changed');
    expect((await rotate({ key_ver: 3, remove: [], shares: [{ user_id: ownerId, wrapped: ownWrap() }] })).body.code).toBe('stale_key');
    expect((await rotate({ key_ver: 2, remove: [ownerId], shares: [] })).status).toBe(400);

    const ok = await rotate({
      key_ver: 2,
      remove: [memberId],
      shares: [
        { user_id: ownerId, wrapped: ownWrap() },
        { user_id: secondId, wrapped: fakeShare() },
      ],
    });
    expect(ok.body).toEqual({ key_ver: 2 });
    expect((await get(`/api/v1/wallets/${walletId}/pull`, member.auth)).status).toBe(404);
    expect((await get('/api/v1/wallets', member.auth)).body.wallets).toEqual([]);
    const stale = await post(`/api/v1/wallets/${walletId}/push`, owner.auth, { key_ver: 1, records: [txn()] });
    expect([stale.status, stale.body.code]).toEqual([409, 'stale_key']);
    const fresh = await post(`/api/v1/wallets/${walletId}/push`, owner.auth, { key_ver: 2, records: [txn()] });
    expect(fresh.body.results[0].status).toBe('applied');
    const pulled = await get(`/api/v1/wallets/${walletId}/pull`, second.auth);
    expect(pulled.body.key_ver).toBe(2);
    expect(pulled.body.records.map((r: any) => r.key_ver)).toEqual([1, 2]);
    const sv = (await get('/api/v1/wallets', second.auth)).body.wallets[0];
    expect(sv.shares.map((s: any) => s.key_ver)).toEqual([1, 2]);
    expect(sv.members.map((m: any) => m.user_id).sort()).toEqual([ownerId, secondId].sort());
    // Thiết bị chủ ví thứ hai xoay cùng phiên bản ⇒ một lượt thắng.
    expect((await rotate({ key_ver: 2, shares: [{ user_id: ownerId, wrapped: ownWrap() }, { user_id: secondId, wrapped: fakeShare() }] })).body.code).toBe(
      'stale_key',
    );
  });

  it('thành viên rời ví ⇒ chủ ví được báo xoay khóa; chủ ví không rời được', async () => {
    const { owner, member, walletId } = await sharedWallet('viewer');
    expect((await call(`/api/v1/wallets/${walletId}/members/me`, { method: 'DELETE', headers: owner.auth })).status).toBe(409);
    expect((await call(`/api/v1/wallets/${walletId}/members/me`, { method: 'DELETE', headers: member.auth })).status).toBe(200);
    const w = (await get('/api/v1/wallets', owner.auth)).body.wallets[0];
    expect(w.needs_rotation).toBe(true);
    expect(w.members).toHaveLength(1);
    await post(`/api/v1/wallets/${walletId}/rotate`, owner.auth, { key_ver: 2, shares: [{ user_id: w.owner_id, wrapped: ownWrap() }] });
    expect((await get('/api/v1/wallets', owner.auth)).body.wallets[0].needs_rotation).toBe(false);
  });

  it('xuất dữ liệu gồm ví chung; xóa tài khoản chủ ví xóa ví chung, thành viên mất quyền', async () => {
    const { owner, member, walletId } = await sharedWallet('editor');
    await post(`/api/v1/wallets/${walletId}/push`, member.auth, { key_ver: 1, records: [txn()] });
    const exp: any = await (await call('/api/v1/me/export', { headers: member.auth })).json();
    expect(exp.shared_wallet_keys).toMatchObject([{ wallet_id: walletId, role: 'editor', key_ver: 1 }]);
    expect(exp.shared_records).toHaveLength(1);

    expect((await call('/api/v1/me/deletion', { method: 'POST', headers: owner.auth })).status).toBe(202);
    await purgeDeletedAccounts(env, Date.now() + 31 * 24 * 3600 * 1000, 1000);
    const rows = await env.DB.prepare(
      `SELECT (SELECT COUNT(*) FROM shared_wallets WHERE id = ?1) + (SELECT COUNT(*) FROM wallet_records WHERE wallet_id = ?1)
         + (SELECT COUNT(*) FROM wallet_members WHERE wallet_id = ?1) + (SELECT COUNT(*) FROM wallet_key_shares WHERE wallet_id = ?1) AS n`,
    )
      .bind(walletId)
      .first<{ n: number }>();
    expect(rows?.n).toBe(0);
    expect((await get(`/api/v1/wallets/${walletId}/pull`, member.auth)).status).toBe(404);
  });
});

// ------------------------------------------------------------------ P7b tệp của ví chung (ADR-0017)

function sealedFile(padded = 65536): Uint8Array {
  const bytes = new Uint8Array(4 + 24 + padded + 16);
  crypto.getRandomValues(bytes.subarray(0, 65536));
  bytes.set([0x51, 0x54, 0x01, 0x01], 0);
  return bytes;
}
const putFile = (path: string, auth: Auth, body: Uint8Array) =>
  call(path, { method: 'PUT', headers: { ...auth, 'Content-Length': String(body.length) }, body });

describe('tệp đính kèm của ví chung', () => {
  it('người ghi tải lên, chủ ví + người xem tải về đúng byte, tính vào hạn mức chủ ví; người ngoài 404', async () => {
    const { owner, member, walletId } = await sharedWallet('editor');
    const id = crypto.randomUUID();
    const path = `/api/v1/wallets/${walletId}/files/${id}`;
    const data = sealedFile();
    expect((await putFile(path, member.auth, data)).status).toBe(201);
    expect(((await (await putFile(path, member.auth, data)).json()) as any).status).toBe('unchanged');
    const down = await call(path, { headers: owner.auth });
    expect(down.status).toBe(200);
    expect(down.headers.get('Cache-Control')).toBe('private, no-store');
    expect(new Uint8Array(await down.arrayBuffer())).toEqual(data);
    expect((await get('/api/v1/me/usage', owner.auth)).body.files).toMatchObject({ count: 1, bytes: data.length });
    expect((await get('/api/v1/me/usage', member.auth)).body.files).toMatchObject({ count: 0, bytes: 0 });
    // Người ngoài ví: 404 như ví không tồn tại, không xoá được.
    const stranger = await login();
    expect((await call(path, { headers: stranger.auth })).status).toBe(404);
    expect((await call(path, { method: 'DELETE', headers: stranger.auth })).status).toBe(404);
    expect((await putFile(`/api/v1/wallets/${walletId}/files/${crypto.randomUUID()}`, stranger.auth, data)).status).toBe(404);
    // Tệp cá nhân không nhận wallet_id của ví chung (thành viên khác sẽ không đọc được).
    expect((await putFile(`/api/v1/files/${crypto.randomUUID()}?wallet_id=${walletId}`, owner.auth, data)).status).toBe(409);
    // Xoá ⇒ mất ở R2.
    expect((await call(path, { method: 'DELETE', headers: owner.auth })).status).toBe(204);
    expect((await call(path, { headers: member.auth })).status).toBe(404);
    expect(await env.FILES.get(`w/${walletId}/${id}`)).toBeNull();
  });

  it('người xem chỉ tải về được; tải lên/xoá ⇒ 403 read_only; bị thu hồi ⇒ 404', async () => {
    const { owner, member, walletId, memberId } = await sharedWallet('viewer');
    const id = crypto.randomUUID();
    const path = `/api/v1/wallets/${walletId}/files/${id}`;
    expect((await putFile(path, owner.auth, sealedFile())).status).toBe(201);
    expect((await call(path, { headers: member.auth })).status).toBe(200);
    const up = await putFile(`/api/v1/wallets/${walletId}/files/${crypto.randomUUID()}`, member.auth, sealedFile());
    expect(up.status).toBe(403);
    expect(((await up.json()) as any).code).toBe('read_only');
    expect((await call(path, { method: 'DELETE', headers: member.auth })).status).toBe(403);
    expect((await call(path, { headers: owner.auth })).status).toBe(200);
    await env.DB.prepare('DELETE FROM wallet_members WHERE wallet_id = ? AND user_id = ?').bind(walletId, memberId).run();
    expect((await call(path, { headers: member.auth })).status).toBe(404);
  });

  it('xoá tài khoản chủ ví ⇒ xoá luôn tệp R2 của ví chung', async () => {
    const { owner, walletId } = await sharedWallet('editor');
    const id = crypto.randomUUID();
    expect((await putFile(`/api/v1/wallets/${walletId}/files/${id}`, owner.auth, sealedFile())).status).toBe(201);
    const ownerId = (await env.DB.prepare('SELECT owner_id FROM shared_wallets WHERE id = ?').bind(walletId).first<{ owner_id: string }>())!.owner_id;
    await env.DB.prepare('UPDATE users SET deletion_requested_at = 1 WHERE id = ?').bind(ownerId).run();
    await purgeDeletedAccounts(env, Date.now());
    expect(await env.FILES.get(`w/${walletId}/${id}`)).toBeNull();
    expect(await env.DB.prepare('SELECT 1 FROM wallet_files WHERE wallet_id = ?').bind(walletId).first()).toBeNull();
  });
});
