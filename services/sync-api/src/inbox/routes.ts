import { Hono } from 'hono';

import { blockIfDeleting, requireUser } from '../auth/middleware';
import { requirePro } from '../pro/entitlements';
import type { AppEnv } from '../env';
import { audit } from '../lib/audit';
import { ApiError, badRequest } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { UUID } from '../lib/validate';

/**
 * Hộp thư email chuyển tiếp (ADR-0006, ADR-0012). TẮT mặc định: chỉ có địa chỉ khi người dùng bật (POST address).
 * Mọi mục trong hộp đã niêm phong bằng khóa công khai của người dùng; máy chủ chỉ trả lại bản niêm phong.
 */
export const inboxRoutes = new Hono<AppEnv>();

inboxRoutes.use('/api/v1/inbox', requireUser, blockIfDeleting);
inboxRoutes.use('/api/v1/inbox/*', requireUser, blockIfDeleting);

// D1 trả BLOB dạng mảng số (hoặc ArrayBuffer tùy môi trường).
const toB64 = (bytes: ArrayBuffer | Uint8Array | number[]) => {
  const u = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let s = '';
  for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode(...u.subarray(i, i + 0x8000));
  return btoa(s);
};

function randomLocal(): string {
  const b = crypto.getRandomValues(new Uint8Array(16));
  return [...b].map((x) => x.toString(16).padStart(2, '0')).join('');
}

inboxRoutes.get('/api/v1/inbox', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `inbox-r:${userId}`, 120, 60_000);
  const [addr, items] = await Promise.all([
    c.env.DB.prepare('SELECT local_part FROM inbound_addresses WHERE user_id = ?').bind(userId).first<{ local_part: string }>(),
    c.env.DB
      .prepare('SELECT id, sealed, received_at FROM inbound_mail WHERE user_id = ? ORDER BY received_at LIMIT 50')
      .bind(userId)
      .all<{ id: string; sealed: ArrayBuffer | number[]; received_at: number }>(),
  ]);
  return c.json({
    address: addr ? `${addr.local_part}@${c.env.INBOX_DOMAIN}` : null,
    items: items.results.map((r) => ({ id: r.id, sealed: toB64(r.sealed), received_at: r.received_at })),
  });
});

/** Bật hoặc đổi địa chỉ (địa chỉ cũ hết hiệu lực ngay). Cần gói khóa có boxPk để niêm phong. */
// Email chuyển tiếp là tính năng Pro (ADR-0016).
inboxRoutes.post('/api/v1/inbox/address', requirePro, async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `inbox-w:${userId}`, 10, 3_600_000);
  const bundle = await c.env.DB.prepare('SELECT bundle FROM account_bundles WHERE user_id = ?').bind(userId).first<{ bundle: string }>();
  if (!bundle) throw new ApiError(409, 'no_bundle', 'Hãy thiết lập mã hóa trên tài khoản trước.');
  const local = randomLocal();
  await c.env.DB
    .prepare(
      `INSERT INTO inbound_addresses (user_id, local_part, created_at) VALUES (?1, ?2, ?3)
       ON CONFLICT(user_id) DO UPDATE SET local_part = ?2, created_at = ?3`,
    )
    .bind(userId, local, Date.now())
    .run();
  await audit(c, userId, 'inbox.address');
  return c.json({ address: `${local}@${c.env.INBOX_DOMAIN}` }, 201);
});

/** Tắt: xóa địa chỉ và mọi thư đang chờ. */
inboxRoutes.delete('/api/v1/inbox/address', async (c) => {
  const { userId } = c.get('auth');
  await c.env.DB.batch([
    c.env.DB.prepare('DELETE FROM inbound_addresses WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM inbound_mail WHERE user_id = ?').bind(userId),
  ]);
  await audit(c, userId, 'inbox.disable');
  return c.body(null, 204);
});

/** App đã nhập xong một thư ⇒ xóa khỏi máy chủ. */
inboxRoutes.delete('/api/v1/inbox/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = c.req.param('id');
  if (!UUID.test(id)) throw badRequest('Mã thư không hợp lệ.');
  await rateLimit(c.env.DB, `inbox-w:${userId}`, 600, 3_600_000);
  await c.env.DB.prepare('DELETE FROM inbound_mail WHERE user_id = ? AND id = ?').bind(userId, id).run();
  return c.body(null, 204);
});
