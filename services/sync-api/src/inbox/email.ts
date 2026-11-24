import PostalMime from 'postal-mime';

import type { Env } from '../env';
import { cachedEntitlement, enforcing, isPro } from '../pro/entitlements';
import { sealFor } from './seal';

/** Email thô tối đa nhận (chủ yếu là thông báo giao dịch, không cần tệp đính kèm lớn). */
const MAX_RAW_EMAIL = 512 * 1024;
/** Văn bản giữ lại sau khi bóc MIME (trước khi niêm phong). */
const MAX_TEXT = 16 * 1024;
/** Số email chờ tối đa mỗi tài khoản (app chưa tải về). */
export const MAX_PENDING = 200;

const LOCAL = /^[0-9a-f]{32}$/;

const ENTITIES: Record<string, string> = { nbsp: ' ', amp: '&', lt: '<', gt: '>', quot: '"' };
const fromCodePoint = (e: string): string => {
  const n = Number(e.slice(1));
  return n > 0 && n <= 0x10ffff ? String.fromCodePoint(n) : ' ';
};

/** Rút chữ từ HTML thư (bỏ style/script, xuống dòng ở khối). Chỉ để bộ đọc phía app có văn bản. */
export function htmlToText(html: string): string {
  return html
    .replace(/<(style|script|head)[^>]*>[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<br\s*\/?>|<\/(p|div|tr|li|h[1-6]|table)>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    // Giải mã thực thể MỘT lượt (không giải mã kép: "&amp;lt;" ⇒ "&lt;", không thành "<").
    .replace(/&(nbsp|amp|lt|gt|quot|#\d{1,7});/g, (_, e: string) => ENTITIES[e] ?? fromCodePoint(e))
    .replace(/[ \t]+/g, ' ')
    .replace(/ *\n */g, '\n')
    .replace(/\n\s*\n+/g, '\n')
    .trim();
}

/**
 * Email Worker (Cloudflare Email Routing, catch-all của INBOX_DOMAIN). Thư tới địa chỉ đang bật được bóc MIME, chỉ giữ
 * người gửi/tiêu đề/ngày/văn bản, NIÊM PHONG NGAY bằng khóa công khai X25519 của người dùng rồi mới ghi D1. Bản rõ chỉ
 * tồn tại trong bộ nhớ của lượt xử lý này; không ghi log nội dung, địa chỉ hay người gửi (ADR-0006, ADR-0012).
 */
export async function handleEmail(message: ForwardableEmailMessage, env: Env): Promise<void> {
  const to = message.to.toLowerCase();
  const at = to.lastIndexOf('@');
  const local = at > 0 ? to.slice(0, at) : '';
  if (to.slice(at + 1) !== env.INBOX_DOMAIN || !LOCAL.test(local)) {
    message.setReject('Unknown recipient');
    return;
  }
  if (message.rawSize > MAX_RAW_EMAIL) {
    message.setReject('Message too large');
    return;
  }
  const db = env.DB;
  const row = await db
    .prepare(
      `SELECT a.user_id AS user_id, b.bundle AS bundle,
              (SELECT COUNT(*) FROM inbound_mail m WHERE m.user_id = a.user_id) AS pending
         FROM inbound_addresses a
         JOIN users u ON u.id = a.user_id
         JOIN account_bundles b ON b.user_id = a.user_id
        WHERE a.local_part = ? AND u.deletion_requested_at IS NULL`,
    )
    .bind(local)
    .first<{ user_id: string; bundle: string; pending: number }>();
  if (!row) {
    message.setReject('Unknown recipient');
    return;
  }
  // Pro hết hạn ⇒ ngừng nhận thư (chỉ xem đệm, không gọi tsudev.com trong Email Worker).
  if (enforcing(env) && !isPro(await cachedEntitlement(env, row.user_id))) {
    message.setReject('Unknown recipient');
    return;
  }
  if (row.pending >= MAX_PENDING) {
    message.setReject('Mailbox full');
    return;
  }
  let boxPk: Uint8Array;
  try {
    const b64 = (JSON.parse(row.bundle) as { boxPk?: unknown }).boxPk;
    if (typeof b64 !== 'string') throw new Error('no_box_pk');
    boxPk = Uint8Array.from(atob(b64), (ch) => ch.charCodeAt(0));
  } catch {
    message.setReject('Recipient unavailable');
    return;
  }

  const raw = await new Response(message.raw).arrayBuffer();
  const mail = await PostalMime.parse(raw, { attachmentEncoding: 'arraybuffer' });
  const text = (mail.text?.trim() ? mail.text : htmlToText(mail.html ?? '')).slice(0, MAX_TEXT);
  const payload = new TextEncoder().encode(
    JSON.stringify({
      v: 1,
      from: (mail.from && 'address' in mail.from ? (mail.from.address ?? '') : '').slice(0, 320),
      subject: (mail.subject ?? '').slice(0, 500),
      date: mail.date ?? null,
      text,
    }),
  );
  const sealed = sealFor(boxPk, payload);
  await db
    .prepare('INSERT INTO inbound_mail (user_id, id, sealed, size, received_at) VALUES (?, ?, ?, ?, ?)')
    .bind(row.user_id, crypto.randomUUID(), sealed, sealed.length, Date.now())
    .run();
}
