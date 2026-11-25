# PHIẾU RÀ SOÁT BẢO MẬT - Nâng Flutter 3.50.1, sodium 4.1.5+1, sqlite3 3.9.2, pdfrx 3.1.0

- **PR / nhánh**: `chore/flutter-3.50`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (uỷ quyền cho agent)
- **Ngày**: 25/11/2026
- **Căn cứ**: ADR-0001 mục 4, ADR-0002 (phong bì), ADR-0020 (PDFium), `.standards/docs/SECURITY_BASELINE.md` mục 5,
  phiếu `logs/handover/20261124-03_viec-phien-sau.md` mục 5 bước 3

## 1. Thay đổi này đụng vào đâu

- [ ] Xác thực - [ ] Phân quyền - [ ] Tải tệp - [ ] Truy vấn CSDL mới - [ ] Hiển thị HTML - [ ] Gọi dịch vụ ngoài
- [x] Xử lý dữ liệu D3: thư viện mật mã (`sodium` - libsodium) và mã hóa CSDL khi lưu (`sqlite3` - SQLite3 Multiple
  Ciphers). KHÔNG đổi mã nguồn mật mã của repo, định dạng phong bì, AAD hay tham số KDF.
- [x] Phụ thuộc mới (bắc cầu): `material_ui` 1.11.1, `cupertino_ui` 1.1.7 (qua `pdfrx` 3.0.1+), nhà phát hành
  `flutter.dev` đã xác minh, BSD-3 - đạt `SECURITY_BASELINE.md` mục 5.

## 2. Phiên bản và thay đổi đã đọc

| Gói | Từ ⇒ đến | Thay đổi liên quan bảo mật |
| --- | --- | --- |
| `sodium` (lõi + app) | 4.1.2+1 ⇒ 4.1.5+1 | Changelog 4.1.3-4.1.5+1: chỉ build hook (`NIX_*` ⇒ User Defines, sửa dọn thư mục tạm, chép đệ quy) + cập nhật bản snapshot libsodium 1.0.22-stable. So `lib/` hai bản (`diff -rwB -I '// ignore'`): lớp FFI/JS KHÔNG đổi logic, chỉ bỏ chú thích `ignore`; khác biệt duy nhất ở `lib/src/hooks/**`. Repo không dùng biến `NIX_*`. |
| libsodium nhúng | 1.0.22-stable (snapshot 27/10) ⇒ 1.0.22-stable (snapshot 24/11) | `minisign -V` với khóa công khai chính thức của libsodium `RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3`: "Signature and comment signature verified", ký 24/11/2026. sha256 tarball `f5eecdc0…d9ee04`. |
| `sodium.js` (web) | libsodium.js sumo 0.8.4 | Hằng `jsSumoDist.hash` (sha512) và `bin/update_web.dart` không đổi ⇒ sha256 ghim trong `apps/app/tool/fetch_web_assets.sh` giữ nguyên. |
| `sqlite3` (app) | 3.9.1 ⇒ 3.9.2 | SQLite3 Multiple Ciphers ⇒ 2.7.0; sửa finalizer chạy hai lần khi isolate bị giết; ký tự NUL trong SQL; tắt nhất quán `SQLITE_ENABLE_MEMORY_MANAGEMENT`. Thư viện tải lúc dựng có sha256 ghim trong gói (`asset_hashes.dart`). `sqlite3.wasm` 3.9.2 cùng sha256 với 3.9.1 (`e7451780…`). |
| `pdfrx` / `pdfrx_engine` / `pdfium_*` | 3.0.0 / 0.9.3 / 0.4.3 ⇒ 3.1.0 / 0.9.6 / 0.4.4 | PDFium vẫn chromium/8125; `pdfium_dart` 0.4.3 kiểm SHA-256 ghim cho gói PDFium tải về; 0.9.6 đóng handle native trước khi giải phóng dữ liệu khi mở PDF lỗi. Xem ADR-0020 mục "Cập nhật". |

## 3. Đối chiếu OWASP

| Rủi ro | Có liên quan | Biện pháp đã áp dụng |
| --- | --- | --- |
| A02 Mật mã | Có | Vector `conformance/envelope-v1.json` khớp mã nguồn, KHÔNG sinh lại; kiểm độc lập bằng libsodium của hệ điều hành; CSDL cũ mở được bằng sqlite3mc mới |
| A06 Thành phần có lỗ hổng | Có | Đọc changelog từng gói; chữ ký minisign libsodium; sha256 ghim (sodium.js, sqlite3.wasm, thư viện sqlite3mc, PDFium) |
| A08 Toàn vẹn phần mềm | Có | `pubspec.lock` ghim băm nội dung; Flutter ghim commit `ae9b586f…` trong ci/release/apple.yml |
| A01, A03, A05, A07, A10 | Không | Không đổi máy chủ, truy vấn, cấu hình CSP hay xác thực |

