# ADR-0010: Máy chủ đồng bộ P5 - lược đồ, rev tài khoản, tệp xuyên Worker, xóa tài khoản

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0003/0004, không thay thế)
- **Ngày**: 18/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `services/sync-api/**`, `docs/security-reviews/20261118-p5-sync-api.md`

## 1. Bối cảnh
Dựng `services/sync-api` (Workers + Hono + D1 + R2) theo ADR-0001/0003/0004. Cần chốt các điểm ADR trước để mở.

## 2. Quyết định
1. **Không gian bản ghi = tài khoản**: khóa chính `records(user_id, id)`. Hai tài khoản trùng id (không xảy ra với
   UUID v4, hoặc cố tình) là hai bản ghi riêng - không thể ghi đè chéo. Ví chung (P9) sẽ thêm không gian ví bằng
   migration mới.
2. **`rev` một bộ đếm mỗi tài khoản** (`users.rev`), tăng TRONG cùng D1 batch với lệnh ghi bản ghi ⇒ không trùng rev
   giữa các lượt đẩy song song, con trỏ kéo không nhảy qua bản ghi. Đẩy lại phong bì y hệt (SHA-256 trùng) là lũy
   đẳng, không tốn rev. Danh tính (id, loại, ví) là bất biến (nằm trong AAD) ⇒ đổi ⇒ `identity_mismatch`.
3. **Máy chủ kiểm khung, không kiểm nội dung**: đầu `QT 01 01`, cỡ tối thiểu theo khối đệm (bản ghi 256, khóa 16,
   tệp 4096), cỡ tối đa (bản ghi 64 KiB, tệp 10 MiB); gói khóa theo đúng lược đồ `AccountKeyBundle` v1 và từ chối
   Argon2id dưới sàn 2/19 MiB (máy chủ không lưu được gói khóa yếu). Dữ liệu mẫu thật sinh từ lõi:
   `packages/core/tool/gen_server_fixture.dart`.
4. **Tệp đính kèm đi xuyên Worker**, không dùng URL ký trước của R2 như phiếu P5 dự kiến: quyền kiểm ở mọi lượt,
   không phải cấp/giữ khóa S3 của R2 (thêm bí mật), tệp ≤ 10 MiB nằm thoải mái trong giới hạn thân yêu cầu của
   Workers. Tệp bất biến (đổi nội dung = id mới). Hạn mức 200 MiB/tài khoản; bản ghi 50 MiB/tài khoản.
5. **Phiên web = một thiết bị nền tảng `web`**: cookie `__Host-qt_session` HttpOnly Secure SameSite=Strict; mọi lượt
   ghi bằng cookie đòi `Origin` đúng + `X-Qt-Csrf: 1`. Thu hồi thiết bị áp cho cả app lẫn web.
6. **Bia mộ**: máy khách báo cờ `deleted` (siêu dữ liệu - lộ duy nhất "bản ghi này đã xóa"); máy chủ xóa hẳn sau 90
   ngày khi MỌI thiết bị còn hiệu lực đã kéo qua (`devices.pulled_rev` = `since` của lượt kéo, tức mốc thiết bị
   xác nhận đã lưu).
7. **Xóa tài khoản**: `POST /api/v1/me/deletion` ⇒ ân hạn 30 ngày (chỉ đọc/xuất, chặn ghi), hủy bằng
   `DELETE`. Hết hạn ⇒ xóa hẳn bản mã/khóa/tệp R2/thiết bị, ẩn danh hóa dòng `users` (`oidc_sub = deleted:<id>`) -
   đăng nhập lại cùng danh tính tsudev tạo tài khoản mới trống. `GET /api/v1/me/export` xuất toàn bộ (vẫn là bản mã).
8. **Không cron** (tài khoản Cloudflare đã hết 5 cron gói Free): dọn dẹp chạy kèm ~1% yêu cầu `/api` bằng `waitUntil`.
9. **Triển khai**: Worker `qulythuchi`, Custom Domain `qulythuchi.tsudev.com`, D1 `qulythuchi` (APAC), R2
   `qulythuchi-files` (APAC). Deploy thủ công `npm run deploy` (chưa có token API cho CI - xem `README` dịch vụ).

## 3. Hệ quả
- Không có khóa lạc quan: thiết bị PHẢI kéo + hợp nhất trước khi đẩy; hai thiết bị đẩy chéo nhau vẫn hội tụ vì hợp
  nhất theo trường giao hoán (thiết bị đẩy lại khi kết quả hợp nhất khác bản đã kéo) - ràng buộc cho P6.
- Xuất dữ liệu dựng toàn bộ JSON trong bộ nhớ: tài khoản gần hạn mức 50 MiB có thể vượt bộ nhớ Worker - phân trang
  khi đo thấy cần.
