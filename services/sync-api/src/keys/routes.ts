import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { z } from 'zod';

import { blockIfDeleting, requireUser } from '../auth/middleware';
import type { AppEnv } from '../env';
import { audit } from '../lib/audit';
import { base64, fromBase64 } from '../lib/crypto';
import { badRequest } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { UUID, isEnvelope } from '../lib/validate';

/**
 * Gói khóa tài khoản và khóa ví đã bọc (ADR-0002). Mọi phần bí mật đã bọc ở máy khách; máy chủ chỉ kiểm khung.
 * Gói khóa CHỈ trả sau khi đăng nhập (ADR-0009 mục 3: giảm dò mật khẩu ngoại tuyến) và có giới hạn tần suất riêng.
 */

const b64 = (min: number, max: number) =>
  z.string().refine((v) => {
    const bytes = fromBase64(v);
    return bytes !== null && bytes.length >= min && bytes.length <= max;
  });

/** Sàn Argon2id - khớp ADR-0007 mục 4 (2 lượt / 19 MiB). Máy chủ cũng từ chối gói khóa tham số yếu. */
const MIN_OPS = 2;
const MIN_MEM = 19 * 1024 * 1024;

/** Khớp `AccountKeyBundle.toJson` của `packages/core` (v1). Trường lạ bị từ chối. */
const accountBundle = z
  .object({
    v: z.literal(1),
    kdf: z
      .object({
        alg: z.literal('argon2id13'),
        salt: b64(16, 16),
        ops: z.number().int().min(MIN_OPS).max(64),
        mem: z.number().int().min(MIN_MEM).max(1024 * 1024 * 1024),
      })
      .strict(),
    mkPw: b64(44, 512),
    mkRc: b64(44, 512),
    kemPk: b64(1216, 1216),
    kemSk: b64(44, 8192),
    boxPk: b64(32, 32),
    boxSk: b64(44, 512),
  })
  .strict();

const walletKeysBody = z.object({
  keys: z
    .array(z.object({ wallet_id: z.string().regex(UUID), wrapped: z.string().max(2048) }).strict())
    .min(1)
    .max(200),
});

export const keysRoutes = new Hono<AppEnv>();

keysRoutes.use('/api/v1/keys/*', requireUser, blockIfDeleting);
keysRoutes.use('/api/v1/keys', requireUser, blockIfDeleting);

keysRoutes.get('/api/v1/keys', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `keys:${userId}`, 30, 60_000);
  const [bundle, wallets] = await Promise.all([
    c.env.DB.prepare('SELECT bundle, updated_at FROM account_bundles WHERE user_id = ?')
      .bind(userId)
      .first<{ bundle: string; updated_at: number }>(),
    c.env.DB.prepare('SELECT wallet_id, wrapped, updated_at FROM wallet_keys WHERE user_id = ? ORDER BY wallet_id')
      .bind(userId)
      .all<{ wallet_id: string; wrapped: ArrayBuffer; updated_at: number }>(),
  ]);
  return c.json({
    account: bundle ? { bundle: JSON.parse(bundle.bundle) as unknown, updated_at: bundle.updated_at } : null,
    wallets: wallets.results.map((w) => ({
      wallet_id: w.wallet_id,
      wrapped: base64(new Uint8Array(w.wrapped)),
      updated_at: w.updated_at,
    })),
  });
});

/**
 * Đặt/thay gói khóa tài khoản (tạo tài khoản mã hóa, đổi mật khẩu = bọc lại khóa chủ).
 * `if_absent: true` (lần thiết lập đầu) ⇒ 409 nếu đã có - hai thiết bị không thể vô tình tạo hai khóa chủ khác nhau.
 */
keysRoutes.put('/api/v1/keys/account', bodyLimit({ maxSize: 32 * 1024 }), async (c) => {
  const { userId, deviceId } = c.get('auth');
  await rateLimit(c.env.DB, `keys-w:${userId}`, 10, 60_000);
  const parsed = z
    .object({ bundle: accountBundle, if_absent: z.boolean().default(false) })
    .strict()
    .safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) throw badRequest('Gói khóa không hợp lệ.');
  const json = JSON.stringify(parsed.data.bundle);
  const t = Date.now();
  if (parsed.data.if_absent) {
    const res = await c.env.DB.prepare(
      'INSERT INTO account_bundles (user_id, bundle, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO NOTHING',
    )
      .bind(userId, json, t)
      .run();
    if (res.meta.changes !== 1) {
      return c.json({ code: 'bundle_exists', message: 'Tài khoản đã có khóa mã hóa. Hãy mở khóa bằng mật khẩu mã hóa.' }, 409);
    }
  } else {
    await c.env.DB.prepare(
      `INSERT INTO account_bundles (user_id, bundle, updated_at) VALUES (?1, ?2, ?3)
       ON CONFLICT(user_id) DO UPDATE SET previous = account_bundles.bundle, bundle = excluded.bundle,
         updated_at = excluded.updated_at
       WHERE account_bundles.bundle <> excluded.bundle`,
    )
      .bind(userId, json, t)
      .run();
  }
  await audit(c, userId, 'account_bundle_set', deviceId);
  return c.json({ updated_at: t });
});

keysRoutes.put('/api/v1/keys/wallets', bodyLimit({ maxSize: 512 * 1024 }), async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `keys-w:${userId}`, 30, 60_000);
  const parsed = walletKeysBody.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) throw badRequest('Khóa ví không hợp lệ.');
  const t = Date.now();
  const stmts: D1PreparedStatement[] = [];
  for (const k of parsed.data.keys) {
    const wrapped = fromBase64(k.wrapped);
    // Khóa 32 B đệm khối 16 ⇒ phong bì ≥ 44 + 48 byte.
    if (!wrapped || !isEnvelope(wrapped, 48) || wrapped.length > 1024) throw badRequest('Khóa ví không hợp lệ.');
    stmts.push(
      c.env.DB.prepare(
        `INSERT INTO wallet_keys (user_id, wallet_id, wrapped, updated_at) VALUES (?, ?, ?, ?)
         ON CONFLICT(user_id, wallet_id) DO UPDATE SET wrapped = excluded.wrapped, updated_at = excluded.updated_at`,
      ).bind(userId, k.wallet_id, wrapped, t),
    );
  }
  const count = await c.env.DB.prepare('SELECT COUNT(*) AS n FROM wallet_keys WHERE user_id = ?')
    .bind(userId)
    .first<{ n: number }>();
  if ((count?.n ?? 0) + stmts.length > 2000) throw badRequest('Quá nhiều ví trong một tài khoản.');
  await c.env.DB.batch(stmts);
  return c.json({ updated_at: t });
});
