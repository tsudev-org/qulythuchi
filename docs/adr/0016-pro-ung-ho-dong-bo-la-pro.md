# ADR-0016: Pro + Ủng hộ - đồng bộ/sao lưu đám mây là Pro, quyền lợi kiểm ở máy chủ theo tsudev.com

- **Trạng thái**: ĐỀ XUẤT - nội dung ĐÃ CHỐT (19/11/2026, phiếu PRO1 mục 8-9). Chuyển ĐÃ CHẤP NHẬN khi tsudev-standards
  v3.9.0 (PRO-A) phát hành; phần dùng máy chủ quyền lợi chờ PRO-B.
- **Ngày**: 19/11/2026
- **Người quyết định**: chủ dự án (phạm vi Pro, 19/11/2026); agent-qulythuchi (cách làm)
- **Liên quan**: `.standards/docs/PRODUCT_POLICY.md` mục 3-4; phiếu toàn hệ
  `~/projects/logs/handover/20261119-PRO1_ke-hoach-luu-cuc-bo-pro-dong-bo-toan-he.md`; tsudev `docs/adr/0002-may-chu-quyen-loi.md`;
  ADR-0003, ADR-0010, ADR-0015

## 1. Bối cảnh

Phiếu T7 yêu cầu Pro tháng/năm + Ủng hộ + huy hiệu. Khi khởi động phiên (19/11/2026) tình hình như sau:

- Máy chủ quyền lợi dùng chung (T5) mới có ADR ĐỀ XUẤT ở tsudev, chưa có mã. tsudev ADR-0002 **bác** phương án mỗi app
  tự xác minh biên nhận Play ⇒ `sync-api` không được tự làm bộ xác minh riêng.
- ADR-0002 của tsudev giả định app giữ access token tsudev. Quly Thu Chi đăng nhập qua Worker (ADR-0003): Worker là RP,
  bỏ token tsudev ngay sau khi đăng nhập, app chỉ giữ token của qulythuchi ⇒ cần kênh máy chủ ↔ máy chủ (PRO-B b1).
- Chủ dự án chốt thêm cho toàn hệ: **miễn phí = chỉ lưu cục bộ; đồng bộ/sao lưu đám mây là Pro**; nhắc mỗi 30 ngày khi
  một tài khoản chưa Pro dùng trên ≥ 2 thiết bị (phiếu PRO1 mục 1-3).
- Production đang cho **đồng bộ E2EE miễn phí** từ P5/P6 ⇒ đã có người dùng cũ.

## 2. Quyết định (đề xuất)

1. **Phạm vi Pro** (chủ dự án chốt 19/11/2026):

   | Tính năng | Miễn phí | Pro |
   | --- | --- | --- |
   | Mọi nghiệp vụ trên thiết bị (ví, giao dịch, ngân sách, kế hoạch, báo cáo cơ bản, thuế, QR, tiện ích P9a) | ✅ | ✅ |
   | Sao lưu/khôi phục tệp `.qtbak`, xuất/nhập CSV | ✅ (quyền mang dữ liệu đi) | ✅ |
   | Đồng bộ + sao lưu đám mây giữa các thiết bị | - | ✅ |
   | Ví chung: tạo ví chung, mời thành viên | - | ✅ |
   | Ví chung: tham gia ví do người khác mời (chốt Q5: một người Pro dùng được cho cả nhà) | ✅ | ✅ |
   | Hạn mức máy chủ (chỉ có ý nghĩa khi đồng bộ) | - | bản ghi 200 MiB, tệp 1 GiB (mặc định toàn hệ 100 MiB + 1 GiB; qulythuchi cần nhiều hơn vì lịch sử giao dịch nhiều năm) |
   | Xuất PDF/XLSX, báo cáo nâng cao (nhiều kỳ, tài sản ròng) | - | ✅ |
   | Tự nhập nâng cao: email chuyển tiếp, đọc thông báo ngân hàng | - | ✅ |
   | Ghi nhanh gõ/giọng nói, OCR trên máy, sao kê CSV/XLSX | ✅ | ✅ |

