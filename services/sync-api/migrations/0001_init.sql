-- Quly Thu Chi - lược đồ khởi tạo máy chủ đồng bộ (D1/SQLite).
-- Migration đã áp dụng là BẤT BIẾN (AGENTS.md B.3): muốn đổi thì tạo tệp mới.
--
-- Máy chủ zero-knowledge (ADR-0002/0004/0010): chỉ lưu phong bì đã niêm phong ở máy khách cùng siêu dữ liệu tối
-- thiểu (id ngẫu nhiên, loại, id ví, kích thước, rev). Không có cột nào chứa số tiền, ghi chú, tên ví hay khóa rõ.

-- Người dùng = danh tính tsudev (sub của OIDC). Không lưu mật khẩu, không lưu token của tsudev.com.
-- rev: bộ đếm tăng đơn điệu của tài khoản, gán cho mỗi lần ghi bản ghi (con trỏ kéo của thiết bị).
-- deletion_requested_at: yêu cầu xóa tài khoản (ân hạn 30 ngày - AUTH_AND_ACCOUNT.md mục 12).
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  oidc_sub TEXT NOT NULL UNIQUE,
  email TEXT,
  email_verified INTEGER NOT NULL DEFAULT 0,
  display_name TEXT,
  avatar_url TEXT,
  rev INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_login_at INTEGER NOT NULL,
  deletion_requested_at INTEGER
);

-- Yêu cầu đăng nhập đang chờ tsudev.com trả về (một lần, sống 10 phút).
CREATE TABLE login_requests (
  state_hash TEXT PRIMARY KEY,
  binder_hash TEXT NOT NULL,
  nonce TEXT NOT NULL,
  code_verifier TEXT NOT NULL,
  client_kind TEXT NOT NULL CHECK (client_kind IN ('web', 'app')),
  app_redirect_uri TEXT,
  app_state TEXT,
  app_code_challenge TEXT,
  return_to TEXT,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

-- Mã một lần trả về app, đổi lấy token kèm code_verifier (sống 60 giây).
CREATE TABLE app_codes (
  code_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  redirect_uri TEXT NOT NULL,
  code_challenge TEXT NOT NULL,
  used_at INTEGER,
  expires_at INTEGER NOT NULL
);

-- Thiết bị đã đăng nhập (app: một lần đăng nhập = một thiết bị = một họ refresh token; web: một phiên trình duyệt).
-- pulled_rev: con trỏ kéo xa nhất thiết bị đã báo - dọn bia mộ chỉ khi mọi thiết bị còn hiệu lực đã qua nó.
CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  platform TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  pulled_rev INTEGER NOT NULL DEFAULT 0,
  revoked_at INTEGER
);
CREATE INDEX devices_user ON devices(user_id);

-- Refresh token xoay vòng; chỉ lưu SHA-256. used_at khác NULL = đã xoay; dùng lại token đã xoay ⇒ thu hồi thiết bị.
CREATE TABLE refresh_tokens (
  token_hash TEXT PRIMARY KEY,
  device_id TEXT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  used_at INTEGER
);
CREATE INDEX refresh_tokens_device ON refresh_tokens(device_id);

-- Phiên trình duyệt (bản web /app): cookie __Host- chỉ lưu băm, gắn với một dòng devices để thu hồi được.
CREATE TABLE web_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);
CREATE INDEX web_sessions_device ON web_sessions(device_id);

-- Gói khóa tài khoản (AccountKeyBundle JSON, mọi phần bí mật đã bọc ở máy khách). previous: bản trước lần thay gần
-- nhất - đường lùi nếu một thiết bị ghi đè hỏng.
CREATE TABLE account_bundles (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  bundle TEXT NOT NULL,
  previous TEXT,
  updated_at INTEGER NOT NULL
);

-- Khóa ví đã bọc bằng khóa chủ (phong bì v1, ngữ cảnh khóa ví).
CREATE TABLE wallet_keys (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wallet_id TEXT NOT NULL,
  wrapped BLOB NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, wallet_id)
);

-- Bản ghi đồng bộ: phong bì v1 đã niêm phong (ADR-0004). digest = SHA-256 của sealed (đẩy lại y hệt là lũy đẳng).
-- deleted: siêu dữ liệu bia mộ do máy khách báo (để dọn sau 90 ngày), bản thân cờ xóa thật nằm trong bản mã.
CREATE TABLE records (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  type TEXT NOT NULL,
  wallet_id TEXT,
  sealed BLOB NOT NULL,
  size INTEGER NOT NULL,
  digest TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  rev INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  device_id TEXT,
  PRIMARY KEY (user_id, id)
);
CREATE INDEX records_user_rev ON records(user_id, rev);

-- Tệp đính kèm (ảnh hóa đơn...) đã mã hóa ở máy khách; nội dung nằm ở R2 khóa `u/<user_id>/<id>`.
CREATE TABLE files (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  wallet_id TEXT,
  size INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, id)
);

-- Giới hạn tần suất cửa sổ cố định.
CREATE TABLE rate_limits (
  key TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  count INTEGER NOT NULL
);

-- Nhật ký sự kiện bảo mật (đăng nhập, thiết bị, thay gói khóa, xóa tài khoản). IP chỉ lưu dạng băm có muối.
-- detail chỉ chứa id kỹ thuật (id thiết bị, loại client) - KHÔNG BAO GIỜ dữ liệu D3.
CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  event TEXT NOT NULL,
  detail TEXT,
  ip_hash TEXT,
  at INTEGER NOT NULL
);
CREATE INDEX audit_log_user ON audit_log(user_id, at);
