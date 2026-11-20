import { deleteOwnedWalletFiles, deleteR2Prefix } from './files/routes';
import type { Env } from './env';
import { DELETION_GRACE_MS } from './me/routes';
import { PRO_GRACE_MS, enforcing, getEntitlement, isPro } from './pro/entitlements';

const DAY = 24 * 3600 * 1000;

/**
 * Dọn dữ liệu hết hạn. KHÔNG dùng cron (tài khoản Cloudflare đã hết 5 cron gói Free - đo ở sound-db 17/11/2026):
 * chạy kèm ~1% yêu cầu /api bằng waitUntil, không chặn phản hồi.
 */
export async function cleanup(env: Env, at = Date.now()) {
  const db = env.DB;
  await db.batch([
    db.prepare('DELETE FROM login_requests WHERE expires_at < ?').bind(at),
    db.prepare('DELETE FROM app_codes WHERE expires_at < ?').bind(at - DAY),
    db.prepare('DELETE FROM refresh_tokens WHERE expires_at < ? OR (used_at IS NOT NULL AND used_at < ?)').bind(at, at - 30 * DAY),
    db.prepare('DELETE FROM web_sessions WHERE expires_at < ?').bind(at),
    db.prepare('DELETE FROM rate_limits WHERE window_start < ?').bind(at - DAY),
    // Bia mộ (ADR-0004): quá 90 ngày VÀ mọi thiết bị còn hiệu lực đã kéo qua nó. Không còn thiết bị ⇒ MIN = NULL ⇒ giữ.
    db
      .prepare(
        `DELETE FROM records WHERE deleted = 1 AND updated_at < ?1 AND rev <=
           (SELECT MIN(d.pulled_rev) FROM devices d WHERE d.user_id = records.user_id AND d.revoked_at IS NULL)`,
      )
      .bind(at - 90 * DAY),
    db.prepare('DELETE FROM devices WHERE revoked_at IS NOT NULL AND revoked_at < ?').bind(at - 90 * DAY),
    // Lời mời ví chung hết hạn mà không ai nhận, hoặc đã nhận nhưng chủ ví bỏ quá 30 ngày.
    db
      .prepare('DELETE FROM wallet_invites WHERE (accepted_at IS NULL AND expires_at < ?) OR accepted_at < ?')
      .bind(at, at - 30 * DAY),
    db.prepare('DELETE FROM audit_log WHERE at < ?').bind(at - 365 * DAY),
    // Email niêm phong app chưa tải về sau 30 ngày (ADR-0006).
    db.prepare('DELETE FROM inbound_mail WHERE received_at < ?').bind(at - 30 * DAY),
  ]);
  await purgeDeletedAccounts(env, at);
  if (enforcing(env)) await purgeLapsedPro(env, at);
}

/**
 * Hết ân hạn 30 ngày ⇒ xóa hẳn bản mã, khóa đã bọc, tệp R2, thiết bị; dòng users được ẩn danh hóa (giữ id cho nhật ký
 * kiểm toán; oidc_sub đổi để lần đăng nhập sau với cùng danh tính tsudev tạo tài khoản MỚI, trống).
 */
export async function purgeDeletedAccounts(env: Env, at = Date.now(), maxUsers = 5) {
  const db = env.DB;
  const due = await db
    .prepare(
      `SELECT id FROM users WHERE deletion_requested_at IS NOT NULL AND deletion_requested_at < ?
       AND oidc_sub NOT LIKE 'deleted:%' LIMIT ?`,
    )
    .bind(at - DELETION_GRACE_MS, maxUsers)
    .all<{ id: string }>();
  for (const { id } of due.results) {
    await deleteR2Prefix(env.FILES, `u/${id}/`);
    await deleteOwnedWalletFiles(env, id);
    await db.batch([
      // Ví chung (ADR-0015): ví mình làm chủ bị xóa cùng bản ghi/lời mời/thành viên (FK CASCADE khi xóa shared_wallets);
      // ví mình là thành viên: rời ví, báo chủ ví xoay khóa.
      db
        .prepare(
          `UPDATE shared_wallets SET needs_rotation = 1, updated_at = ?2 WHERE owner_id <> ?1
           AND id IN (SELECT wallet_id FROM wallet_members WHERE user_id = ?1)`,
        )
        .bind(id, at),
      db.prepare('DELETE FROM shared_wallets WHERE owner_id = ?').bind(id),
      db.prepare('DELETE FROM wallet_members WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM wallet_key_shares WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM wallet_invites WHERE accepted_by = ?').bind(id),
      db.prepare('DELETE FROM records WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM wallet_keys WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM account_bundles WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM files WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM inbound_mail WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM inbound_addresses WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM devices WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM app_codes WHERE user_id = ?').bind(id),
      db
        .prepare(
          `UPDATE users SET oidc_sub = 'deleted:' || id, email = NULL, email_verified = 0, display_name = NULL,
             avatar_url = NULL WHERE id = ?`,
        )
        .bind(id),
      db.prepare("INSERT INTO audit_log (user_id, event, detail, ip_hash, at) VALUES (?, 'account_purged', NULL, NULL, ?)").bind(id, at),
    ]);
  }
}

