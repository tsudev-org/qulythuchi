-- T7 / PRO1 (ADR-0016): đệm quyền lợi TsuDEV Pro do tsudev.com ký (JWS ES256, PRODUCT_POLICY 7.4).
-- Migration đã áp dụng là BẤT BIẾN (AGENTS.md B.3).
--
-- Nguồn sự thật là JWS của tsudev.com, lấy qua kênh RP (`GET /api/rp/entitlements/{sub}`, private_key_jwt). Bảng này
-- chỉ là bộ đệm ≤ 24 giờ để gate đẩy/tải lên không gọi tsudev.com mỗi lượt. Không chứa dữ liệu D3: chỉ mốc thời gian,
-- huy hiệu, số thiết bị.
--
-- status: 'ok' (có JWS hợp lệ) | 'unknown_subject' (tsudev.com không trả quyền lợi cho tài khoản này - Grant OIDC đã
-- hết hạn, cần đăng nhập lại). pro_until/jws_exp/fetched_at: mili giây Unix. pro_until = 0: chưa từng có Pro.
CREATE TABLE entitlements (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('ok', 'unknown_subject')),
  jws TEXT,
  pro_until INTEGER NOT NULL DEFAULT 0,
  badge TEXT NOT NULL DEFAULT 'none' CHECK (badge IN ('pro', 'donor', 'both', 'none')),
  devices_30d INTEGER NOT NULL DEFAULT 0,
  jws_exp INTEGER NOT NULL DEFAULT 0,
  fetched_at INTEGER NOT NULL
);

-- Mã cài đặt (AUTH_AND_ACCOUNT 14.3) đã chuyển tiếp cho tsudev.com: chỉ lưu SHA-256 để biết mã nào cần báo lại (mỗi mã
-- ≤ 1 lần / 24 giờ ⇒ `devices_30d` đếm đủ mọi thiết bị mà không gọi tsudev.com mỗi lượt). Không dùng để nhận diện.
CREATE TABLE installations_seen (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  installation_hash TEXT NOT NULL,
  reported_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, installation_hash)
);

-- Pro hết hạn: mốc xoá bản mã trên máy chủ (pro_until + 90 ngày) đã qua thì dọn theo lô (src/maintenance.ts).
CREATE INDEX entitlements_pro_until ON entitlements(pro_until);
