# PHIẾU RÀ SOÁT BẢO MẬT - OCR hóa đơn trên desktop (ADR-0021)

- **PR / nhánh**: `feat/ocr-desktop`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (uỷ quyền cho agent)
- **Ngày**: 24/11/2026
- **Căn cứ**: ADR-0021, ADR-0012 mục 7, ADR-0017 (trần ảnh), `.standards/docs/SECURITY_BASELINE.md`, AGENTS.md B.5

## 1. Thay đổi này đụng vào đâu

- [ ] Xác thực - [ ] Phân quyền - [x] Tải tệp (người dùng chọn ảnh hóa đơn trên máy, đọc trong bộ nhớ)
- [ ] Truy vấn CSDL mới (văn bản đi vào luồng xem trước Ghi nhanh có sẵn) - [ ] Hiển thị HTML
- [ ] Gọi ra dịch vụ ngoài (không có: OCR của hệ điều hành/Tesseract chạy trên máy)
- [x] Chạy tiến trình ngoài (Linux: `tesseract`)
- [x] Xử lý dữ liệu D3 (ảnh + chữ hóa đơn) - không đụng phong bì/khoá E2EE
- [x] Quyền nền tảng: macOS thêm `com.apple.security.files.user-selected.read-only` (chỉ tệp người dùng chọn)

## 2. Thiết kế

- Windows `Windows.Media.Ocr`, macOS Vision: API hệ điều hành chạy cục bộ; không thêm thư viện native nào vào gói.
- Linux: `Process.start('/usr/bin/tesseract' | '/usr/local/bin/tesseract', [...], runInShell: false)` - đường dẫn
  tuyệt đối cố định (không tra `PATH` ⇒ không bị chiếm bằng tệp cùng tên trong thư mục người dùng), đối số cố định
  (không chèn chuỗi người dùng), ảnh qua stdin (không tệp tạm), hết 60 giây ⇒ `SIGKILL`.
- Ảnh ≤ 25 MiB, kiểm ở Dart (trước khi đọc) VÀ ở mã native (Windows/macOS). Windows thu nhỏ về ≤
  `OcrEngine::MaxImageDimension` trước khi nhận dạng.
- Thông báo lỗi native chỉ chứa mã (`no_language`, `failed`, HRESULT) - không chứa nội dung ảnh/văn bản.
- Windows: luồng nền trả kết quả qua `PostMessage` tới cửa sổ chính; cửa sổ đã đóng ⇒ bỏ kết quả (không gọi kênh ngoài
  luồng nền tảng).

## 3. Ca tấn công đã cân nhắc

1. **Ảnh độc khai thác bộ giải mã ảnh** (T33): giải mã bằng Windows Imaging Component / ImageIO / Leptonica của hệ
   thống - được hãng/bản phân phối vá; tệp do chính chủ chọn; macOS App Sandbox bật thật. Còn lại: rủi ro thấp.
2. **Chiếm tệp chạy Tesseract**: chỉ hai đường dẫn hệ thống (cần quyền root để ghi). Test `desktop_ocr_test.dart`.
3. **Treo/hết bộ nhớ**: trần 25 MiB, timeout 60 giây giết tiến trình (test "quá thời gian").
4. **Lộ ảnh/chữ hóa đơn**: không mạng, không tệp tạm, không log (`debugPrint` chỉ trong integration test với ảnh vẽ sẵn).
5. **Dữ liệu sai vào sổ**: văn bản chỉ điền ô Ghi nhanh; người dùng xem trước và bấm lưu (ADR-0012 mục 3).

## 4. Kiểm chứng

- `apps/app/test/desktop_ocr_test.dart`: chọn ngôn ngữ, đường dẫn tuyệt đối, đối số + stdin, đệm `--list-langs`, mã thoát
  ≠ 0, timeout giết tiến trình, hủy chọn, trần 25 MiB.
- `apps/app/integration_test/desktop_ocr_test.dart` trên CI (`desktop-ocr`: Windows, macOS, Linux + xvfb): engine thật
  đọc hóa đơn vẽ sẵn, `parseReceiptText` ra 125000.

## 5. Kết luận

Chấp nhận. Rủi ro còn lại: lỗi bộ giải mã ảnh của hệ điều hành (thấp, vá theo hệ điều hành).