/**
 * Pro hết hạn quá 90 ngày (PRODUCT_POLICY 7.2, ADR-0016) ⇒ xoá BẢN MÃ trên máy chủ: bản ghi cá nhân, tệp R2, ví chung
 * mình làm chủ (kèm bản ghi/thành viên/lời mời - FK CASCADE), hộp thư email. Giữ tài khoản, thiết bị, gói khóa đã bọc
 * (vài KB, cần khi mua lại Pro hoặc làm thành viên ví người khác). Dữ liệu trên thiết bị không bị đụng tới.
 * Trước khi xoá luôn hỏi lại tsudev.com nếu đệm đã quá 1 ngày (có thể vừa gia hạn); hỏi lỗi ⇒ để lượt sau.
 * Tài khoản chưa từng có Pro mà còn dữ liệu (đẩy lên lúc gate còn tắt) ⇒ `pro_until` = 0 ⇒ xoá luôn.
 */
export async function purgeLapsedPro(env: Env, at = Date.now(), maxUsers = 3) {
  const db = env.DB;
  const due = await db
    .prepare(
      `SELECT u.id, u.last_login_at, e.status, e.pro_until, e.fetched_at FROM users u
         LEFT JOIN entitlements e ON e.user_id = u.id
        WHERE u.oidc_sub NOT LIKE 'deleted:%' AND u.deletion_requested_at IS NULL
          AND (e.user_id IS NULL OR e.pro_until < ?1)
          AND (EXISTS (SELECT 1 FROM records r WHERE r.user_id = u.id)
            OR EXISTS (SELECT 1 FROM files f WHERE f.user_id = u.id)
            OR EXISTS (SELECT 1 FROM shared_wallets w WHERE w.owner_id = u.id)
            OR EXISTS (SELECT 1 FROM inbound_addresses a WHERE a.user_id = u.id))
        LIMIT ?2`,
    )
    .bind(at - PRO_GRACE_MS, maxUsers)
    .all<{ id: string; last_login_at: number; status: string | null; pro_until: number | null; fetched_at: number | null }>();
  for (const u of due.results) {
    let e;
    try {
      e = u.status !== null && (u.fetched_at ?? 0) > at - DAY ? null : await getEntitlement(env, u.id, {}, { force: true });
    } catch {
      continue;
    }
    const status = e ? e.status : u.status;
    const proUntil = e ? e.proUntil : (u.pro_until ?? 0);
    if (e && isPro(e, at)) continue;
    if (proUntil + PRO_GRACE_MS >= at) continue;
    // tsudev.com không trả quyền lợi (Grant hết hạn) ⇒ chỉ xoá khi người dùng cũng bỏ app quá ân hạn.
    if (status === 'unknown_subject' && u.last_login_at > at - PRO_GRACE_MS) continue;
    await deleteR2Prefix(env.FILES, `u/${u.id}/`);
    await deleteOwnedWalletFiles(env, u.id);
    await db.batch([
      db.prepare('DELETE FROM shared_wallets WHERE owner_id = ?').bind(u.id),
      db.prepare('DELETE FROM records WHERE user_id = ?').bind(u.id),
      db.prepare('DELETE FROM files WHERE user_id = ?').bind(u.id),
      db.prepare('DELETE FROM inbound_mail WHERE user_id = ?').bind(u.id),
      db.prepare('DELETE FROM inbound_addresses WHERE user_id = ?').bind(u.id),
      db.prepare("INSERT INTO audit_log (user_id, event, detail, ip_hash, at) VALUES (?, 'pro_data_purged', NULL, NULL, ?)").bind(u.id, at),
    ]);
  }
}
