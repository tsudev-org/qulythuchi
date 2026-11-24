import { deleteOwnedWalletFiles, deleteR2Prefix } from './files/routes';
import type { Env } from './env';
import { DELETION_GRACE_MS } from './me/routes';
import { PRO_GRACE_MS, STATUS_MAX_SUBS, enforcing, fetchSubjectStatus, type SubjectStatus } from './pro/entitlements';

const DAY = 24 * 3600 * 1000;
/** Kênh trạng thái chưa xác nhận được (hoặc vừa xác nhận gia hạn) ⇒ không hỏi lại tsudev.com trong 24 giờ. */
const PURGE_RECHECK_MS = DAY;

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
 *
 * Xoá CÓ XÁC MINH (PRODUCT_POLICY 7.4 "Kênh trạng thái", ADR-0018): `pro_until` đệm chỉ dùng để CHỌN ứng viên; ngay
 * trước khi xoá luôn hỏi kênh trạng thái tsudev.com cho đúng các ứng viên đó:
 * - `ok` và `pro_until` + 90 ngày còn ở tương lai (đã gia hạn, ví dụ trên web mà chưa mở app) ⇒ cập nhật hạn đã đệm, GIỮ;
 * - `ok` đã quá 90 ngày (kể cả `pro_until` = 0: chưa từng có Pro mà còn dữ liệu đẩy lúc gate tắt), hoặc `deleted` ⇒ xoá;
 * - `unknown_subject`, kênh lỗi/hết giờ/khung sai/chưa cấu hình ⇒ HOÃN, ghi mốc, không hỏi lại trong 24 giờ.
 * `404 unknown_subject` của kênh RP `GET /{sub}` (grant OIDC quá 30 ngày) KHÔNG bao giờ là lý do xoá.
 */
export async function purgeLapsedPro(env: Env, at = Date.now(), maxUsers = 3) {
  const db = env.DB;
  const due = await db
    .prepare(
      `SELECT u.id, u.oidc_sub FROM users u
         LEFT JOIN entitlements e ON e.user_id = u.id
         LEFT JOIN pro_purge_checks c ON c.user_id = u.id
        WHERE u.oidc_sub NOT LIKE 'deleted:%' AND u.deletion_requested_at IS NULL
          AND (e.user_id IS NULL OR e.pro_until < ?1)
          AND (c.user_id IS NULL OR c.checked_at < ?2)
          AND (EXISTS (SELECT 1 FROM records r WHERE r.user_id = u.id)
            OR EXISTS (SELECT 1 FROM files f WHERE f.user_id = u.id)
            OR EXISTS (SELECT 1 FROM shared_wallets w WHERE w.owner_id = u.id)
            OR EXISTS (SELECT 1 FROM inbound_addresses a WHERE a.user_id = u.id))
        LIMIT ?3`,
    )
    .bind(at - PRO_GRACE_MS, at - PURGE_RECHECK_MS, Math.min(maxUsers, STATUS_MAX_SUBS))
    .all<{ id: string; oidc_sub: string }>();
  if (due.results.length === 0) return;

  const markChecked = (id: string) =>
    db
      .prepare(
        `INSERT INTO pro_purge_checks (user_id, checked_at) VALUES (?1, ?2)
         ON CONFLICT(user_id) DO UPDATE SET checked_at = ?2`,
      )
      .bind(id, at);
  let statuses: Map<string, SubjectStatus>;
  try {
    statuses = await fetchSubjectStatus(env, due.results.map((u) => u.oidc_sub));
  } catch (e) {
    console.warn('pro_purge_deferred', e instanceof Error ? e.message.slice(0, 32) : 'error');
    await db.batch(due.results.map((u) => markChecked(u.id)));
    return;
  }

  const keep: D1PreparedStatement[] = [];
  const purge: { id: string; status: 'ok' | 'deleted' }[] = [];
  for (const u of due.results) {
    const st = statuses.get(u.oidc_sub);
    if (st?.status === 'ok' && st.proUntil + PRO_GRACE_MS > at) {
      // Đã gia hạn mà app chưa hỏi lại: chỉ đổi `pro_until` (không đụng `jws`/`fetched_at` - gate vẫn lấy JWS mới theo
      // nhịp thường). Chưa có đệm ⇒ tạo dòng `fetched_at` = 0 (không bao giờ "còn hạn" nên không cấp Pro từ dòng này).
      keep.push(
        db
          .prepare(
            `INSERT INTO entitlements (user_id, status, pro_until, fetched_at) VALUES (?1, 'unknown_subject', ?2, 0)
             ON CONFLICT(user_id) DO UPDATE SET pro_until = MAX(pro_until, ?2)`,
          )
          .bind(u.id, st.proUntil),
        markChecked(u.id),
      );
    } else if (st?.status === 'deleted' || st?.status === 'ok') {
      purge.push({ id: u.id, status: st.status });
    } else {
      keep.push(markChecked(u.id));
    }
  }
  if (keep.length > 0) await db.batch(keep);

  for (const { id, status } of purge) {
    await deleteR2Prefix(env.FILES, `u/${id}/`);
    await deleteOwnedWalletFiles(env, id);
    await db.batch([
      db.prepare('DELETE FROM shared_wallets WHERE owner_id = ?').bind(id),
      db.prepare('DELETE FROM records WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM files WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM inbound_mail WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM inbound_addresses WHERE user_id = ?').bind(id),
      db.prepare('DELETE FROM pro_purge_checks WHERE user_id = ?').bind(id),
      db
        .prepare("INSERT INTO audit_log (user_id, event, detail, ip_hash, at) VALUES (?, 'pro_data_purged', ?, NULL, ?)")
        .bind(id, `verified:${status}`, at),
    ]);
  }
}
