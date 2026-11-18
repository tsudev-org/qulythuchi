import type { Env } from './env';
import { DELETION_GRACE_MS } from './me/routes';

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
    db.prepare('DELETE FROM audit_log WHERE at < ?').bind(at - 365 * DAY),
    // Email niêm phong app chưa tải về sau 30 ngày (ADR-0006).
    db.prepare('DELETE FROM inbound_mail WHERE received_at < ?').bind(at - 30 * DAY),
  ]);
  await purgeDeletedAccounts(env, at);
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
    for (;;) {
      const page = await env.FILES.list({ prefix: `u/${id}/`, limit: 500 });
      if (page.objects.length) await env.FILES.delete(page.objects.map((o) => o.key));
      if (!page.truncated) break;
    }
    await db.batch([
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
