# ADR-0012: Tự nhập P7 - bộ đọc chung, hàng đợi thông báo mã hóa, email niêm phong, OCR/giọng nói trên máy

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0006, không thay thế)
- **Ngày**: 18/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `packages/core/lib/src/autoimport/**`, `apps/app/lib/services/{auto_import,import_csv,xlsx_reader,
  notification_bridge,capture*}.dart`, `apps/app/android/.../{BankNotificationListener,NotificationQueue,QuickAddWidget}.kt`,
  `services/sync-api/src/inbox/**`, `migrations/0002_email_inbox.sql`, `docs/security-reviews/20261118-p7-tu-nhap.md`

## 1. Bối cảnh
ADR-0006 chốt 5 cách tự nhập. P7 hiện thực chúng; cần chốt các điểm ADR-0006 để mở.

## 2. Quyết định
1. **Bộ đọc chung trong lõi** (Dart thuần, test được trên mọi đích), không mẫu riêng từng ngân hàng: nhãn phổ biến
   ("+50,000VND", "PS:", "GD:", "Số tiền GD:", "SD:", "ND:"), ví điện tử ("vừa nhận 100.000đ" + từ khóa chiều tiền).
   Lý do: không có mẫu thật để kiểm từng ngân hàng, định dạng đổi không báo trước; bộ đọc chung chịu được thay đổi nhỏ.
   OTP/khuyến mãi/không rõ chiều tiền ⇒ bỏ. Danh sách gói app ngân hàng chỉ để gợi ý, người dùng tự chọn app.
