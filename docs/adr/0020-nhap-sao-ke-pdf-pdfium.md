# ADR-0020: Nhập sao kê ngân hàng dạng PDF - PDFium (`pdfrx`) chỉ để lấy chữ, dựng bảng ở lõi

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0006/0012 - 5 cách tự nhập; không thay thế)
- **Ngày**: 24/11/2026
- **Người quyết định**: agent-qulythuchi (việc dời từ P7 trong `logs/STATE.md`; 👤 uỷ quyền "hoàn thiện project")
- **Liên quan**: `packages/core/lib/src/autoimport/pdf_table.dart`, `apps/app/lib/services/import_pdf.dart`,
  `apps/app/lib/ui/data/data_page.dart`, `docs/security-reviews/20261124-sao-ke-pdf.md`, THREAT_MODEL T32

## 1. Bối cảnh

Nhiều ngân hàng Việt Nam chỉ gửi sao kê qua email dạng PDF, thường **có mật khẩu** (ngày sinh, số giấy tờ). P7 chỉ
nhận CSV/XLSX và bảo người dùng "tải bản Excel" - nhiều ngân hàng không có. Đọc PDF cần: giải nén luồng nội dung, giải
mã font (Identity-H + ToUnicode), và với tệp có mật khẩu là **giải mã AES/RC4** của PDF. Tự viết phần mật mã đó trái
nguyên tắc "không tự chế mật mã" (AGENTS.md B.5).

## 2. Quyết định

1. **Thư viện**: `pdfrx` **3.0.0** (ghim đúng phiên bản - bản 3.0.1+ đòi Dart 3.14, Flutter đang ghim 3.47.8), MIT, trên
   **PDFium** (engine PDF của Chrome, BSD-3/Apache-2.0, được fuzz liên tục bởi OSS-Fuzz). Chạy cả 6 đích: Android, iOS,
   macOS, Windows, Linux (FFI) và web (wasm).
2. **Chỉ lấy chữ**: app chỉ gọi `PdfDocument.openData` + `page.loadText()` (ký tự + hộp bao). KHÔNG hiển thị trang, KHÔNG
   chạy JavaScript của PDF (bản PDFium dựng sẵn của bblanchon là bản không V8), KHÔNG theo liên kết, KHÔNG tải gì.
3. **Dựng bảng ở lõi** (Dart thuần, `pdfGlyphsToRows`): ký tự ⇒ từ ⇒ dòng ⇒ ranh giới cột theo hồ sơ chiếu trục x của
   các dòng giao dịch (có ngày) + dòng tiêu đề cột; gộp dòng xuống hàng của diễn giải; bỏ tiêu đề lặp mỗi trang. Kết quả
   đi vào ĐÚNG luồng ghép cột + chống trùng + hàng chờ xác nhận của CSV/XLSX (không thêm đường ghi dữ liệu mới).
4. **Mật khẩu PDF**: hỏi bằng hộp thoại, chỉ giữ trong bộ nhớ đủ để mở tệp, không lưu, không log. Huỷ ⇒ dừng êm.
5. **Giới hạn**: tệp ≤ 15 MiB, ≤ 200 trang, ≤ 2 triệu ký tự, ≤ 20.000 dòng. PDF ảnh quét (không có lớp chữ) ⇒ báo rõ, gợi ý
   bản điện tử/CSV hoặc OCR từng trang (Tự nhập > Hóa đơn).
6. **Chuỗi cung ứng**: bản PDFium native do build hook của `pdfium_dart` tải từ `bblanchon/pdfium-binaries` (GitHub
   Releases) và **kiểm SHA-256 ghim trong gói** (`verifyPdfiumArchive`); iOS/macOS qua XCFramework của tác giả gói. Bản web
   là `pdfium.wasm` + worker nằm trong gói, app TỰ phục vụ ở `/app/assets/packages/pdfrx/assets/`. CSP `<meta>` của
   `/app/` thêm DUY NHẤT `blob:` vào `connect-src` (worker của pdfrx đọc dữ liệu qua `blob:` URL - đo thật bằng
   Playwright: bị chặn khi thiếu); `blob:` chỉ trỏ tới dữ liệu do chính trang tạo trong bộ nhớ, không mở nguồn mạng
   nào. Phần còn lại giữ nguyên (`'self'`, `'wasm-unsafe-eval'`, `worker-src 'self' blob:`). `pubspec.lock` ghim băm nội dung mọi gói.
7. **Dựng**: build hook biên dịch một thư viện C nhỏ (`pdfrx_pdfium_gate`) ⇒ Linux cần `clang` khi `flutter test`/
   `flutter build` (job CI đã cài); Windows cần Visual Studio C++, macOS/iOS cần Xcode (đã có trên runner).

## 3. Phương án đã loại

- **Tự viết bộ đọc PDF thuần Dart**: không cần mã native, nhưng phải tự cài giải mã AES/RC4 + RC4 key schedule của chuẩn
  PDF ⇒ tự chế mật mã; font CID/ToUnicode và luồng nén nhiều biến thể ⇒ dễ sai im lặng với sao kê thật.
- **`syncfusion_flutter_pdf`**: giấy phép thương mại/cộng đồng có điều kiện doanh thu, không tương thích AGPL-3.0 phân phối
  lại (ADR-0005).
- **Gửi PDF lên máy chủ để đọc**: phá E2EE (sao kê là D3) - loại ngay.
- **OCR ảnh trang**: chậm, sai số tiền; chỉ dùng cho PDF quét.

## 4. Hệ quả

- App nặng thêm: native ~5-6 MB/ABI (libpdfium), web +5,2 MB (`pdfium.wasm`, chỉ tải khi mở trang web app).
- Bề mặt tấn công mới: PDFium phân tích tệp không tin cậy (T32) - chấp nhận vì PDFium là bộ đọc PDF được kiểm thử
  khắc nghiệt nhất hiện có; tệp chỉ do chính người dùng chọn; nâng `pdfrx` theo Dependabot + đọc changelog bảo mật.
- Nâng `pdfrx` lên 3.0.1+ khi nâng Flutter ≥ 3.50 (cùng PR).

## Cập nhật

- **25/11/2026 - nâng `pdfrx` 3.1.0** (cùng PR nâng Flutter 3.50.1, nhánh `chore/flutter-3.50`): vẫn ghim ĐÚNG phiên
  bản như mục 1. `pdfrx_engine` 0.9.6, `pdfium_dart`/`pdfium_flutter` 0.4.4. PDFium vẫn chromium/8125 (đổi lần cuối ở
  0.4.1) ⇒ thư viện PDFium trong gói Windows/macOS/Linux/Android không đổi; `pdfium_dart` 0.4.3 thêm kiểm SHA-256 ghim
  cho gói PDFium tải lúc dựng. Cách nạp PDFium và `pdfrx_pdfium_gate` không đổi (không cần ADR mới). `pdfrx` 3.0.1+
  kéo theo `material_ui`/`cupertino_ui` (bắc cầu); app chỉ dùng phần đọc chữ, không dùng widget xem PDF.

