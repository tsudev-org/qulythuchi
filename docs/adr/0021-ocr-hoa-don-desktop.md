# ADR-0021: OCR hóa đơn trên desktop - OCR của hệ điều hành (Windows, macOS), Tesseract của hệ thống (Linux)

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0012 mục 7; không thay thế)
- **Ngày**: 24/11/2026
- **Người quyết định**: agent-qulythuchi (phiếu `logs/handover/20261124-01_viec-phien-sau.md` mục 1.3)
- **Liên quan**: `apps/app/lib/services/{capture,capture_mobile,desktop_ocr}.dart`,
  `apps/app/windows/runner/ocr_channel.{h,cpp}`, `apps/app/macos/Runner/OcrChannel.swift`,
  `apps/app/integration_test/desktop_ocr_test.dart`, `scripts/package-linux.sh`,
  `docs/security-reviews/20261124-ocr-desktop.md`, THREAT_MODEL T33

## 1. Bối cảnh

ADR-0012 mục 7 chỉ bật "Quét hóa đơn" trên Android/iOS (Google ML Kit); desktop ẩn nút, Tesseract "dời lại". Người
dùng desktop vẫn có ảnh hóa đơn (chụp màn hình hóa đơn điện tử, ảnh chuyển từ điện thoại). Yêu cầu không đổi: nhận
dạng TRÊN MÁY, ảnh không rời thiết bị (D3), không thêm dịch vụ trả phí.

Bộ đọc hóa đơn ở lõi (`parseReceiptText`) **bỏ dấu trước khi so nhãn** và đọc theo dòng ⇒ chỉ cần engine trả đúng
chữ số + chữ Latinh theo dòng; mất dấu tiếng Việt không làm hỏng việc tìm tổng tiền.

## 2. Các phương án đã xét

| Phương án | Ưu | Nhược |
| --- | --- | --- |
| A. Đóng gói Tesseract + Leptonica native cho 3 nền tảng | Một engine, có `vie` | Tự dựng/ghim băm 2 thư viện C lớn × 3 nền tảng, +15-25 MB, thêm DLL lạ cho AV gắn cờ (bài học AhnLab `pdfrx_pdfium_gate.dll`), thêm bề mặt lỗi bộ nhớ khi đọc ảnh |
| B. Mô hình ONNX (PP-OCR) + onnxruntime | Chất lượng cao | Runtime native lớn, mô hình nhiều MB, tự viết hậu xử lý; quá nặng cho mục tiêu "lấy tổng tiền" |
| **C. OCR của hệ điều hành + Tesseract của bản phân phối Linux** | Không thêm thư viện native nào vào gói; engine do Microsoft/Apple/bản phân phối vá; chạy trên máy | Ngôn ngữ phụ thuộc máy người dùng; ba đường mã native nhỏ |
| D. Desktop chỉ "nhập từ ảnh" không OCR | Không mã mới | Không giải quyết nhu cầu |

## 3. Quyết định (phương án C)

1. **Windows**: `Windows.Media.Ocr` (Windows 10+), gọi bằng C++/WinRT trong runner (`ocr_channel.cpp`), kênh
   `com.tsudev.qulythuchi/ocr`. Ngôn ngữ chọn lúc chạy từ `OcrEngine::AvailableRecognizerLanguages`: ưu tiên `vi*`,
   rồi ngôn ngữ hồ sơ người dùng, rồi ngôn ngữ đầu tiên có sẵn; không có gói OCR nào ⇒ lỗi `no_language` (app báo
   "cài gói ngôn ngữ có nhận dạng chữ trong Cài đặt Windows"). Ảnh giải mã bằng `BitmapDecoder` (theo hướng EXIF), thu
   nhỏ đều về ≤ `OcrEngine::MaxImageDimension`. Chạy trên luồng nền (MTA), kết quả trả về luồng nền tảng qua
   `PostMessage` tới cửa sổ chính (kênh Flutter chỉ được trả lời trên luồng nền tảng).
