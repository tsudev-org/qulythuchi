# ADR-0006: Tự nhập giao dịch: thông báo, sao kê, OCR, giọng nói, email niêm phong

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi (chủ dự án duyệt hướng chung 17/11/2026)

## 1. Bối cảnh
Việt Nam chưa có API ngân hàng mở miễn phí. Chủ dự án chọn cả 5 cách tự nhập.

## 2. Quyết định
| Cách | Cơ chế | Dữ liệu rời thiết bị? |
| --- | --- | --- |
| Thông báo ngân hàng (Android) | `NotificationListenerService`, chỉ nghe gói app ngân hàng người dùng chọn; bộ phân tích mẫu trong `packages/core` | Không |
| Sao kê | Nhập CSV/XLSX/PDF (văn bản) theo mẫu từng ngân hàng, chống trùng bằng băm (ngày, số tiền, mô tả) | Không |
| OCR hóa đơn | Android/iOS: Google ML Kit Text Recognition trên máy; desktop: Tesseract `vie` cài kèm hoặc tắt | Không |
| Giọng nói | Nhận dạng trên máy khi nền tảng hỗ trợ (`requiresOnDeviceRecognition`); không có ⇒ báo rõ trước khi dùng dịch vụ hệ điều hành | Tùy nền tảng, báo trước |
| Email chuyển tiếp | **Tắt mặc định.** Địa chỉ ngẫu nhiên `<128-bit>@in.qulythuchi.tsudev.com`; Email Worker niêm phong ngay bằng khóa công khai X25519 của người dùng (`crypto_box_seal`), không lưu bản rõ, xóa sau khi app tải về hoặc sau 30 ngày | Có, máy chủ thấy bản rõ vài mili giây khi xử lý - ghi rõ ở màn hình bật |

Giao dịch tự nhập vào hàng chờ "Cần xác nhận", không cộng thẳng vào số dư trừ khi người dùng bật tự xác nhận.

## 3. Hệ quả
- Google Play (nếu lên sau này) yêu cầu khai báo quyền nghe thông báo; bản GitHub/F-Droid không vướng.
- Email chuyển tiếp là ngoại lệ E2EE duy nhất, có trong mô hình đe dọa.
