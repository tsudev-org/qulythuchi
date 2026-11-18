import { env } from 'cloudflare:workers';
import nacl from 'tweetnacl';
import { beforeAll, describe, expect, it } from 'vitest';

import { cleanup } from '../src/maintenance';
import worker from '../src/index';
import { htmlToText, MAX_PENDING } from '../src/inbox/email';
import { openSealed, sealFor } from '../src/inbox/seal';
import vector from './fixtures/sealed-box-v1.json';
import { call, fixture, json, login } from './helpers';

const DOMAIN = 'in.qulythuchi.tsudev.com';
let keys: nacl.BoxKeyPair;

beforeAll(() => {
  keys = nacl.box.keyPair();
});

const b64 = (u: Uint8Array) => btoa(String.fromCharCode(...u));

/** Đăng nhập + gói khóa có boxPk của cặp khóa test (để mở được thư niêm phong). */
async function account() {
  const a = await login();
  const bundle = { ...fixture.bundle, boxPk: b64(keys.publicKey) };
  const put = await call('/api/v1/keys/account', json({ bundle }, a.auth, 'PUT'));
  expect(put.status).toBeLessThan(300);
  return a;
}

function rawEmail(to: string, body = 'TK 1234 GD: -50,000VND ND: cafe') {
  return [
    'From: Ngan hang <noreply@bank.example>',
    `To: ${to}`,
    'Subject: =?UTF-8?B?' + btoa(String.fromCharCode(...new TextEncoder().encode('Biến động số dư'))) + '?=',
    'Date: Wed, 18 Nov 2026 10:00:00 +0700',
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=utf-8',
    '',
    body,
    '',
  ].join('\r\n');
}

/** Gửi thư giả vào Email Worker; trả lý do từ chối (nếu có). */
async function deliver(to: string, raw = rawEmail(to), rawSize?: number) {
  let rejected: string | null = null;
  const bytes = new TextEncoder().encode(raw);
  const msg = {
    from: 'noreply@bank.example',
    to,
    headers: new Headers(),
    raw: new Response(bytes).body!,
    rawSize: rawSize ?? bytes.length,
    setReject: (r: string) => {
      rejected = r;
    },
    forward: () => Promise.resolve(),
    reply: () => Promise.resolve(),
  } as unknown as ForwardableEmailMessage;
  await worker.email(msg, env);
  return rejected;
}