2. **Nguồn sự thật** là JWS quyền lợi do tsudev.com ký (ES256). `sync-api` lấy JWS qua kênh RP (PRO-B b1), kiểm chữ ký
   bằng JWKS, lưu đệm trong D1 (**migration mới 0004**, không sửa 0001-0003) có hạn ≤ 24 giờ, rồi gắn vào phiên.
3. **Gate ở máy chủ**: `sync/push`, `PUT /files`, tạo ví chung/mời, bật hộp thư email ⇒ không Pro trả `402 pro_required`.
   `sync/pull` + `me/export` vẫn mở trong thời gian ân hạn. App chỉ ẩn/hiện nút theo quyền lợi đã đệm (≤ 7 ngày), không
   tự cấp quyền.
4. **Play Billing** (bản Play): thuê bao `tsudev_pro` (`thang`/`nam`) và tiêu hao `ung_ho_20k`…`ung_ho_200k` (gói chung
   TsuDEV Pro 49.000 ₫/tháng, 490.000 ₫/năm - PRO1 mục 9.1). App mở luồng mua với `obfuscatedAccountId` =
   base64url(SHA-256(`tsudev-pro|` + `sub`)); `purchaseToken` đi app ⇒
   `sync-api` ⇒ tsudev (PRO-B), không bao giờ xác minh trong app. Bản web/desktop/APK ngoài Play: mở `tsudev.com/pro`
   và `tsudev.com/ung-ho`. Bản Play không có liên kết thanh toán ra web (PRODUCT_POLICY 4.3).
5. **Thông báo nhiều thiết bị** theo phiếu PRO1 mục 3. Số thiết bị lấy từ `devices_30d` của JWS (PRO-B b2); bảng
   `devices` của `sync-api` chỉ dùng thêm khi tài khoản đã đồng bộ.
6. **Chuyển sang Pro**: chưa có người dùng thật (👤 xác nhận 19/11/2026) ⇒ tắt đồng bộ miễn phí thẳng ở bản kế tiếp,
   không cần ân hạn chuyển tiếp; dữ liệu thử nghiệm trên D1/R2 được xoá (báo 👤 trước khi xoá production). Quy tắc lâu
   dài khi Pro hết hạn: chặn đẩy ngay, kéo + xuất thêm 90 ngày, app báo trước ở mốc 30 và 7 ngày, rồi xoá bản mã trên máy
   chủ theo quy trình xoá (ADR-0010 mục 7). Dữ liệu trên thiết bị không bao giờ bị xoá.
7. **Huy hiệu**: dùng component Flutter chung (PRO-C), không tự vẽ bản riêng. Hiện cạnh tên ở màn Tài khoản và danh
   sách thành viên ví chung (chỉ khi người đó không ẩn).

## 3. Hệ quả

- Không có mã T7 tới khi PRO-A + PRO-B xong. Thứ tự khi mở lại: máy chủ (migration 0004 đệm quyền lợi + gate +
  chuyển tiếp Play) ⇒ app (lớp `Entitlements`, màn Pro/Ủng hộ, thông báo 30 ngày, huy hiệu, vi + en, test widget hai
  khổ) ⇒ phiếu rà soát `docs/security-reviews/<ngày>-t7-pro-ung-ho.md` + THREAT_MODEL (giả mạo quyền lợi, dùng lại biên
  nhận, vượt gate, liệt kê thiết bị).
- Định danh, JWS, mã lỗi `402 pro_required`, nội dung thông báo vi/en: dùng NGUYÊN VĂN hợp đồng chung PRO1 mục 9.
- Làm được trước PRO-B: màn Pro/Ủng hộ, thông báo nhiều thiết bị (nguồn quyền lợi giả trong test), lớp `Entitlements`
  kiểm JWS bằng JWKS (test với khoá thử), gate ở máy chủ với nguồn quyền lợi tiêm vào được.
- Lõi `packages/core` không đổi (quyền lợi không phải dữ liệu D3, không đụng phong bì).
