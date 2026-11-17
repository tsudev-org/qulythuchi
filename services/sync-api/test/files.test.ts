import { describe, expect, it } from 'vitest';

import { call, login } from './helpers';

function sealedFile(padded = 4096): Uint8Array {
  const bytes = new Uint8Array(4 + 24 + padded + 16);
  for (let i = 0; i < bytes.length; i += 65536) crypto.getRandomValues(bytes.subarray(i, i + 65536));
  bytes.set([0x51, 0x54, 0x01, 0x01], 0);
  return bytes;
}

const upload = (auth: Record<string, string>, id: string, body: Uint8Array) =>
  call(`/api/v1/files/${id}`, { method: 'PUT', headers: { ...auth, 'Content-Length': String(body.length) }, body });

describe('tệp đính kèm mã hóa (R2)', () => {
  it('tải lên, tải về đúng byte, xóa', async () => {
    const { auth } = await login();
    const id = crypto.randomUUID();
    const data = sealedFile();
    const up = await upload(auth, id, data);
    expect(up.status).toBe(201);
    expect(((await upload(auth, id, data).then((r) => r.json())) as any).status).toBe('unchanged');
    const down = await call(`/api/v1/files/${id}`, { headers: auth });
    expect(down.status).toBe(200);
    expect(down.headers.get('Content-Type')).toBe('application/octet-stream');
    expect(new Uint8Array(await down.arrayBuffer())).toEqual(data);
    expect((await call(`/api/v1/files/${id}`, { method: 'DELETE', headers: auth })).status).toBe(204);
    expect((await call(`/api/v1/files/${id}`, { headers: auth })).status).toBe(404);
  });

  it('từ chối tệp không phải phong bì, quá nhỏ, id sai', async () => {
    const { auth } = await login();
    const plain = new TextEncoder().encode('x'.repeat(5000));
    expect((await upload(auth, crypto.randomUUID(), plain)).status).toBe(400);
    expect((await upload(auth, crypto.randomUUID(), sealedFile(16))).status).toBe(400);
    expect((await upload(auth, 'khong-phai-uuid', sealedFile())).status).toBe(400);
  });

  it('B không đọc/xóa được tệp của A', async () => {
    const a = await login();
    const b = await login();
    const id = crypto.randomUUID();
    await upload(a.auth, id, sealedFile());
    expect((await call(`/api/v1/files/${id}`, { headers: b.auth })).status).toBe(404);
    await call(`/api/v1/files/${id}`, { method: 'DELETE', headers: b.auth });
    expect((await call(`/api/v1/files/${id}`, { headers: a.auth })).status).toBe(200);
  });

  it('khai báo quá 10 MB bị chặn 413 trước khi đọc thân', async () => {
    const { auth } = await login();
    const res = await call(`/api/v1/files/${crypto.randomUUID()}`, {
      method: 'PUT',
      headers: { ...auth, 'Content-Length': String(11 * 1024 * 1024) },
      body: sealedFile(),
    });
    expect([411, 413]).toContain(res.status);
  });
});