describe('email chuyển tiếp niêm phong', () => {
  it('tắt mặc định: chưa bật thì không có địa chỉ, thư bị từ chối', async () => {
    const a = await account();
    const box = await call('/api/v1/inbox', { headers: a.auth }).then((r) => r.json<any>());
    expect(box).toEqual({ address: null, items: [] });
    expect(await deliver(`${'0'.repeat(32)}@${DOMAIN}`)).toBe('Unknown recipient');
    expect(await deliver(`abc@${DOMAIN}`)).toBe('Unknown recipient');
  });

  it('bật ⇒ thư được niêm phong bằng boxPk, mở được đúng nội dung, máy chủ không giữ bản rõ', async () => {
    const a = await account();
    const on = await call('/api/v1/inbox/address', json({}, a.auth));
    expect(on.status).toBe(201);
    const { address } = await on.json<{ address: string }>();
    const [local, host] = address.split('@');
    expect(local).toMatch(/^[0-9a-f]{32}$/);
    expect(host).toBe(DOMAIN);
    expect(await deliver(address.toUpperCase())).toBeNull();

    const rows = await env.DB.prepare('SELECT sealed FROM inbound_mail').all<{ sealed: number[] }>();
    for (const r of rows.results) {
      expect(new TextDecoder().decode(new Uint8Array(r.sealed))).not.toContain('cafe');
    }
    const box = await call('/api/v1/inbox', { headers: a.auth }).then((r) => r.json<any>());
    expect(box.items).toHaveLength(1);
    const sealed = Uint8Array.from(atob(box.items[0].sealed), (c) => c.charCodeAt(0));
    const plain = JSON.parse(
      new TextDecoder().decode(openSealed(sealed, keys.publicKey, keys.secretKey)!),
    );
    expect(plain).toMatchObject({ v: 1, from: 'noreply@bank.example', subject: 'Biến động số dư' });
    expect(plain.text).toContain('GD: -50,000VND ND: cafe');

    expect((await call(`/api/v1/inbox/${box.items[0].id}`, { method: 'DELETE', headers: a.auth })).status).toBe(204);
    expect((await call('/api/v1/inbox', { headers: a.auth }).then((r) => r.json<any>())).items).toHaveLength(0);
  });

  it('đổi địa chỉ ⇒ địa chỉ cũ hết hiệu lực; tắt ⇒ xóa thư chờ', async () => {
    const a = await account();
    const first = (await call('/api/v1/inbox/address', json({}, a.auth)).then((r) => r.json<any>())).address;
    expect(await deliver(first)).toBeNull();
    const second = (await call('/api/v1/inbox/address', json({}, a.auth)).then((r) => r.json<any>())).address;
    expect(second).not.toBe(first);
    expect(await deliver(first)).toBe('Unknown recipient');
    expect(await deliver(second)).toBeNull();
    expect((await call('/api/v1/inbox/address', { method: 'DELETE', headers: a.auth })).status).toBe(204);
    const box = await call('/api/v1/inbox', { headers: a.auth }).then((r) => r.json<any>());
    expect(box).toEqual({ address: null, items: [] });
    expect(await deliver(second)).toBe('Unknown recipient');
  });

  it('cần gói khóa trước khi bật; thư quá lớn bị từ chối; B không thấy thư của A', async () => {
    const bare = await login();
    expect((await call('/api/v1/inbox/address', json({}, bare.auth))).status).toBe(409);

    const a = await account();
    const addr = (await call('/api/v1/inbox/address', json({}, a.auth)).then((r) => r.json<any>())).address;
    expect(await deliver(addr, rawEmail(addr), 10 * 1024 * 1024)).toBe('Message too large');
    expect(await deliver(addr)).toBeNull();
    const b = await account();
    const boxB = await call('/api/v1/inbox', { headers: b.auth }).then((r) => r.json<any>());
    expect(boxB.items).toHaveLength(0);
    const idA = (await call('/api/v1/inbox', { headers: a.auth }).then((r) => r.json<any>())).items[0].id;
    await call(`/api/v1/inbox/${idA}`, { method: 'DELETE', headers: b.auth });
    expect((await call('/api/v1/inbox', { headers: a.auth }).then((r) => r.json<any>())).items).toHaveLength(1);
  });

  it('hộp đầy ⇒ từ chối; thư quá 30 ngày bị dọn', async () => {
    const a = await account();
    const addr = (await call('/api/v1/inbox/address', json({}, a.auth)).then((r) => r.json<any>())).address;
    const me = await env.DB.prepare('SELECT user_id FROM inbound_addresses WHERE local_part = ?')
      .bind(addr.split('@')[0])
      .first<{ user_id: string }>();
    const stmts = [];
    for (let i = 0; i < MAX_PENDING; i++) {
      stmts.push(
        env.DB.prepare('INSERT INTO inbound_mail (user_id, id, sealed, size, received_at) VALUES (?, ?, ?, 1, ?)').bind(
          me!.user_id,
          crypto.randomUUID(),
          new Uint8Array([1]),
          Date.now() - 31 * 24 * 3600 * 1000,
        ),
      );
    }
    await env.DB.batch(stmts);
    expect(await deliver(addr)).toBe('Mailbox full');
    await cleanup(env);
    expect(await deliver(addr)).toBeNull();
  });

  it('tương thích libsodium crypto_box_seal (vector sinh bằng libsodium hệ thống)', () => {
    const d = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
    const [pk, sk] = [d(vector.pk), d(vector.sk)];
    // libsodium niêm phong ⇒ cùng cách ghép nonce/box mở được.
    expect(new TextDecoder().decode(openSealed(d(vector.sealed), pk, sk)!)).toBe(vector.message);
    // Worker niêm phong ⇒ mở lại được; mỗi lần khóa tạm khác nhau; sửa 1 byte ⇒ hỏng.
    const msg = new TextEncoder().encode(vector.message);
    const a = sealFor(pk, msg);
    const b = sealFor(pk, msg);
    expect(a.length).toBe(msg.length + 48);
    expect(a).not.toEqual(b);
    expect(new TextDecoder().decode(openSealed(a, pk, sk)!)).toBe(vector.message);
    a.set([a.at(-1)! ^ 1], a.length - 1);
    expect(openSealed(a, pk, sk)).toBeNull();
    expect(() => sealFor(pk.subarray(1), msg)).toThrow();
  });

  it('bóc chữ từ HTML', () => {
    expect(htmlToText('<style>x{}</style><p>Số tiền: <b>50.000</b>&nbsp;đ</p><div>ND: cafe</div>')).toBe(
      'Số tiền: 50.000 đ\nND: cafe',
    );
  });

  it('giải mã thực thể một lượt, không giải mã kép', () => {
    expect(htmlToText('<p>A &amp;lt;b&amp;gt; &lt;i&gt; &#273;&#7891;ng &#0;</p>')).toBe('A &lt;b&gt; <i> đồng');
  });
});
