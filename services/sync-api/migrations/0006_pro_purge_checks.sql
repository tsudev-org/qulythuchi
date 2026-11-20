-- PRO2 (ADR-0018, PRODUCT_POLICY v1.2.0 mục 7.4 "Kênh trạng thái"): xoá bản mã vì hết Pro phải có xác minh.
-- Migration đã áp dụng là BẤT BIẾN (AGENTS.md B.3) - bảng mới, không đụng `entitlements` của 0004.
--
-- Mốc lần cuối máy chủ hỏi kênh trạng thái tsudev.com (`POST /api/rp/entitlements/status`) cho một tài khoản đang chờ
-- xoá vì hết Pro. Kết quả "hoãn" (kênh lỗi/hết giờ/khung sai, `unknown_subject`, kênh chưa cấu hình) hoặc "đã gia hạn"
-- đều ghi mốc ⇒ không hỏi lại trong 24 giờ (không dội tsudev.com). Tách khỏi `entitlements` vì tài khoản chưa từng có
-- đệm quyền lợi cũng có thể là ứng viên. Không chứa dữ liệu D3: chỉ mốc thời gian (mili giây Unix).
CREATE TABLE pro_purge_checks (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  checked_at INTEGER NOT NULL
);