2. **Số tiền tiếng Việt** (`findSpokenAmount`): chữ số + đơn vị ("50k", "1tr2", "1,5 triệu"), chữ viết ("năm mươi
   nghìn", "hai trăm rưỡi"), nói tắt ("2 triệu 500" = 2,5 triệu). Số chữ không đơn vị bị bỏ (tránh "mua quà cho ba");
   số trần < 1000 hiểu là nghìn đồng (thói quen ghi chép VN). Không dùng số thực: giá trị nội bộ × 1000.
3. **Mọi giao dịch tự nhập vào hàng chờ** (`pending = true`, không tính số dư) trừ khi người dùng bật "Tự xác nhận"
   (tắt mặc định). Ghi qua `LedgerRepository.importTxns` (một lần ghi cho cả lô ⇒ một lượt đồng bộ). Ghi nhanh bằng
   câu/giọng nói/OCR là ngoại lệ: người dùng đã xem trước nên lưu thẳng.
4. **Chống trùng không thêm trường**: sao kê dùng dấu vân tay (ngày, số tiền có dấu, nội dung bỏ dấu) đếm theo số lần
   (nhập lại cùng tệp không nhân đôi, hai khoản giống hệt trong tệp vẫn giữ); thông báo/email dùng `possibleDuplicates`
   cùng nguồn + cùng nội dung (ngân hàng hay đăng lại thông báo).
5. **Thông báo Android**: `NotificationListenerService` chỉ giữ gói đã chọn (bỏ ngay mọi gói khác, bỏ nhóm/đang chạy),
   mã hóa mỗi mục AES-256-GCM bằng khóa Android Keystore (không xuất được), ghi `noBackupFilesDir`, tối đa 500 mục.
   Dart lấy ra và xóa (`drain`) khi kho khóa đang mở, rồi phân tích. Không có quyền nào khác; người dùng tự cấp quyền
   "Truy cập thông báo" sau màn công bố rõ. Hàng đợi dùng khóa Keystore thay vì khóa chủ vì dịch vụ chạy khi app khóa.
6. **Sao kê**: CSV và XLSX (bộ đọc XLSX tối thiểu trên `archive` đã có: trang đầu, chuỗi dùng chung, ô ngày theo kiểu
   ô; giới hạn 5 MB nén / 40 MB giải nén chống bom zip; không công thức/macro). Tự tìm dòng tiêu đề sau phần thông tin
   tài khoản, cột ghi nợ/ghi có, bỏ cột số dư. **PDF không làm**: gói Dart đọc PDF miễn phí đủ tốt không có
   (syncfusion có giấy phép thương mại); hướng người dùng tải bản Excel/CSV.
7. **OCR**: Google ML Kit Text Recognition (mô hình chữ Latinh đóng gói trong app, nhận dạng trên máy) + `image_picker`;
   ảnh tạm bị xóa ngay sau khi đọc. Chỉ Android/iOS; desktop/web ẩn nút (Tesseract desktop dời lại - ADR-0006 cho phép
   "hoặc tắt"). iOS tối thiểu 15.5 (yêu cầu của ML Kit). Lưu ý: SDK ML Kit có thể gửi số liệu sử dụng ẩn danh (không
   gồm ảnh/văn bản) cho Google - ghi ở phiếu rà soát.
8. **Giọng nói**: `speech_to_text`, lượt đầu luôn `onDevice: true`; máy không có gói ngoại tuyến ⇒ hộp thoại nói rõ âm
   thanh có thể tới Google/Apple, chỉ dùng dịch vụ HĐH khi người dùng đồng ý (mỗi lần). Web không dùng Web Speech API.
9. **Email niêm phong** (ngoại lệ E2EE duy nhất): địa chỉ `<128 bit hex>@in.qulythuchi.tsudev.com`, tắt mặc định,
   đổi/tắt được. Email Worker: kiểm địa chỉ + tài khoản không đang xóa + hộp ≤ 200 thư + thư ≤ 512 KiB ⇒ bóc MIME
   (`postal-mime`), chỉ giữ người gửi/tiêu đề/ngày/văn bản ≤ 16 KiB, NIÊM PHONG NGAY bằng `boxPk` rồi mới ghi D1. Không
   ghi log nội dung/địa chỉ. App tải `GET /api/v1/inbox`, mở bằng khóa danh tính (chỉ mở trong lượt gọi), nhập vào hàng
   chờ, xóa từng thư. Thư còn lại > 30 ngày bị dọn.
   **Niêm phong bằng tweetnacl, không libsodium.js**: workerd cấm biên dịch WASM động (test bắt được). `nacl.box` CHÍNH
   LÀ `crypto_box`; phần ghép duy nhất là nonce BLAKE2b-192(epk ‖ pk) theo đặc tả libsodium (`@noble/hashes`). Tương
   thích kiểm hai chiều với libsodium hệ thống (`scripts/gen-sealed-vector.py`, `test/fixtures/sealed-box-v1.json`).
10. **Gợi ý danh mục trên máy**: thứ tự nội dung trùng hệt ⇒ điểm theo từ học từ lịch sử (ngưỡng 0,75) ⇒ luật từ khóa
    mặc định theo tên danh mục mặc định. Phát hiện trùng (cùng ví, số tiền, ±1 ngày) khi ghi nhanh; hàm khoản chi bất
    thường (> 3 lần trung vị 90 ngày, ≥ 5 mẫu) có trong lõi.
11. **Widget màn hình chính** (Android): chỉ ba nút Gõ/Nói/Quét mở `com.tsudev.qulythuchi:/quick?mode=…`, KHÔNG hiển
    thị số dư hay dữ liệu nào (widget nằm ngoài khóa app). App vẫn đòi mở khóa trước khi ghi.

## 3. Hệ quả
- Bộ đọc chung có thể đọc sai thông báo lạ ⇒ mọi giao dịch tự nhập đi qua hàng chờ; người dùng sửa ở màn chi tiết.
- Tệp đính kèm (lưu ảnh hóa đơn mã hóa + `PUT /files`) CHƯA làm ở P7: OCR chỉ lấy số liệu, ảnh không giữ lại.
  Dời sang phase sau (cần bảng tệp cục bộ + đồng bộ tệp trong `SyncEngine`).
- Email Routing cho `in.qulythuchi.tsudev.com` (MX + catch-all ⇒ Worker `qulythuchi`) là việc của chủ dự án trên
  bảng điều khiển Cloudflare; chưa cấu hình thì thư bị trả lại, phần còn lại vẫn chạy.
