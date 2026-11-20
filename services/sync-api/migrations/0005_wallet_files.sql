-- P7b Tệp đính kèm của VÍ CHUNG (ADR-0017). Migration MỚI - 0001..0004 đã áp dụng là bất biến.
--
-- Tệp cá nhân giữ bảng `files` (R2 `u/<user_id>/<id>`). Tệp của ví chung nằm ở không gian ví để mọi thành viên đọc
-- được: R2 `w/<wallet_id>/<id>`. Nội dung đã mã hóa ở máy khách bằng khóa tệp riêng; khóa tệp nằm trong bản ghi
-- `attachment` đã niêm phong bằng khóa ví - máy chủ không có. Xóa ví ⇒ dòng bị CASCADE, đối tượng R2 do mã xóa.
CREATE TABLE wallet_files (
  wallet_id TEXT NOT NULL REFERENCES shared_wallets(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  size INTEGER NOT NULL,
  uploader_id TEXT,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (wallet_id, id)
);
