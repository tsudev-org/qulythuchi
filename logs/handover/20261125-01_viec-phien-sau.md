# PHIẾU BÀN GIAO 20261125-01 - Việc cho phiên sau (sau phiên `qulythuchi-09`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-09`, AKB `SES-20261125-0104-52cc`), 25/11/2026
- **Trạng thái**: ĐÓNG 25/11/2026 (phiên `qulythuchi-10`) - thay bằng phiếu `20261125-02`. Trước đó: thay phiếu `20261124-03` (ĐÓNG; bảng việc chờ 👤 ở mục 2 của nó VẪN dùng - chép tóm tắt ở mục 3).
- **Đọc kèm**: `logs/STATE.md`, AGENTS.md B.4, `third_party/sodium/BAN_VA.md`, phiếu `20261125-UI2_*`.

## 0. Hiện trạng (25/11/2026, sáng)

- `main`: #87 (Flutter 3.50.1 / Dart 3.14.0, sodium 4.1.5+1, pdfrx 3.1.0, sqlite3 3.9.2 - chủ dự án gộp 02:18) và #88
  (trang `/security/`, SEC2) đã gộp. Production `deploy-2026.11.25.1` (web app build Flutter 3.50.1 + `/security/`):
  `/`, `/app/`, `/tai-ve/`, `/security/`, `security.txt`, health, providers 200; `/auth/web/start` 302; Playwright
  `/app/` Sáng + Tối 0 lỗi console.
- **`main` hiện dựng macOS/iOS HỎNG** cho tới khi gộp #89 (mục 1.1). Không cắt thẻ beta trước khi gộp #89.
- PR mở: **#89** (vá tạm hook sodium, CI 17/17 xanh), **#90** (đo khởi động desktop, chồng trên #89, OCR ×3 xanh).
- Nhánh thử nghiệm (KHÔNG PR): `thu/apk-unbundled` (mục 1.4).

## 1. Việc agent tự làm (theo thứ tự)

1. **Gộp #89 rồi #90** (👤 gộp; GitHub tự chuyển đích #90 sang `main` khi #89 gộp - kiểm lại CI #90 sau khi đổi đích).
   Gốc lỗi: Dart 3.14 dùng `posix_spawn` trên macOS ⇒ `./configure` tương đối hỏng (Skycoder42/libsodium_dart_bindings#245,
   đã gửi chẩn đoán + bản sửa 1 dòng, tài khoản tsudev-tsudev). **Theo dõi #245**: upstream phát hành bản sửa ⇒ xoá
   `third_party/sodium`, khối `dependency_overrides`, ngoại lệ `.gitignore` + `.gitleaks.toml` tương ứng; nâng `sodium`.
   Trong lúc còn bản chép: dependabot KHÔNG theo dõi `sodium` ở app - tự đọc changelog gói mỗi tuần.
2. **Phiếu UI2** (`logs/handover/20261125-UI2_ra-soat-giao-dien-web.md`, chủ dự án uỷ quyền mở Playwright): rà sâu
   website + `/app/`, mục 0 phiếu toàn hệ trước. Ưu tiên cao nhất sau khi #89/#90 gộp.
3. **Cắt beta** `v26.11.DDNN-beta.1` sau khi #89 gộp (bản đầu trên Flutter 3.50 + pdfrx 3.1.0): theo dõi VirusTotal
   (`pdfrx_pdfium_gate.dll` dựng lại ⇒ băm mới ⇒ có thể AhnLab/Cynet gắn cờ lại, `docs/store/antivirus.md`), kiểm APK/zip/deb.
4. **APK unbundled** (AGENTS.md B.4): đo cục bộ trên `thu/apk-unbundled` (arm64, Flutter 3.50.1):

   | | Cài đặt | Tải về (≈ gzip) |
   | --- | --- | --- |
   | Hiện tại (ML Kit đóng gói sẵn) | 56,9 MB | 27,4 MB |
   | Thin (`play-services-mlkit-text-recognition` 19.0.2 qua dependency substitution + `mobile_scanner` unbundled) | 38,5 MB | 19,0 MB |

   Còn vượt 25 MB cài đặt (libapp 14,1 + libflutter 11,3 + PDFium 6,6 MB). Đánh đổi: máy KHÔNG có Play services (APK
   GitHub, Huawei, F-Droid) mất OCR + quét mã. Cần 👤 chọn: (a) thin cho mọi bản, (b) thin chỉ bản Play (`TSU_CHANNEL=play`,
   cấu hình Gradle theo kênh) + bản GitHub giữ bundled, (c) giữ nguyên và ghi B.4. Chọn (a)/(b) ⇒ ADR mới + thông báo
   lỗi riêng "cần Google Play services" (hiện chỉ toast `scanFailed` chung, `quick_entry_sheet.dart` `_scan`) + thử trên
   máy thật có/không có Play services.
