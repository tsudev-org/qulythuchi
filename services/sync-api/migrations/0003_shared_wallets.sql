-- P9 Ví chung gia đình (ADR-0015). Migration MỚI - 0001/0002 đã áp dụng là bất biến.
--
-- Ví chung có KHÔNG GIAN BẢN GHI RIÊNG (khác ADR-0010 mục 1 "không gian = tài khoản"): bản ghi mang wallet_id của ví
-- chung nằm ở wallet_records, rev là bộ đếm của ví. Máy chủ vẫn zero-knowledge: chỉ lưu phong bì, khóa ví đã bọc
-- (bọc bằng khóa chủ của chính người đó, hoặc khối X-Wing + bí mật cặp mà máy chủ không có), quyền và siêu dữ liệu.

-- Một ví đã chia sẻ. id = id ví do máy khách sinh (UUID v4). key_ver: phiên bản khóa ví HIỆN TẠI - mọi lượt ghi phải
-- dùng đúng phiên bản này (xoay khóa khi thu hồi thành viên). needs_rotation: có người rời ví, chủ ví nên xoay khóa.
CREATE TABLE shared_wallets (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key_ver INTEGER NOT NULL,
  rev INTEGER NOT NULL DEFAULT 0,
  needs_rotation INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX shared_wallets_owner ON shared_wallets(owner_id);

-- Thành viên và quyền. Đúng một dòng 'owner' mỗi ví (chủ ví không đổi được trong P9).
CREATE TABLE wallet_members (
  wallet_id TEXT NOT NULL REFERENCES shared_wallets(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
  joined_at INTEGER NOT NULL,
  PRIMARY KEY (wallet_id, user_id)
);
CREATE INDEX wallet_members_user ON wallet_members(user_id);

-- Khóa ví đã bọc cho từng thành viên, mỗi phiên bản một dòng (bản ghi chưa kịp mã hóa lại vẫn cần phiên bản cũ).
-- Chủ ví: phong bì 'QT' bọc bằng khóa chủ. Thành viên: khối 'QS' (X-Wing + bí mật cặp). Thu hồi ⇒ xóa mọi dòng.
CREATE TABLE wallet_key_shares (
  wallet_id TEXT NOT NULL REFERENCES shared_wallets(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  key_ver INTEGER NOT NULL,
  wrapped BLOB NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (wallet_id, user_id, key_ver)
);
CREATE INDEX wallet_key_shares_user ON wallet_key_shares(user_id);

-- Lời mời. id là nửa công khai của mã mời; nửa bí mật KHÔNG BAO GIỜ tới máy chủ. Người nhận gửi bằng chứng (BLAKE2b có
-- khóa = bí mật) trên khóa công khai X-Wing của họ; chủ ví kiểm rồi mới chia khóa. Hoàn tất ⇒ xóa dòng.
CREATE TABLE wallet_invites (
  id TEXT PRIMARY KEY,
  wallet_id TEXT NOT NULL REFERENCES shared_wallets(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('editor', 'viewer')),
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  accepted_by TEXT REFERENCES users(id) ON DELETE CASCADE,
  accepted_at INTEGER,
  accept_kem_pk BLOB,
  accept_proof BLOB
);
CREATE INDEX wallet_invites_wallet ON wallet_invites(wallet_id);
CREATE INDEX wallet_invites_accepted ON wallet_invites(accepted_by);

-- Bản ghi của ví chung (cùng khung với records). key_ver: phiên bản khóa đã niêm phong phong bì này.
-- author_id/device_id: ai ghi lần cuối (để thu hồi/kiểm toán) - không phải dữ liệu D3.
CREATE TABLE wallet_records (
  wallet_id TEXT NOT NULL REFERENCES shared_wallets(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  type TEXT NOT NULL,
  sealed BLOB NOT NULL,
  size INTEGER NOT NULL,
  digest TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  key_ver INTEGER NOT NULL,
  rev INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  author_id TEXT,
  device_id TEXT,
  PRIMARY KEY (wallet_id, id)
);
CREATE INDEX wallet_records_rev ON wallet_records(wallet_id, rev);
