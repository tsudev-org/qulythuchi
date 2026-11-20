import { Hono, type Context } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { z } from 'zod';

import { blockIfDeleting, requireUser } from '../auth/middleware';
import { assertPro, requirePro } from '../pro/entitlements';
import type { AppEnv } from '../env';
import { audit } from '../lib/audit';
import { base64, fromBase64, sha256Hex } from '../lib/crypto';
import { ApiError, badRequest } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { RECORD_TYPE, UUID, isEnvelope } from '../lib/validate';
import { MAX_BATCH, MAX_RECORD_BYTES } from '../sync/routes';

/**
 * Ví chung gia đình (P9, ADR-0015). Máy chủ chỉ giữ quyền + bản mã:
 * - khóa ví đã bọc cho từng thành viên (chủ ví: bọc bằng khóa chủ; thành viên: X-Wing + bí mật cặp từ mã mời);
 * - lời mời chỉ có nửa công khai (id); bằng chứng nhận lời mời do CHỦ VÍ kiểm trên thiết bị;
 * - không gian bản ghi riêng của ví, rev của ví, phiên bản khóa hiện tại (ghi bằng phiên bản cũ ⇒ `stale_key`).
 */

/** Id dành riêng cho khóa dữ liệu cấp tài khoản (ADR-0011 mục 3) - không bao giờ là ví chung. */
const ACCOUNT_KEY_ID = '00000000-0000-4000-8000-000000000000';
export const MAX_OWNED_SHARED = 20;
export const MAX_MEMBERS = 20;
export const MAX_OPEN_INVITES = 20;
export const MAX_JOINED = 50;
export const INVITE_TTL_MS = 7 * 24 * 3600 * 1000;
/** Lời mời đã được nhận nhưng chủ ví chưa mở app để hoàn tất: giữ tối đa 30 ngày. */
const ACCEPTED_TTL_MS = 30 * 24 * 3600 * 1000;
export const WALLET_RECORD_QUOTA = 50 * 1024 * 1024;
const RECORD_MIN_PADDED = 256;
/** Khóa 32 B đệm khối 16 ⇒ phong bì ≥ 44 + 48. Khối 'QS' = 3 + bản mã X-Wing 1120 + phong bì 92. */
const OWN_WRAP_MIN = 92;
const SHARE_BYTES = 3 + 1120 + 92;
/** Khóa công khai X-Wing (ADR-0007 mục 1). */
const KEM_PK_BYTES = 1216;

type Role = 'owner' | 'editor' | 'viewer';

const wrappedKey = z.string().max(4096);

/** Bản bọc khóa ví hợp lệ về KHUNG: phong bì v1 (bản của chính mình) hoặc khối chia sẻ 'QS' 01. */
function parseWrapped(v: string, kind: 'own' | 'share'): Uint8Array {
  const b = fromBase64(v);
  if (!b) throw badRequest('Khóa ví không hợp lệ.');
  if (kind === 'own') {
    if (!isEnvelope(b, 48) || b.length < OWN_WRAP_MIN || b.length > 1024) throw badRequest('Khóa ví không hợp lệ.');
  } else if (b.length !== SHARE_BYTES || b[0] !== 0x51 || b[1] !== 0x53 || b[2] !== 0x01) {
    throw badRequest('Khóa ví không hợp lệ.');
  }
  return b;
}

interface Membership {
  role: Role;
  key_ver: number;
  owner_id: string;
  rev: number;
}

async function membership(c: Context<AppEnv>, walletId: string): Promise<Membership> {
  if (!UUID.test(walletId)) throw notFound();
  const row = await c.env.DB.prepare(
    `SELECT m.role, w.key_ver, w.owner_id, w.rev FROM wallet_members m JOIN shared_wallets w ON w.id = m.wallet_id
     WHERE m.wallet_id = ? AND m.user_id = ?`,
  )
    .bind(walletId, c.get('auth').userId)
    .first<Membership>();
  // Không phải thành viên ⇒ 404 như ví không tồn tại (không lộ ví của người khác có hay không).
  if (!row) throw notFound();
  return row;
}

async function ownerOnly(c: Context<AppEnv>, walletId: string): Promise<Membership> {
  const m = await membership(c, walletId);
  if (m.role !== 'owner') throw new ApiError(403, 'forbidden', 'Chỉ chủ ví được làm việc này.');
  return m;
}

const notFound = () => new ApiError(404, 'not_found', 'Không tìm thấy ví chung.');

async function json<T>(c: Context<AppEnv>, schema: z.ZodType<T>, message = 'Yêu cầu không hợp lệ.'): Promise<T> {
  const parsed = schema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) throw badRequest(message);
  return parsed.data;
}