5. **Linux không có Secret Service ⇒ app sập ngay** (`terminate called after throwing an instance of 'LibsecretError'`,
   đo trên WSL 25/11): lỗi C++ từ `flutter_secure_storage_linux` không bắt được ở Dart ⇒ người dùng Linux tối giản/WSL thấy
   app tắt im lặng. Hướng: kiểm D-Bus `org.freedesktop.secrets` trước khi dùng kho bí mật, không có ⇒ màn lỗi khởi động có
   hướng dẫn (cài gnome-keyring/KeePassXC); CI đã có mẫu mở gnome-keyring (`desktop-ocr`, PR #90). Cần phiếu rà soát (D3).
6. Phiếu `tsudev-ui-flutter` 20261125-MUI1 (tsudev_ui chuyển `material_ui`): khi có bản mới ⇒ `dart fix --apply
   --code=migrate_design_widgets`, gỡ 76 dòng `// ignore: deprecated_member_use` + header `l10n.yaml` (AGENTS.md B.4).
   `tsudev_ui` v0.5.0 đã có `TsuXdApprover` + `TsuXdApproveScreen` (QR2b phía UI) ⇒ kiểm phía tsudev.com đã xong QR2b chưa rồi làm "QR vai XÁC NHẬN".
7. Dependabot sẽ mở lại PR pub đã có trong #87 ⇒ đóng nếu trùng.

## 2. Bằng chứng / số đo của phiên

- Mật mã: vector `conformance/` khớp, KHÔNG sinh lại; `verify_libsodium.py` đạt; minisign libsodium hợp lệ; sqlite3mc
  2.7.0 đọc được CSDL tạo bởi bản cũ (test mới `vault_store_test.dart` + tệp `test/fixtures/sqlite3mc-chacha20-tu-3.9.1.mau`).
  Phiếu rà soát `docs/security-reviews/20261125-nang-flutter-sodium.md` (+ mục 8 trong #89).
- Web (Flutter 3.50.1): `main.dart.js` 1,88 MB gzip, `canvaskit.wasm` 2,93 MB gzip.
- Khởi động desktop (CI #90): lần đầu / chạy lại trung vị - Windows 672 / 429 ms, macOS 1 382 / 323 ms, Linux 565 / 415 ms.
- SEC2: SSL Labs A+ (4/4), Observatory A+ 150 (12/12), Scorecard 7.1, Best Practices 16946 passing; dữ liệu
  `docs/security/trust.json` (ngày đo quá 120 ngày ⇒ build dừng: đo lại trước ~20/03/2027).

## 3. Việc chờ 👤 (không đổi - chi tiết ở phiếu 20261124-03 mục 2)

Mua thử Pro + Ủng hộ; nghiệm thu P9 (2 tài khoản) + P7b; Quét hóa đơn desktop bằng ảnh thật; "Quét để đăng nhập" trên
điện thoại; `PRO_ENFORCE=on`; (tuỳ chọn) thư Cynet. **Mới**: gộp #89/#90; chọn phương án APK (mục 1.4).

## 4. Bẫy mới

- `.gitignore` chuẩn chặn `*secret*` và `bin/` - chép gói bên thứ ba vào repo phải so `git ls-files | wc -l` với
  `find -type f | wc -l` (AKB `LES-20261125-0658-1326`).
- Dựng Linux cục bộ: thiếu `libsecret-1-dev` ⇒ `apt-get download libsecret-1-dev libgcrypt20-dev libgpg-error-dev`,
  `dpkg -x` vào `~/.cache/lotus-tmp/secret/root`, sửa `prefix=` trong `.pc`, symlink `.so` ⇒ `PKG_CONFIG_PATH`. Lần cấu
  hình CMake lỗi để lại `CMAKE_INSTALL_PREFIX=/usr/local` ⇒ xoá `build/linux` trước khi dựng lại.
- App macOS chạy trong sandbox: không ghi được tệp ngoài container ⇒ tín hiệu đo dùng MÃ THOÁT (37), không dùng tệp.
- Lỗi CSP `connect-src` khi chạy `/app/` ở `localhost` (gọi API tuyệt đối `https://qulythuchi.tsudev.com`) là do môi
  trường - production 0 lỗi.
- Flutter 3.50 đòi AGP ≥ 9.1.1 (đã nâng trong #87).