2. **macOS**: Vision `VNRecognizeTextRequest` (`.accurate`, sửa lỗi ngôn ngữ bật), ngôn ngữ = giao của
   `supportedRecognitionLanguages()` với `vi-VN`/`vi`, rồi `en-US`; xếp dòng từ trên xuống theo hộp bao. Cùng tên kênh.
   Sandbox: thêm `com.apple.security.files.user-selected.read-only` (bộ chọn tệp).
3. **Linux**: Tesseract **của bản phân phối** (`/usr/bin/tesseract` hoặc `/usr/local/bin/tesseract`, đường dẫn tuyệt
   đối - không tra `PATH`), gọi `Process.start` không qua shell: `tesseract stdin stdout -l <vie+eng|eng> --psm 4`, ảnh
   qua stdin, hết 60 giây thì giết. Gói `.deb` thêm `Recommends: tesseract-ocr, tesseract-ocr-vie`; bản `.tar.gz`
   không có Tesseract ⇒ nút ẩn, trang Tự nhập nói cách cài. App không tải mô hình nào.
4. **Ảnh vào**: desktop không có camera ⇒ "Quét hóa đơn" mở bộ chọn tệp (`file_selector`, đã có) lọc JPEG/PNG (+
   HEIC/WebP/BMP nơi hệ điều hành đọc được); tệp > 25 MiB bị từ chối trước khi đọc (cùng trần `ImageSanitizer`). Ảnh
   chỉ ở bộ nhớ, không ghi tệp tạm, không lưu; văn bản đi vào ĐÚNG luồng xem trước của Ghi nhanh (ADR-0012 mục 3).
5. **Web vẫn không OCR** (không có engine trên máy đủ tin cậy trong trình duyệt mà không tải mô hình lớn).
6. **Kiểm chứng**: test đơn vị Dart cho bộ chọn ngôn ngữ/đối số/timeout Tesseract (tiến trình giả); `integration_test`
   chạy ENGINE THẬT trên CI Windows, macOS, Linux (xvfb + `tesseract-ocr-vie`): vẽ ảnh "TONG CONG 125.000" bằng font
   đóng gói, nhận dạng, kiểm `parseReceiptText` ra 125000.

## 4. Hệ quả

- Không thêm thư viện native nào vào gói desktop ⇒ không thêm tệp cho AV gắn cờ, không thêm việc ghim băm.
- Chất lượng tiếng Việt phụ thuộc máy: Windows/macOS có thể chỉ có mô hình Latinh/tiếng Anh (mất dấu) - chấp nhận vì
  bộ đọc bỏ dấu; người dùng luôn xem trước và sửa trước khi lưu.
- Windows không có gói OCR nào (hiếm, máy cắt giảm) ⇒ báo lỗi rõ, không ẩn nút.
- Linux bản `.tar.gz`/máy không cài Tesseract ⇒ không có OCR (như trước), có hướng dẫn cài.

## 5. Số đo trên CI (PR #74, 24/11/2026)

| Máy | Engine / ngôn ngữ có sẵn | Kết quả trên hóa đơn vẽ sẵn (3 dòng, font Inter 64 px) |
| --- | --- | --- |
| `windows-2025` | Windows.Media.Ocr, chỉ `en-US` | Đúng nguyên văn 3 dòng, `parseReceiptText` = 125000 |
| `macos-15` (15.8.2) | Vision `.accurate`; ngôn ngữ có sẵn gồm `vi-VT` (tiếng Việt - app chọn qua `hasPrefix("vi-")`) + `en-US` (đo 24/11, PR #81) | Đúng nguyên văn 3 dòng, = 125000 |
| `ubuntu-24.04` | Tesseract 5, `eng`, `osd`, `vie` ⇒ `vie+eng` | Đúng nguyên văn 3 dòng, = 125000 |

Chưa đo: chữ có dấu tiếng Việt và ảnh chụp hóa đơn thật (nghiệm thu của 👤 trên máy thật).
