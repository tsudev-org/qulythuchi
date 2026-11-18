-- P7 (ADR-0006, ADR-0012): email chuyển tiếp niêm phong. TẮT mặc định: chỉ người dùng tự bật mới có địa chỉ.
-- Địa chỉ `<local_part>@<INBOX_DOMAIN>`, local_part 128 bit ngẫu nhiên (32 hex), đổi được (địa chỉ cũ hết hiệu lực).
CREATE TABLE inbound_addresses (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  local_part TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);

-- Email đã NIÊM PHONG (crypto_box_seal bằng boxPk của người dùng) ngay khi nhận; máy chủ không lưu bản rõ.
-- App tải về rồi xóa; còn lại quá 30 ngày thì máy chủ xóa (src/maintenance.ts).
CREATE TABLE inbound_mail (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  sealed BLOB NOT NULL,
  size INTEGER NOT NULL,
  received_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, id)
);
CREATE INDEX inbound_mail_received ON inbound_mail(received_at);
