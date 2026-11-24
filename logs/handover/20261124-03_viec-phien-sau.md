# PHIẾU BÀN GIAO 20261124-03 - Việc cho phiên sau (sau phiên `qulythuchi-08`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-08`), 24/11/2026
- **Trạng thái**: MỞ. Thay phiếu `20261124-02` (đã ĐÓNG; bảng mục 2 của nó chép lại dưới đây, có bổ sung).
- **Đọc kèm**: `logs/STATE.md`, AGENTS.md B.4, `docs/store/antivirus.md`, ADR-0021, ADR-0023.

## 0. Hiện trạng (24/11/2026, khuya)

- Production `deploy-2026.11.24.3` (Worker `db6c9687`): màn chào web app là `TsuSignInScreen` (QR3, PR #78).
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
3. **Nâng Flutter** lên bản stable có Dart ≥ 3.14 (ghim commit trong CI + `release.yml`, AGENTS.md B.2), rồi nâng
   `sodium` 4.1.5 + `pdfrx` 3.1.0 (bản 3.1.0 có pdfium dựng sẵn cho iOS/macOS - đọc ghi chú phát hành, chạy lại job
   `desktop-ocr` + test nhập PDF). `sodium` đụng mật mã (D3) ⇒ phiếu rà soát + `conformance/` vẫn khớp.
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
