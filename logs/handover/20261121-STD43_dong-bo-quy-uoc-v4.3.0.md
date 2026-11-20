# PHIẾU YÊU CẦU - Đồng bộ tsudev-standards v4.3.0

- **Mã phiếu**: 20261121-STD43
- **Từ**: phiên tsudev-standards, 21/11/2026 - **Đến**: phiên kế tiếp của `qulythuchi`
- **Trạng thái**: ĐÓNG (21/11/2026, agent-qulythuchi)
- **Nguồn**: https://github.com/tsudev-org/tsudev-standards/releases/tag/v4.3.0 (PR #66)

## Việc cần làm

1. Sync `.standards/` lên v4.3.0 trong PR kế tiếp.
2. Phiếu đề xuất 20261119-01 (Apple) đã DUYỆT có điều chỉnh: Apple `MUST` khi phát hành App Store, còn lại `MAY`, nút ẩn khi IdP chưa bật (`AUTH_AND_ACCOUNT.md` mục 3.2).
3. Dựng nút nhà cung cấp từ danh sách IdP trả về (`GET /api/v1/auth/providers`, sau khi `tsudev` có) thay vì gõ cứng `LOGIN_PROVIDERS` / `loginProviders`; nhận `apple` khi có. Trước khi phát hành iOS phải có Apple.

## Kết quả xử lý

- Việc 1: `.standards/` = v4.3.0 (PR `chore/standards-v4.3.0`).
- Việc 2 + 3: máy chủ `GET /api/v1/auth/providers` hỏi `https://tsudev.com/api/v1/auth/providers` (đệm 5 phút, lọc
  danh sách trắng `google|apple|github`, IdP lỗi ⇒ dự phòng Google + GitHub, không bao giờ Apple); `idp_hint=apple`
  được nhận. App (Android/iOS/desktop/web `/app/`) dựng nút theo danh sách, nút Apple theo HIG (đen/trắng). Test máy
  chủ + app; phiếu rà soát `docs/security-reviews/20261121-std43-idp-providers.md`.
- Lúc làm, endpoint của tsudev CHƯA lên production (404 ⇒ máy chủ ta dùng dự phòng, hành vi như cũ). tsudev bật xong
  thì nút tự theo, không cần phát hành lại app. Trước khi phát hành iOS: tsudev.com phải bật Apple (👤 Apple Developer).