const kemPkSql = `json_extract(b.bundle, '$.kemPk')`;
const boxPkSql = `json_extract(b.bundle, '$.boxPk')`;

export const walletRoutes = new Hono<AppEnv>();

walletRoutes.use('/api/v1/wallets', requireUser, blockIfDeleting);
walletRoutes.use('/api/v1/wallets/*', requireUser, blockIfDeleting);
walletRoutes.use('/api/v1/invites/*', requireUser, blockIfDeleting);

// ------------------------------------------------------------------ Tạo ví chung

/**
 * Biến một ví riêng thành ví chung. Khóa ví hiện tại thành phiên bản 1 (không phải mã hóa lại); mọi bản ghi của ví đang
 * nằm trong không gian tài khoản được CHUYỂN sang không gian ví trong cùng một giao tác (rev ví đánh lại từ 1).
 */
// Pro (ADR-0016): tạo ví chung / mời / chia khóa cho người mới cần chủ ví có Pro; tham gia và rời ví luôn miễn phí;
// xoay khóa không chặn (thu hồi quyền đọc của người đã rời quan trọng hơn gói).
walletRoutes.post('/api/v1/wallets', bodyLimit({ maxSize: 16 * 1024 }), requirePro, async (c) => {
  const { userId, deviceId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const body = await json(c, z.object({ wallet_id: z.string().regex(UUID), wrapped: wrappedKey }).strict());
  if (body.wallet_id === ACCOUNT_KEY_ID) throw badRequest();
  const wrapped = parseWrapped(body.wrapped, 'own');
  const db = c.env.DB;
  const [exists, owned, hasBundle] = await db.batch<{ n: number }>([
    db.prepare('SELECT COUNT(*) AS n FROM shared_wallets WHERE id = ?').bind(body.wallet_id),
    db.prepare('SELECT COUNT(*) AS n FROM shared_wallets WHERE owner_id = ?').bind(userId),
    db.prepare('SELECT COUNT(*) AS n FROM account_bundles WHERE user_id = ?').bind(userId),
  ]);
  if ((exists?.results[0]?.n ?? 0) > 0) throw new ApiError(409, 'wallet_exists', 'Ví này đã được chia sẻ.');
  if ((hasBundle?.results[0]?.n ?? 0) === 0) throw new ApiError(409, 'no_keys', 'Hãy đồng bộ khóa mã hóa trước.');
  if ((owned?.results[0]?.n ?? 0) >= MAX_OWNED_SHARED) {
    throw new ApiError(409, 'limit', `Mỗi tài khoản chia sẻ được tối đa ${MAX_OWNED_SHARED} ví.`);
  }
  const t = Date.now();
  await db.batch([
    db
      .prepare('INSERT INTO shared_wallets (id, owner_id, key_ver, rev, created_at, updated_at) VALUES (?, ?, 1, 0, ?, ?)')
      .bind(body.wallet_id, userId, t, t),
    db.prepare("INSERT INTO wallet_members (wallet_id, user_id, role, joined_at) VALUES (?, ?, 'owner', ?)").bind(body.wallet_id, userId, t),
    db
      .prepare('INSERT INTO wallet_key_shares (wallet_id, user_id, key_ver, wrapped, created_at) VALUES (?, ?, 1, ?, ?)')
      .bind(body.wallet_id, userId, wrapped, t),
    db
      .prepare(
        `INSERT INTO wallet_records (wallet_id, id, type, sealed, size, digest, deleted, key_ver, rev, updated_at, author_id, device_id)
         SELECT wallet_id, id, type, sealed, size, digest, deleted, 1, ROW_NUMBER() OVER (ORDER BY rev), updated_at, user_id, device_id
         FROM records WHERE user_id = ? AND wallet_id = ?`,
      )
      .bind(userId, body.wallet_id),
    db
      .prepare('UPDATE shared_wallets SET rev = (SELECT COALESCE(MAX(rev), 0) FROM wallet_records WHERE wallet_id = ?1) WHERE id = ?1')
      .bind(body.wallet_id),
    db.prepare('DELETE FROM records WHERE user_id = ? AND wallet_id = ?').bind(userId, body.wallet_id),
  ]);
  await audit(c, userId, 'wallet_shared', `${body.wallet_id} ${deviceId}`);
  const w = await db.prepare('SELECT rev FROM shared_wallets WHERE id = ?').bind(body.wallet_id).first<{ rev: number }>();
  return c.json({ wallet_id: body.wallet_id, key_ver: 1, rev: w?.rev ?? 0 });
});

// ------------------------------------------------------------------ Danh sách

interface WalletRow {
  wallet_id: string;
  role: Role;
  key_ver: number;
  rev: number;
  needs_rotation: number;
  owner_id: string;
}

walletRoutes.get('/api/v1/wallets', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets:${userId}`, 120, 60_000);
  const db = c.env.DB;
  const [wallets, shares, members, invites, pending] = await db.batch<Record<string, unknown>>([
    db.prepare(
      `SELECT w.id AS wallet_id, m.role, w.key_ver, w.rev, w.needs_rotation, w.owner_id
       FROM wallet_members m JOIN shared_wallets w ON w.id = m.wallet_id WHERE m.user_id = ?1 ORDER BY w.created_at`,
    ).bind(userId),
    db.prepare('SELECT wallet_id, key_ver, wrapped FROM wallet_key_shares WHERE user_id = ? ORDER BY key_ver').bind(userId),
    db.prepare(
      // Huy hiệu (PRODUCT_POLICY 4.1): giá trị SAU `badge_display` từ đệm quyền lợi còn hạn; Pro đã qua `pro_until` ⇒
      // tắt phần Pro (Ủng hộ giữ). Không có đệm còn hạn ⇒ 'none' (không lộ gì thêm về người khác).
      `SELECT m.wallet_id, m.user_id, m.role, m.joined_at, u.display_name, u.email, ${kemPkSql} AS kem_pk, ${boxPkSql} AS box_pk,
         CASE WHEN e.status = 'ok' AND e.jws_exp > ?2 THEN
           CASE WHEN e.pro_until <= ?2 AND e.badge = 'both' THEN 'donor'
                WHEN e.pro_until <= ?2 AND e.badge = 'pro' THEN 'none'
                ELSE e.badge END
         ELSE 'none' END AS badge
       FROM wallet_members m JOIN users u ON u.id = m.user_id LEFT JOIN account_bundles b ON b.user_id = m.user_id
         LEFT JOIN entitlements e ON e.user_id = m.user_id
       WHERE m.wallet_id IN (SELECT wallet_id FROM wallet_members WHERE user_id = ?1) ORDER BY m.joined_at`,
    ).bind(userId, Date.now()),
    // Lời mời: chỉ chủ ví thấy.
    db.prepare(
      `SELECT i.id, i.wallet_id, i.role, i.expires_at, i.accepted_by, i.accepted_at, i.accept_kem_pk, i.accept_proof,
         u.display_name, u.email
       FROM wallet_invites i JOIN shared_wallets w ON w.id = i.wallet_id LEFT JOIN users u ON u.id = i.accepted_by
       WHERE w.owner_id = ?1 AND (i.expires_at > ?2 OR (i.accepted_at IS NOT NULL AND i.accepted_at > ?3))
       ORDER BY i.created_at`,
    ).bind(userId, Date.now(), Date.now() - ACCEPTED_TTL_MS),
    // Lời mời mình đã nhận, chờ chủ ví hoàn tất.
    db.prepare(
      `SELECT i.id, i.wallet_id, i.role, i.accepted_at, o.display_name AS owner_name
       FROM wallet_invites i JOIN shared_wallets w ON w.id = i.wallet_id JOIN users o ON o.id = w.owner_id
       WHERE i.accepted_by = ?1 AND i.accepted_at > ?2`,
    ).bind(userId, Date.now() - ACCEPTED_TTL_MS),
  ]);
  const by = <T extends Record<string, unknown>>(rows: T[] | undefined) => {
    const m = new Map<string, T[]>();
    for (const r of rows ?? []) {
      const k = r.wallet_id as string;
      m.set(k, [...(m.get(k) ?? []), r]);
    }
    return m;
  };
  const sharesBy = by(shares?.results);
  const membersBy = by(members?.results);
  const invitesBy = by(invites?.results);
  const b64 = (v: unknown) =>
    v instanceof ArrayBuffer || ArrayBuffer.isView(v) || Array.isArray(v) ? base64(new Uint8Array(v as ArrayLike<number>)) : null;
  return c.json({
    wallets: ((wallets?.results ?? []) as unknown as WalletRow[]).map((w) => ({
      wallet_id: w.wallet_id,
      role: w.role,
      key_ver: w.key_ver,
      rev: w.rev,
      owner_id: w.owner_id,
      needs_rotation: w.role === 'owner' && w.needs_rotation === 1,
      shares: (sharesBy.get(w.wallet_id) ?? []).map((s) => ({ key_ver: s.key_ver, wrapped: b64(s.wrapped) })),
      members: (membersBy.get(w.wallet_id) ?? []).map((m) => ({
        user_id: m.user_id,
        role: m.role,
        joined_at: m.joined_at,
        display_name: m.display_name ?? null,
        email: m.email ?? null,
        kem_pk: m.kem_pk ?? null,
        box_pk: m.box_pk ?? null,
        badge: m.badge ?? 'none',
      })),
      invites:
        w.role === 'owner'
          ? (invitesBy.get(w.wallet_id) ?? []).map((i) => ({
              invite_id: i.id,
              role: i.role,
              expires_at: i.expires_at,
              accepted:
                i.accepted_by == null
                  ? null
                  : {
                      user_id: i.accepted_by,
                      accepted_at: i.accepted_at,
                      display_name: i.display_name ?? null,
                      email: i.email ?? null,
                      kem_pk: b64(i.accept_kem_pk),
                      proof: b64(i.accept_proof),
                    },
            }))
          : [],
    })),
    pending: (pending?.results ?? []).map((p) => ({
      invite_id: p.id,
      wallet_id: p.wallet_id,
      role: p.role,
      accepted_at: p.accepted_at,
      owner_name: p.owner_name ?? null,
    })),
  });
});

// ------------------------------------------------------------------ Lời mời

walletRoutes.post('/api/v1/wallets/:wid/invites', bodyLimit({ maxSize: 4096 }), async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const wid = c.req.param('wid');
  await ownerOnly(c, wid);
  await assertPro(c, userId);
  const body = await json(c, z.object({ invite_id: z.string().regex(UUID), role: z.enum(['editor', 'viewer']) }).strict());
  const db = c.env.DB;
  const t = Date.now();
  const [open, members] = await db.batch<{ n: number }>([
    db.prepare('SELECT COUNT(*) AS n FROM wallet_invites WHERE wallet_id = ? AND expires_at > ?').bind(wid, t),
    db.prepare('SELECT COUNT(*) AS n FROM wallet_members WHERE wallet_id = ?').bind(wid),
  ]);
  if ((open?.results[0]?.n ?? 0) >= MAX_OPEN_INVITES) throw new ApiError(409, 'limit', 'Ví đang có quá nhiều lời mời chưa dùng.');
  if ((members?.results[0]?.n ?? 0) >= MAX_MEMBERS) {
    throw new ApiError(409, 'limit', `Một ví chung có tối đa ${MAX_MEMBERS} thành viên.`);
  }
  const res = await db
    .prepare(
      'INSERT INTO wallet_invites (id, wallet_id, role, created_at, expires_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT(id) DO NOTHING',
    )
    .bind(body.invite_id, wid, body.role, t, t + INVITE_TTL_MS)
    .run();
  if (res.meta.changes !== 1) throw new ApiError(409, 'invite_exists', 'Lời mời đã tồn tại.');
  await audit(c, userId, 'wallet_invite_created', wid);
  return c.json({ invite_id: body.invite_id, expires_at: t + INVITE_TTL_MS });
});

walletRoutes.delete('/api/v1/wallets/:wid/invites/:iid', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const wid = c.req.param('wid');
  await ownerOnly(c, wid);
  await c.env.DB.prepare('DELETE FROM wallet_invites WHERE id = ? AND wallet_id = ?').bind(c.req.param('iid'), wid).run();
  return c.json({ ok: true });
});

walletRoutes.get('/api/v1/invites/:iid', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `invite:${userId}`, 20, 60_000);
  const iid = c.req.param('iid');
  if (!UUID.test(iid)) throw inviteGone();
  const row = await c.env.DB.prepare(
    `SELECT i.wallet_id, i.role, i.expires_at, i.accepted_by, w.owner_id, o.display_name AS owner_name
     FROM wallet_invites i JOIN shared_wallets w ON w.id = i.wallet_id JOIN users o ON o.id = w.owner_id WHERE i.id = ?`,
  )
    .bind(iid)
    .first<{ wallet_id: string; role: Role; expires_at: number; accepted_by: string | null; owner_id: string; owner_name: string | null }>();
  if (!row || (row.expires_at <= Date.now() && row.accepted_by !== userId)) throw inviteGone();
  return c.json({
    invite_id: iid,
    wallet_id: row.wallet_id,
    role: row.role,
    expires_at: row.expires_at,
    owner_name: row.owner_name,
    state: row.owner_id === userId ? 'own' : row.accepted_by === null ? 'open' : row.accepted_by === userId ? 'accepted' : 'taken',
  });
});

const inviteGone = () => new ApiError(404, 'invite_gone', 'Lời mời không tồn tại hoặc đã hết hạn.');

/**
 * Nhận lời mời. Khóa công khai X-Wing lấy từ gói khóa ĐÃ ĐĂNG KÝ của người nhận (không nhận từ thân yêu cầu) và bằng
 * chứng là BLAKE2b có khóa = bí mật lời mời trên khóa đó. Máy chủ không kiểm được bằng chứng (không có bí mật) - chủ ví
 * kiểm trên thiết bị trước khi chia khóa.
 */
walletRoutes.post('/api/v1/invites/:iid/accept', bodyLimit({ maxSize: 4096 }), async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `invite:${userId}`, 20, 60_000);
  const iid = c.req.param('iid');
  if (!UUID.test(iid)) throw inviteGone();
  const body = await json(c, z.object({ proof: z.string().max(64) }).strict());
  const proof = fromBase64(body.proof);
  if (!proof || proof.length !== 32) throw badRequest();
  const db = c.env.DB;
  const row = await db
    .prepare(
      `SELECT i.wallet_id, i.expires_at, i.accepted_by, w.owner_id,
         (SELECT COUNT(*) FROM wallet_members m WHERE m.wallet_id = i.wallet_id AND m.user_id = ?2) AS member,
         (SELECT COUNT(*) FROM wallet_members m WHERE m.user_id = ?2) AS joined
       FROM wallet_invites i JOIN shared_wallets w ON w.id = i.wallet_id WHERE i.id = ?1`,
    )
    .bind(iid, userId)
    .first<{ wallet_id: string; expires_at: number; accepted_by: string | null; owner_id: string; member: number; joined: number }>();
  if (!row || row.expires_at <= Date.now()) throw inviteGone();
  if (row.owner_id === userId || row.member > 0) throw new ApiError(409, 'already_member', 'Bạn đã ở trong ví này.');
  if (row.accepted_by !== null && row.accepted_by !== userId) {
    throw new ApiError(409, 'invite_taken', 'Lời mời này đã được người khác dùng. Hãy xin chủ ví mã mới.');
  }
  if (row.joined >= MAX_JOINED) throw new ApiError(409, 'limit', `Mỗi tài khoản tham gia tối đa ${MAX_JOINED} ví chung.`);
  const bundle = await db.prepare(`SELECT ${kemPkSql} AS kem_pk FROM account_bundles b WHERE b.user_id = ?`).bind(userId).first<{ kem_pk: string | null }>();
  const kemPk = bundle?.kem_pk ? fromBase64(bundle.kem_pk) : null;
  if (!kemPk || kemPk.length !== KEM_PK_BYTES) throw new ApiError(409, 'no_keys', 'Hãy đồng bộ khóa mã hóa trước.');
  // Điều kiện accepted_by trong WHERE: hai người nhận cùng lúc ⇒ chỉ một người thắng.
  const res = await db
    .prepare(
      `UPDATE wallet_invites SET accepted_by = ?2, accepted_at = ?3, accept_kem_pk = ?4, accept_proof = ?5
       WHERE id = ?1 AND (accepted_by IS NULL OR accepted_by = ?2)`,
    )
    .bind(iid, userId, Date.now(), kemPk, proof)
    .run();
  if (res.meta.changes !== 1) throw new ApiError(409, 'invite_taken', 'Lời mời này đã được người khác dùng. Hãy xin chủ ví mã mới.');
  await audit(c, userId, 'wallet_invite_accepted', row.wallet_id);
  return c.json({ wallet_id: row.wallet_id, state: 'accepted' });
});

// ------------------------------------------------------------------ Thành viên

/** Chủ ví hoàn tất lời mời đã kiểm bằng chứng: thêm thành viên + khối chia sẻ khóa phiên bản hiện tại. */
walletRoutes.post('/api/v1/wallets/:wid/members', bodyLimit({ maxSize: 16 * 1024 }), async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const wid = c.req.param('wid');
  const m = await ownerOnly(c, wid);
  await assertPro(c, userId);
  const body = await json(c, z.object({ invite_id: z.string().regex(UUID), key_ver: z.number().int(), wrapped: wrappedKey }).strict());
  if (body.key_ver !== m.key_ver) throw staleKey();
  const wrapped = parseWrapped(body.wrapped, 'share');
  const db = c.env.DB;
  const inv = await db
    .prepare('SELECT role, accepted_by, accepted_at FROM wallet_invites WHERE id = ? AND wallet_id = ?')
    .bind(body.invite_id, wid)
    .first<{ role: Role; accepted_by: string | null; accepted_at: number | null }>();
  if (!inv?.accepted_by || (inv.accepted_at ?? 0) < Date.now() - ACCEPTED_TTL_MS) throw inviteGone();
  const count = await db.prepare('SELECT COUNT(*) AS n FROM wallet_members WHERE wallet_id = ?').bind(wid).first<{ n: number }>();
  if ((count?.n ?? 0) >= MAX_MEMBERS) throw new ApiError(409, 'limit', `Một ví chung có tối đa ${MAX_MEMBERS} thành viên.`);
  const t = Date.now();
  await db.batch([
    db
      .prepare('INSERT INTO wallet_members (wallet_id, user_id, role, joined_at) VALUES (?, ?, ?, ?) ON CONFLICT DO NOTHING')
      .bind(wid, inv.accepted_by, inv.role, t),
    db
      .prepare(
        `INSERT INTO wallet_key_shares (wallet_id, user_id, key_ver, wrapped, created_at) VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(wallet_id, user_id, key_ver) DO UPDATE SET wrapped = excluded.wrapped`,
      )
      .bind(wid, inv.accepted_by, m.key_ver, wrapped, t),
    db.prepare('DELETE FROM wallet_invites WHERE id = ?').bind(body.invite_id),
  ]);
  await audit(c, userId, 'wallet_member_added', wid);
  return c.json({ user_id: inv.accepted_by, role: inv.role });
});

walletRoutes.put('/api/v1/wallets/:wid/members/:uid', bodyLimit({ maxSize: 1024 }), async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const wid = c.req.param('wid');
  await ownerOnly(c, wid);
  const body = await json(c, z.object({ role: z.enum(['editor', 'viewer']) }).strict());
  const res = await c.env.DB.prepare("UPDATE wallet_members SET role = ? WHERE wallet_id = ? AND user_id = ? AND role <> 'owner'")
    .bind(body.role, wid, c.req.param('uid'))
    .run();
  if (res.meta.changes !== 1) throw new ApiError(404, 'not_found', 'Không tìm thấy thành viên.');
  await audit(c, userId, 'wallet_role_changed', wid);
  return c.json({ role: body.role });
});

/** Thành viên tự rời ví. Mất quyền ngay; chủ ví được báo `needs_rotation` để xoay khóa ở lần đồng bộ sau. */
walletRoutes.delete('/api/v1/wallets/:wid/members/me', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const wid = c.req.param('wid');
  const m = await membership(c, wid);
  if (m.role === 'owner') throw new ApiError(409, 'owner_cannot_leave', 'Chủ ví không rời ví được. Hãy thu hồi các thành viên.');
  const db = c.env.DB;
  await db.batch([
    db.prepare('DELETE FROM wallet_members WHERE wallet_id = ? AND user_id = ?').bind(wid, userId),
    db.prepare('DELETE FROM wallet_key_shares WHERE wallet_id = ? AND user_id = ?').bind(wid, userId),
    db.prepare('UPDATE shared_wallets SET needs_rotation = 1, updated_at = ? WHERE id = ?').bind(Date.now(), wid),
  ]);
  await audit(c, userId, 'wallet_left', wid);
  return c.json({ ok: true });
});

const rotateBody = z
  .object({
    key_ver: z.number().int().min(2),
    remove: z.array(z.string().regex(UUID)).max(MAX_MEMBERS).default([]),
    shares: z.array(z.object({ user_id: z.string().regex(UUID), wrapped: wrappedKey }).strict()).min(1).max(MAX_MEMBERS),
  })
  .strict();

/**
 * Xoay khóa ví (thu hồi thành viên, hoặc sau khi có người rời). Trong MỘT giao tác: xóa thành viên bị thu hồi cùng mọi
 * khối khóa của họ, ghi khóa phiên bản mới cho ĐÚNG tập thành viên còn lại, nâng `key_ver`. Từ đây mọi lượt ghi bằng
 * phiên bản cũ bị từ chối (`stale_key`); thiết bị chủ ví mã hóa lại bản ghi cũ và đẩy lên.
 */
walletRoutes.post('/api/v1/wallets/:wid/rotate', bodyLimit({ maxSize: 64 * 1024 }), async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `wallets-w:${userId}`, 30, 60_000);
  const wid = c.req.param('wid');
  const m = await ownerOnly(c, wid);
  const body = await json(c, rotateBody);
  if (body.key_ver !== m.key_ver + 1) throw staleKey();
  if (body.remove.includes(userId)) throw badRequest('Chủ ví không tự thu hồi mình được.');
  const db = c.env.DB;
  const members = await db.prepare('SELECT user_id FROM wallet_members WHERE wallet_id = ?').bind(wid).all<{ user_id: string }>();
  const remaining = new Set(members.results.map((r) => r.user_id).filter((u) => !body.remove.includes(u)));
  const given = new Set(body.shares.map((s) => s.user_id));
  // Phải có khóa mới cho ĐÚNG những người còn lại: thiếu ⇒ có người mất quyền đọc; thừa ⇒ có người bị thu hồi vẫn nhận khóa.
  if (given.size !== body.shares.length || given.size !== remaining.size || [...remaining].some((u) => !given.has(u))) {
    throw new ApiError(409, 'members_changed', 'Danh sách thành viên đã thay đổi. Hãy đồng bộ rồi thử lại.');
  }
  const t = Date.now();
  const stmts: D1PreparedStatement[] = [];
  for (const u of body.remove) {
    stmts.push(
      db.prepare("DELETE FROM wallet_members WHERE wallet_id = ? AND user_id = ? AND role <> 'owner'").bind(wid, u),
      db.prepare('DELETE FROM wallet_key_shares WHERE wallet_id = ? AND user_id = ?').bind(wid, u),
      db.prepare('DELETE FROM wallet_invites WHERE wallet_id = ? AND accepted_by = ?').bind(wid, u),
    );
  }
  for (const s of body.shares) {
    const wrapped = parseWrapped(s.wrapped, s.user_id === userId ? 'own' : 'share');
    // INSERT thường (không upsert): hai thiết bị chủ ví xoay cùng lúc ⇒ lượt sau vấp khóa chính, cả giao tác hủy.
    stmts.push(
      db
        .prepare('INSERT INTO wallet_key_shares (wallet_id, user_id, key_ver, wrapped, created_at) VALUES (?, ?, ?, ?, ?)')
        .bind(wid, s.user_id, body.key_ver, wrapped, t),
    );
  }
  stmts.push(
    db
      .prepare('UPDATE shared_wallets SET key_ver = ?, needs_rotation = 0, updated_at = ? WHERE id = ? AND key_ver = ?')
      .bind(body.key_ver, t, wid, m.key_ver),
  );
  try {
    await db.batch(stmts);
  } catch {
    throw staleKey();
  }
  await audit(c, userId, body.remove.length ? 'wallet_member_removed' : 'wallet_key_rotated', wid);
  return c.json({ key_ver: body.key_ver });
});

const staleKey = () => new ApiError(409, 'stale_key', 'Khóa ví đã đổi. Hãy đồng bộ lại.');

// ------------------------------------------------------------------ Đồng bộ trong không gian ví

const pushBody = z
  .object({
    key_ver: z.number().int().min(1),
    records: z
      .array(
        z.object({
          id: z.string().regex(UUID),
          type: z.string().regex(RECORD_TYPE),
          sealed: z.string().max(MAX_RECORD_BYTES * 3),
          deleted: z.boolean().default(false),
        }),
      )
      .min(1)
      .max(MAX_BATCH),
  })
  .strict();

type WalletPushResult =
  | { id: string; status: 'applied' | 'unchanged'; rev: number }
  | { id: string; status: 'rejected'; reason: 'invalid_envelope' | 'too_large' | 'identity_mismatch' | 'duplicate' | 'quota' | 'forbidden' };

walletRoutes.post('/api/v1/wallets/:wid/push', bodyLimit({ maxSize: 4 * 1024 * 1024 }), async (c) => {
  const { userId, deviceId } = c.get('auth');
  await rateLimit(c.env.DB, `push:${userId}`, 120, 60_000);
  const wid = c.req.param('wid');
  const m = await membership(c, wid);
  if (m.role === 'viewer') throw new ApiError(403, 'read_only', 'Bạn chỉ có quyền xem ví này.');
  // Ví chung chạy bằng Pro của CHỦ ví (một người Pro dùng được cho cả nhà - ADR-0016 Q5).
  await assertPro(c, m.owner_id, 'owner_no_pro');
  const body = await json(c, pushBody, 'Gói đồng bộ không hợp lệ.');
  if (body.key_ver !== m.key_ver) throw staleKey();
  const db = c.env.DB;
  const ids = body.records.map((r) => r.id);
  const existing = new Map<string, { type: string; digest: string; rev: number; size: number }>();
  for (let i = 0; i < ids.length; i += 90) {
    const chunk = ids.slice(i, i + 90);
    const rows = await db
      .prepare(`SELECT id, type, digest, rev, size FROM wallet_records WHERE wallet_id = ? AND id IN (${chunk.map(() => '?').join(',')})`)
      .bind(wid, ...chunk)
      .all<{ id: string; type: string; digest: string; rev: number; size: number }>();
    for (const r of rows.results) existing.set(r.id, r);
  }
  const usage = await db.prepare('SELECT COALESCE(SUM(size), 0) AS bytes FROM wallet_records WHERE wallet_id = ?').bind(wid).first<{ bytes: number }>();
  let bytes = usage?.bytes ?? 0;
  const results: WalletPushResult[] = [];
  const writes: D1PreparedStatement[] = [];
  const pending: { index: number; id: string }[] = [];
  const seen = new Set<string>();
  const t = Date.now();
  for (const r of body.records) {
    if (seen.has(r.id)) {
      results.push({ id: r.id, status: 'rejected', reason: 'duplicate' });
      continue;
    }
    seen.add(r.id);
    // Thông tin ví (tên, loại, tiền tệ) chỉ chủ ví sửa/xóa được.
    if (r.type === 'wallet' && (m.role !== 'owner' || r.id !== wid)) {
      results.push({ id: r.id, status: 'rejected', reason: 'forbidden' });
      continue;
    }
    const sealed = fromBase64(r.sealed);
    if (!sealed || !isEnvelope(sealed, RECORD_MIN_PADDED)) {
      results.push({ id: r.id, status: 'rejected', reason: 'invalid_envelope' });
      continue;
    }
    if (sealed.length > MAX_RECORD_BYTES) {
      results.push({ id: r.id, status: 'rejected', reason: 'too_large' });
      continue;
    }
    const prev = existing.get(r.id);
    if (prev && prev.type !== r.type) {
      results.push({ id: r.id, status: 'rejected', reason: 'identity_mismatch' });
      continue;
    }
    const digest = await sha256Hex(sealed);
    if (prev?.digest === digest) {
      results.push({ id: r.id, status: 'unchanged', rev: prev.rev });
      continue;
    }
    const nextBytes = bytes - (prev?.size ?? 0) + sealed.length;
    if (nextBytes > WALLET_RECORD_QUOTA) {
      results.push({ id: r.id, status: 'rejected', reason: 'quota' });
      continue;
    }
    bytes = nextBytes;
    writes.push(
      db.prepare('UPDATE shared_wallets SET rev = rev + 1 WHERE id = ?').bind(wid),
      db
        .prepare(
          `INSERT INTO wallet_records (wallet_id, id, type, sealed, size, digest, deleted, key_ver, rev, updated_at, author_id, device_id)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, (SELECT rev FROM shared_wallets WHERE id = ?1), ?9, ?10, ?11)
           ON CONFLICT(wallet_id, id) DO UPDATE SET sealed = excluded.sealed, size = excluded.size, digest = excluded.digest,
             deleted = excluded.deleted, key_ver = excluded.key_ver, rev = excluded.rev, updated_at = excluded.updated_at,
             author_id = excluded.author_id, device_id = excluded.device_id
           RETURNING rev`,
        )
        .bind(wid, r.id, r.type, sealed, sealed.length, digest, r.deleted ? 1 : 0, m.key_ver, t, userId, deviceId),
    );
    pending.push({ index: results.length, id: r.id });
    results.push({ id: r.id, status: 'applied', rev: 0 });
  }
  if (writes.length) {
    // Xoay khóa xen giữa lúc kiểm và lúc ghi ⇒ bản ghi mang key_ver cũ: thiết bị có quyền ghi tự mã hóa lại bản ghi có
    // key_ver < hiện tại ở lần đồng bộ sau (ADR-0015 mục 5), nên không cần khóa cả ví.
    const out = await db.batch<{ rev: number }>(writes);
    pending.forEach((p, k) => {
      const rev = out[k * 2 + 1]?.results[0]?.rev;
      if (rev === undefined) throw new ApiError(500, 'internal', 'Máy chủ gặp lỗi. Hãy thử lại sau.');
      results[p.index] = { id: p.id, status: 'applied', rev };
    });
  }
  return c.json({ results });
});

const pullQuery = z.object({
  since: z.coerce.number().int().min(0).default(0),
  limit: z.coerce.number().int().min(1).max(500).default(200),
});

walletRoutes.get('/api/v1/wallets/:wid/pull', async (c) => {
  const { userId } = c.get('auth');
  await rateLimit(c.env.DB, `pull:${userId}`, 240, 60_000);
  const wid = c.req.param('wid');
  const m = await membership(c, wid);
  const q = pullQuery.safeParse(c.req.query());
  if (!q.success) throw badRequest('Tham số không hợp lệ.');
  const { since, limit } = q.data;
  const rows = await c.env.DB.prepare(
    'SELECT id, type, sealed, deleted, key_ver, rev FROM wallet_records WHERE wallet_id = ? AND rev > ? ORDER BY rev LIMIT ?',
  )
    .bind(wid, since, limit + 1)
    .all<{ id: string; type: string; sealed: ArrayBuffer; deleted: number; key_ver: number; rev: number }>();
  const page = rows.results.slice(0, limit);
  return c.json({
    key_ver: m.key_ver,
    records: page.map((r) => ({
      id: r.id,
      type: r.type,
      wallet_id: wid,
      sealed: base64(new Uint8Array(r.sealed)),
      deleted: r.deleted === 1,
      key_ver: r.key_ver,
      rev: r.rev,
    })),
    cursor: page.at(-1)?.rev ?? since,
    has_more: rows.results.length > limit,
  });
});
