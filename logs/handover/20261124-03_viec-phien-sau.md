# PHIẾU BÀN GIAO 20261124-03 - Việc cho phiên sau (sau phiên `qulythuchi-08`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-08`), 24/11/2026
- **Trạng thái**: MỞ. Thay phiếu `20261124-02` (đã ĐÓNG; bảng mục 2 của nó chép lại dưới đây, có bổ sung).
- **Đọc kèm**: `logs/STATE.md`, AGENTS.md B.4, `docs/store/antivirus.md`, ADR-0021, ADR-0023.

## 0. Hiện trạng (24/11/2026, khuya)

- Production `deploy-2026.11.24.4` (Worker `5ff4dc02`, #83 npm); trước đó `.3` đưa màn chào `TsuSignInScreen`
  (QR3, PR #78) lên web app.
  `/`, `/app/`, `/tai-ve/`, health, providers 200; `/auth/web/start` 302; Playwright `/app/` Sáng + Tối 0 lỗi console.
- Releases: `v26.11.2401-beta.1`, `v26.11.2402-beta.1` ĐÃ BỎ NHÁP (AhnLab-V3 gỡ cờ, zip 0/7x);
  `v26.11.2403-beta.1` (có QR3) tự công bố. Không cần bỏ `pdfrx_pdfium_gate.dll` khỏi gói Windows nữa.
- Đã gộp: #78 (QR3 + chuẩn v5.3.0 + knip + ruff + `tsudev_ui` v0.4.0), #80 (dependabot bỏ qua typescript major).
- Phiên `qulythuchi-07` bị tắt máy đột ngột lúc 22:32 khi đang sửa `dependabot.yml` ⇒ xem bẫy mục 4.

## 1. Việc agent tự làm (theo thứ tự)

1. **Dependabot**: #79 đã thay bằng #83 (không có TS 7) - ĐÃ GỘP cùng #82 (actions) và đã deploy (mục 0). #84
   (`sodium` 4.1.5 ở lõi) + #85 (`pdfrx` 3.1.0, `sodium` ở app) ĐÃ ĐÓNG: cần Dart SDK ^3.14.0 mà Flutter ghim 3.47.8
   có Dart 3.13.7 ⇒ xem mục 3 dưới đây (dependabot sẽ mở lại khi có bản mới hơn).
2. **APK mỗi ABI > 25 MB** (AGENTS.md B.4: arm64 ~57 MB cài, ~27,5 MB tải). Gốc: `libmlkit_google_ocr_pipeline.so`
   11 MB, `libbarhopper_v3.so` 4,9 MB (mobile_scanner), PDFium 6,6 MB, Flutter + `libapp.so` 26 MB. Thử:
   - mobile_scanner bản unbundled (`dev.steenbakker.mobile_scanner.useUnbundled=true` trong `android/gradle.properties`).
   - ML Kit nhận dạng chữ qua Google Play services (thin) thay bản gói sẵn.
   Điều kiện: máy không có Play services (APK GitHub, F-Droid sau này) phải báo lỗi rõ, không sập; đo lại bằng cách
   tải APK và cộng `lib/<abi>` + phần không phải lib (cách đo trong phiên `qulythuchi-08`). Cần ADR nếu đổi.
3. **Nâng Flutter 3.47.8 ⇒ 3.50.1 (Dart 3.13.7 ⇒ 3.14.0)** - ưu tiên CAO, làm ĐẦU phiên sau. Kế hoạch đầy đủ: mục 5.
4. **Đo khởi động desktop** (≤ 1 giây tới cửa sổ dùng được): thêm bước đo trong job `desktop-ocr` hoặc đo tay trên
   bản 2403; ghi B.4.
5. **QR vai XÁC NHẬN** (app quét QR ở `/login` của PC): vẫn CHỜ QR2b phía tsudev.
6. Sau mỗi tính năng có trong app cài đặt: cắt thẻ beta mới, theo dõi VirusTotal.

## 2. Việc chờ 👤 - và agent làm gì khi 👤 báo kết quả

| Việc 👤 | Hướng dẫn | Khi 👤 báo ĐẠT | Khi 👤 báo LỖI |
| --- | --- | --- | --- |
| **Mới**: thử "Quét để đăng nhập" trên điện thoại | APK `v26.11.2403-beta.1` ⇒ màn chào/Tài khoản ⇒ Quét để đăng nhập ⇒ quét QR ở tsudev.com | Ghi ADR-0023 + STATE | QR bị báo "không phải của tsudev" ⇒ thêm mẫu vào `qr_sign_in_test.dart`; trình duyệt không mở ⇒ kiểm `<queries>` Android/`LSApplicationQueriesSchemes` |
| Mua thử Pro + Ủng hộ trên điện thoại | `docs/store/google-play.md` bước 4b | Ghi google-play.md + STATE; nhắn phiên tsudev ghi QT5 mục 4 | Log Render `[play]`/`[rp]`, `wrangler tail`, sửa, test, deploy |
| Nghiệm thu P9 ví chung (2 tài khoản, 2 thiết bị) | `logs/handover/20261119-03_p9-xong.md` mục 2b | Đánh dấu P9 trong STATE | Tái hiện bằng test `p9_*`, sửa, phiếu rà soát |
| Nghiệm thu P7b ảnh hoá đơn | `logs/handover/20261120-03_p7b-tep-dinh-kem-xong.md` mục 2b | Đánh dấu P7b | Như trên (`p7b_*`) |
| Thử Quét hóa đơn trên máy tính bằng ảnh thật (bản 2403) | Tự nhập ⇒ Quét hóa đơn ⇒ chọn ảnh | Ghi số đo vào ADR-0021 mục 5 | Windows "chưa có bộ nhận dạng" ⇒ hướng dẫn thêm ngôn ngữ OCR; đọc sai tổng ⇒ thêm mẫu vào test `receipt` |
| (Tuỳ chọn) Gửi thư Cynet | `docs/store/antivirus.md` mục 2 | - | - |
| Bật `PRO_ENFORCE=on` + đồng ý xoá dữ liệu thử nghiệm | ADR-0016/0018 | Đặt biến Worker, deploy, kiểm 402 | - |

Agent KHÔNG tự đăng nhập tài khoản Google/tsudev của 👤, không gõ/đọc mật khẩu, không "nghiệm thu thay".

## 3. Khi 👤 nghiệm thu xong P9 + P7b + mua Pro

Như phiếu `20261124-01` mục 3: bản chính thức `vYY.M.DDNN` ⇒ kênh gói (`docs/RELEASE.md` mục 6) ⇒ AAB Thử nghiệm kín
12 người × 14 ngày ⇒ trang Tải về "Dùng được ngay".

## 4. Bẫy mới

- **Tắt máy đột ngột (WSL) làm rỗng tệp đang ghi**: phiên `qulythuchi-08` gặp 5 object git rỗng, `refs/stash` rỗng
  (`warning: ignoring broken ref refs/stash`, `git stash` hỏng im lặng), tệp tracked rỗng và 4251 tệp
  `apps/site/node_modules` rỗng (`ERR_INVALID_PACKAGE_CONFIG` ở `sharp`). Đầu phiên sau sự cố: `git fsck --no-dangling`
  + `find . -type f -size 0 -newermt '<giờ tắt máy - 30 phút>'`. Sửa: chuyển object rỗng ra ngoài, `git fetch`, fsck
  lại; `npx -y npm@11.21.2 ci` cho thư mục node_modules hỏng.
- Job macOS có thể "not acquired by Runner ... after multiple attempts" (15 phút, không có log) ⇒ không phải lỗi mã,
  `gh run rerun <id> --failed`.
- `/auth/web/start` nằm ở gốc, KHÔNG dưới `/api/v1` (đo nhầm sẽ ra 404).

## 5. Kế hoạch nâng Flutter (bổ sung 24/11/2026 theo yêu cầu của chủ dự án)

**Lý do.** `sodium` 4.1.5+1 (lõi + app) và `pdfrx` 3.1.0 (+ `pdfrx_engine` 0.9.6, `pdfium_*` 0.4.4) đòi Dart SDK
^3.14.0 ⇒ dependabot #84/#85 đỏ, đã đóng. ADR-0020 mục 1 cũng ghim `pdfrx` 3.0.0 chỉ vì lý do này.

**Bản đích** (đo từ `releases_linux.json` của Flutter, 24/11/2026):

| Flutter | Dart | Commit | Ngày |
| --- | --- | --- | --- |
| 3.47.8 (đang ghim) | 3.13.7 | `737ba8f885dc774b53b442759999a312c9461e4e` | 23/10/2026 |
| **3.50.1 (đích)** | **3.14.0** | `ae9b586f34a8443573f82ef57c3bf914a908cbf7` | 20/11/2026 |

Đầu phiên đo lại: có 3.50.2+ thì lấy bản vá mới nhất của 3.50 (đối chiếu `hash` trong
`https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`, KHÔNG tin số commit trong phiếu
nếu đã có bản mới hơn).

**Chỗ phải đổi - MỘT PR duy nhất, nhánh `chore/flutter-3.50`** (đổi lẻ ⇒ CI ghim lệch ⇒ đỏ):

| Tệp | Đổi |
| --- | --- |
| `.github/workflows/ci.yml` dòng 11-12 | `FLUTTER_VERSION`, `FLUTTER_COMMIT` (5 job dùng chung: core, app, desktop-ocr, android) |
| `.github/workflows/release.yml` dòng 25-26 | như trên (bản phát hành phải dựng cùng Flutter với CI) |
| `.github/workflows/apple.yml` dòng 45-46 | như trên |
| `packages/core/pubspec.yaml`, `apps/app/pubspec.yaml` | `environment.sdk: ^3.14.0`; `sodium: ^4.1.5+1` |
| `apps/app/pubspec.yaml` dòng 71 | `pdfrx: 3.1.0` (vẫn ghim ĐÚNG phiên bản như ADR-0020) |
| `pubspec.lock` (lõi + app) | `dart pub get` / `flutter pub upgrade` (kéo luôn 7 gói "upgradable" đang khoá) |
| AGENTS.md B.2, `CONTRIBUTING.md` dòng 13 | "Flutter 3.50.1" |
| ADR-0020 mục 1 | KHÔNG sửa ADR đã chấp nhận ⇒ ghi bổ sung cuối ADR (mục "Cập nhật") hoặc ADR mới nếu cách nạp PDFium đổi |
| `CHANGELOG.md` | mục chưa phát hành: nâng Flutter/Dart, sodium, pdfrx |

`qr` 3.0.3 ⇒ 4.0.1 là bản MAJOR: KHÔNG gộp vào PR này (để dependabot riêng).

**Các bước:**

1. Máy dev: giữ bản cũ làm dự phòng `mv ~/tools/flutter ~/tools/flutter-3.47.8`, rồi
   `git clone --depth 1 -b 3.50.1 https://github.com/flutter/flutter.git ~/tools/flutter`, kiểm `git rev-parse HEAD`
   khớp commit, `flutter --version` báo Dart 3.14.0. Linux cần clang (bẫy mục 4 phiếu 20261124-02:
   `~/.cache/lotus-tmp/clang`, xuất `PATH` + `LD_LIBRARY_PATH`).
2. Lõi: `cd packages/core && dart pub get && dart format lib test tool && dart analyze --fatal-infos && dart test`.
   Đổi `sdk` ⇒ đổi language version ⇒ **`dart format` có thể định dạng lại nhiều tệp**: commit riêng trong cùng PR
   ("style: dart format theo Dart 3.14") để dễ duyệt. Lint mới/deprecation ⇒ sửa, không tắt lint.
3. **Mật mã (D3)**: `sodium` 4.1.2+1 ⇒ 4.1.5+1 là bản vá nhưng đụng lớp gọi libsodium ⇒ BẮT BUỘC: chạy bước "Vector đối
   chiếu khớp mã nguồn" (`conformance/`) cục bộ - phải khớp, KHÔNG sinh lại vector (sinh lại = che lỗi); đọc changelog
   `libsodium_dart_bindings` 4.1.3-4.1.5; phiếu rà soát `docs/security-reviews/2026112x-nang-flutter-sodium.md` theo
   `.standards/docs/templates/SECURITY_REVIEW.md`. Web: `tool/fetch_web_assets.sh` (sodium.js có checksum) - kiểm bản
   `sodium` mới có đòi sodium.js khác không; đổi thì cập nhật checksum.
4. App: `cd apps/app && flutter pub upgrade && flutter gen-l10n && dart run tool/gen_tokens.dart && flutter analyze &&
   flutter test` (mốc: 159+ test đạt như phiên 07). Kiểm cây sạch sau sinh mã (cổng CI "cây sạch sau build").
5. **pdfrx 3.1.0**: ghi chú phát hành nói có PDFium dựng sẵn (xcframework) cho iOS/macOS ⇒ đọc kỹ: Podfile/SPM có
   đổi không, `apple.yml` kiểm gói `.app` có thêm framework không. Chạy test khứ hồi PDF (60 dòng, 3 trang) + job
   `desktop-ocr` cả 3 OS. Windows: xem `pdfrx_pdfium_gate.dll` có đổi không (bản mới ⇒ băm mới ⇒ có thể bị AhnLab gắn
   cờ lại - theo dõi VirusTotal bản beta kế tiếp, `docs/store/antivirus.md`).
6. Web: `./scripts/build-web.sh` ⇒ đo lại `main.dart.js`/`canvaskit.wasm` gzip (AGENTS.md B.4) ⇒ chạy cục bộ
   `/app/` + Playwright Sáng/Tối 0 lỗi console; luồng nhập PDF trên web (`pdfium.wasm`, CSP `blob:`).
7. PR ⇒ CI đủ: core, app, desktop-ocr ×3, Android, Apple (iOS Simulator + macOS ad-hoc). Job macOS "not acquired by
   Runner" ⇒ `gh run rerun --failed` (không phải lỗi mã). Android đỏ vì Gradle tải mạng ⇒ rerun. AGP/Gradle/Kotlin tối
   thiểu có thể tăng theo Flutter 3.50 ⇒ đọc cảnh báo `flutter build apk`, sửa `android/settings.gradle(.kts)` nếu cần.
8. Gộp ⇒ deploy (`build-web.sh` + `npm run deploy`, kiểm khói như mục 0) ⇒ cắt `v26.11.DDNN-beta.1` ⇒ theo dõi
   VirusTotal + kiểm APK/zip/deb chạy được ⇒ ghi STATE.
9. Dependabot sẽ mở lại PR pub (#84/#85 đã đóng) ⇒ đóng nếu trùng với PR này.

**Dừng & hỏi 👤 nếu:** vector `conformance/` không khớp sau khi nâng `sodium`; định dạng phong bì/AAD phải đổi; hoặc
pdfrx 3.1.0 buộc đổi cách đóng gói PDFium trên Windows (ảnh hưởng cờ antivirus vừa gỡ).

**Quay lui:** revert PR; máy dev `mv ~/tools/flutter-3.47.8 ~/tools/flutter`.