## 4. Ca tấn công / hỏng hóc đã cân nhắc

1. **Bản libsodium bị tráo trong gói pub**: chặn bằng chữ ký minisign của tác giả libsodium (đã kiểm tay, mục 2) + băm
   nội dung gói trong `pubspec.lock`. **Test**: vector conformance + `verify_libsodium.py` (libsodium hệ điều hành độc lập).
2. **Định dạng phong bì lệch im lặng** (bản ghi cũ không mở được / bản ghi mới không tương thích thiết bị cũ):
   **Test**: CI "Vector đối chiếu khớp mã nguồn" (`diff` với `conformance/envelope-v1.json`) - khớp cục bộ.
3. **sqlite3mc đổi cipher mặc định hoặc định dạng trang ⇒ người dùng cũ mất truy cập CSDL**: app đặt khóa bằng
   `PRAGMA hexkey` và dựa vào cipher mặc định (`db_open_native.dart`). Đã kiểm chéo bằng ctypes với hai bản
   `libsqlite3mc.x64.linux.so` (sha256 khớp gói): tạo bằng 3.9.1 ⇒ 3.9.2 đọc được, 3.9.2 ghi ⇒ 3.9.1 đọc được, sai khóa
   ⇒ `file is not a database`, tệp không chứa bản rõ. **Test mới**: `vault_store_test.dart` "mặc định ChaCha20 và đọc
   được CSDL tạo bởi bản cũ" với tệp mẫu `test/fixtures/sqlite3mc-chacha20-tu-3.9.1.mau` (khóa thử, không phải bí mật).
4. **sodium.js web bị đổi**: sha256 ghim trong `fetch_web_assets.sh`, script dừng nếu không khớp.
5. **PDF độc hại (T32)**: không đổi so với ADR-0020; PDFium cùng bản, thêm sửa lỗi giải phóng handle khi mở lỗi.

## 5. Kiểm tra bắt buộc

- [x] Không secret nào trong mã, log, thông báo lỗi (khóa trong tệp mẫu là khóa thử `'ab' * 32`).
- [x] Không thêm phụ thuộc chưa rà soát (`material_ui`/`cupertino_ui`: `flutter.dev`, mục 1).
- [x] `packages/core`: `dart test` 108 đạt; vector khớp; `verify_libsodium.py` ĐẠT (BIP39, bằng chứng mời, chia sẻ khóa ví).
- [x] `apps/app`: `flutter analyze --fatal-infos` sạch, `flutter test` 167 đạt (gồm khứ hồi PDF).
- [ ] CI đủ job (core, app, desktop-ocr ×3, Android, Apple) - ghi kết quả vào PR.

## 6. Rủi ro còn lại

- `flutter/material` lỗi thời trên 3.50 (chặn từng dòng, AGENTS.md B.4) - không phải rủi ro bảo mật; gỡ theo phiếu MUI1.
- `pdfrx_pdfium_gate.dll` dựng lại trên Windows ⇒ băm mới ⇒ có thể bị antivirus gắn cờ lại: theo dõi VirusTotal bản
  beta kế tiếp (`docs/store/antivirus.md`).

## 7. Kết luận

- [x] Đạt - được merge khi CI xanh đủ job.

## 8. Bổ sung (25/11/2026, PR #89) - vá tạm build hook `sodium` cho macOS/iOS

- Sau #87, job macOS/iOS đỏ: Dart 3.14.0 dùng `posix_spawn` trên macOS ⇒ `./configure` tương đối không tìm thấy
  (upstream Skycoder42/libsodium_dart_bindings#245, đã gửi chẩn đoán).
- `third_party/sodium` = bản chép nguyên `sodium` 4.1.5+1 (BSD-3) + MỘT thay đổi ở `AutomakeBuilder._configure`
  (đường dẫn tuyệt đối). `diff -r` với gói pub.dev: chỉ khác hàm đó. Mã gọi libsodium (`lib/src/api|ffi|js`), tarball
  libsodium và chữ ký minisign không đổi ⇒ mục 2-4 giữ nguyên hiệu lực.
- Rủi ro mới: bản chép không tự nhận bản vá bảo mật của gói ⇒ dependabot không còn theo dõi `sodium` ở app. Gỡ ngay khi
  upstream phát hành bản sửa (`third_party/sodium/BAN_VA.md`); theo dõi #245.
- gitleaks: miễn trừ hẹp (đường dẫn VÀ nguyên dòng `int get keyBytes => sodium.crypto_*_KEYBYTES;`).
- CI #89: đủ 17 job xanh, gồm macOS (ad-hoc + chạy thử), iOS, OCR desktop ×3, Android.

