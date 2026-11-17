import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

import { call, fakeEnvelope, fixture, json, login } from './helpers';

const push = (auth: Record<string, string>, records: unknown[]) => call('/api/v1/sync/push', json({ records }, auth));
const pull = async (auth: Record<string, string>, q = '') => {
  const res = await call(`/api/v1/sync/pull${q}`, { headers: auth });
  return { status: res.status, body: (await res.json()) as any };
};

describe('đồng bộ bản mã', () => {
  it('nhận phong bì THẬT của lõi Dart, trả nguyên byte khi kéo', async () => {
    const { auth } = await login();
    const res = await push(auth, fixture.records);
    expect(res.status).toBe(200);
    const out: any = await res.json();
    expect(out.results.map((r: any) => r.status)).toEqual(['applied', 'applied']);
    expect(out.results[1].rev).toBeGreaterThan(out.results[0].rev);
    const { body } = await pull(auth);
    expect(body.records.map((r: any) => r.sealed)).toEqual(fixture.records.map((r) => r.sealed));
    expect(body.records[0]).toMatchObject({ id: fixture.records[0]!.id, type: 'txn', wallet_id: fixture.records[0]!.wallet_id, deleted: false });
    expect(body.has_more).toBe(false);
    expect(body.cursor).toBe(out.results[1].rev);
  });

  it('đẩy lại y hệt là lũy đẳng (không tăng rev)', async () => {
    const { auth } = await login();
    const first: any = await (await push(auth, fixture.records)).json();
    const again: any = await (await push(auth, fixture.records)).json();
    expect(again.results.map((r: any) => r.status)).toEqual(['unchanged', 'unchanged']);
    expect(again.results.map((r: any) => r.rev)).toEqual(first.results.map((r: any) => r.rev));
  });

  it('bản mới của cùng bản ghi nhận rev mới; con trỏ chỉ trả phần thay đổi', async () => {
    const { auth } = await login();
    const id = crypto.randomUUID();
    const a: any = await (await push(auth, [{ id, type: 'wallet', wallet_id: null, sealed: fakeEnvelope() }])).json();
    const cursor = a.results[0].rev;
    const b: any = await (await push(auth, [{ id, type: 'wallet', wallet_id: null, sealed: fakeEnvelope(), deleted: true }])).json();
    expect(b.results[0].status).toBe('applied');
    expect(b.results[0].rev).toBeGreaterThan(cursor);
    const { body } = await pull(auth, `?since=${cursor}`);
    expect(body.records).toHaveLength(1);
    expect(body.records[0].deleted).toBe(true);
  });

  it('từ chối phong bì sai khung, quá lớn, đổi danh tính, trùng trong lô - từng bản ghi, không hỏng cả lô', async () => {
    const { auth } = await login();
    const id = crypto.randomUUID();
    await push(auth, [{ id, type: 'txn', wallet_id: null, sealed: fakeEnvelope() }]);
    const notEnvelope = btoa('x'.repeat(400));
    const short = fakeEnvelope(16);
    const ok = crypto.randomUUID();
    const res: any = await (
      await push(auth, [
        { id: crypto.randomUUID(), type: 'txn', wallet_id: null, sealed: notEnvelope },
        { id: crypto.randomUUID(), type: 'txn', wallet_id: null, sealed: short },
        { id: crypto.randomUUID(), type: 'txn', wallet_id: null, sealed: fakeEnvelope(70 * 1024) },
        { id, type: 'budget', wallet_id: null, sealed: fakeEnvelope() },
        { id: ok, type: 'txn', wallet_id: null, sealed: fakeEnvelope() },
        { id: ok, type: 'txn', wallet_id: null, sealed: fakeEnvelope() },
      ])
    ).json();
    expect(res.results.map((r: any) => r.reason ?? r.status)).toEqual([
      'invalid_envelope',
      'invalid_envelope',
      'too_large',
      'identity_mismatch',
      'applied',
      'duplicate',
    ]);
  });

  it('kiểm lược đồ: id phải UUID chữ thường, loại hợp lệ, lô không rỗng', async () => {
    const { auth } = await login();
    for (const bad of [
      [{ id: 'ABC', type: 'txn', wallet_id: null, sealed: fakeEnvelope() }],
      [{ id: crypto.randomUUID().toUpperCase(), type: 'txn', wallet_id: null, sealed: fakeEnvelope() }],
      [{ id: crypto.randomUUID(), type: 'Txn;DROP', wallet_id: null, sealed: fakeEnvelope() }],
      [],
    ]) {
      expect((await push(auth, bad)).status).toBe(400);
    }
    expect((await call('/api/v1/sync/push', { method: 'POST', headers: { ...auth, 'content-type': 'application/json' }, body: '{' })).status).toBe(400);
  });

  it('cô lập tài khoản: B không kéo được, không ghi đè được bản ghi của A (A01/IDOR)', async () => {
    const a = await login();
    const b = await login();
    const id = crypto.randomUUID();
    const sealedA = fakeEnvelope();
    await push(a.auth, [{ id, type: 'txn', wallet_id: null, sealed: sealedA }]);
    expect((await pull(b.auth)).body.records).toHaveLength(0);
    // B đẩy cùng id: tạo bản ghi riêng trong không gian của B, KHÔNG chạm bản của A.
    await push(b.auth, [{ id, type: 'txn', wallet_id: null, sealed: fakeEnvelope() }]);
    const { body } = await pull(a.auth);
    expect(body.records).toHaveLength(1);
    expect(body.records[0].sealed).toBe(sealedA);
  });

  it('phân trang theo con trỏ, không sót không lặp', async () => {
    const { auth } = await login();
    const ids = Array.from({ length: 7 }, () => crypto.randomUUID());
    await push(auth, ids.map((id) => ({ id, type: 'category', wallet_id: null, sealed: fakeEnvelope() })));
    const got: string[] = [];
    let since = 0;
    for (;;) {
      const { body } = await pull(auth, `?since=${since}&limit=3`);
      got.push(...body.records.map((r: any) => r.id));
      since = body.cursor;
      if (!body.has_more) break;
    }
    expect(got).toEqual(ids);
    expect((await pull(auth, '?limit=9999')).status).toBe(400);
  });

  it('ghi nhận mốc đã kéo của thiết bị (cho dọn bia mộ)', async () => {
    const { auth, body } = await login();
    await pull(auth, '?since=5');
    const row = await env.DB.prepare('SELECT pulled_rev FROM devices WHERE id = ?').bind(body.device_id).first<{ pulled_rev: number }>();
    expect(row!.pulled_rev).toBe(5);
  });

  it('hai lượt đẩy song song không bao giờ trùng rev', async () => {
    const { auth } = await login();
    const batches = Array.from({ length: 4 }, () =>
      Array.from({ length: 5 }, () => ({ id: crypto.randomUUID(), type: 'txn', wallet_id: null, sealed: fakeEnvelope() })),
    );
    const outs = await Promise.all(batches.map(async (b) => ((await (await push(auth, b)).json()) as any).results));
    const revs = outs.flat().map((r: any) => r.rev);
    expect(new Set(revs).size).toBe(revs.length);
  });
});
