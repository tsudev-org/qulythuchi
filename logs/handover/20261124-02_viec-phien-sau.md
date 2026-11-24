# PHIẾU BÀN GIAO 20261124-02 - Việc cho phiên sau (sau phiên `qulythuchi-07`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-07`), 24/11/2026
- **Trạng thái**: MỞ. Thay phần "Việc agent tự làm" của phiếu `20261124-01` (phiếu đó giữ làm lịch sử; bảng mục 2 và
  mục 3 của nó VẪN DÙNG, chép lại dưới đây).
- **Đọc kèm**: `logs/STATE.md`, `docs/store/antivirus.md`, `logs/handover/20261124-QR1_dang-nhap-qr-ui1-dk2.md`,
  ADR-0021, ADR-0022.

## 0. Hiện trạng (24/11/2026, tối)

- Production `deploy-2026.11.24.2` (Worker `fa8d1759`): web app `/app/` có sửa UI1. `/`, `/app/`, health, `/tai-ve/`,
  providers 200; Playwright `/app/` Sáng + Tối 0 lỗi console.
- Đã gộp: #73 (UI1 + `.standards` v5.1.0 + cổng cây sạch sau build), #74 (OCR desktop, ADR-0021), #75 (widget + lối
  tắt iOS, ADR-0022), #76 (CHANGELOG).
- Releases: `v26.11.2401-beta.1` NHÁP (AhnLab-V3 + Cynet gắn cờ `pdfrx_pdfium_gate.dll`; quét lại 24/11 chiều vẫn cờ).
  `v26.11.2402-beta.1` NHÁP: AhnLab-V3 gắn cùng mã trên zip Windows (1/73); đủ 7 tệp + SHA256SUMS ký Sigstore (Release nháp: 👤 vẫn tải được để thử).

## 1. Việc agent tự làm (theo thứ tự)

1. **AhnLab** - đầu phiên `POST /api/v3/files/<sha256>/analyse` cho zip + DLL của cả `v26.11.2401-beta.1` và
   `v26.11.2402-beta.1` (khoá `~/.config/tsudev/virustotal.env` là KHOÁ THÔ một dòng - không `source`). Hết cờ ⇒ bỏ nháp
   (`gh release edit <thẻ> --draft=false`), ghi bảng. **Từ 01/12/2026** còn cờ ⇒ đánh giá bỏ `pdfrx_pdfium_gate.dll`
   khỏi gói Windows như phiếu `20261124-01` mục 1.1 (đọc mã `pdfium_dart`, dựng thử runner Windows, test nhập PDF trên
   Windows trước khi đổi).
2. **STD-SYNC phần còn lại** (tsudev-standards v5.1.0, gộp vào PR kế tiếp):
   - `knip` cho `services/sync-api` + `apps/site`: thêm devDependency GHIM phiên bản bằng `npx -y npm@11.21.2 install
     -D knip@<x.y.z>` rồi script `npm run knip` + bước CI. (Lệnh `npx -y knip@5` không ghim bị bộ phân loại quyền chặn
     trong phiên `qulythuchi-07` - đừng chạy lại kiểu đó.)
   - `ruff` (F401, F841) cho `conformance/*.py`, `scripts/*.py` trong CI.
   - Ngân sách tốc độ LANGUAGE_SELECTION 5.1: đo JS ban đầu (gzip) + LCP website; APK mỗi ABI (`--split-per-abi`);
     khởi động desktop. Flutter web `/app/` chắc chắn > 170 KB ⇒ ghi lệch chuẩn ở AGENTS.md B.4 kèm số đo. Tham khảo
     cách sound-db làm (sound-db PR #44, phiếu `sound-db/logs/handover/20261124-QR1_*`).
3. **tsudev_ui v0.3.0** (đã có tag): thay theme điều hướng tự viết trong `apps/app/lib/theme/app_theme.dart` bằng
   `tsuNavigationBarTheme`/`tsuNavigationRailTheme` + `tsuCompleteContainers`; giữ `test/theme_nav_contrast_test.dart`.
4. **QR3 - ĐÃ MỞ KHOÁ (ưu tiên cao, làm ngay sau mục 1)**: `tsudev_ui` **v0.4.0** có `TsuSignInScreen` (AUTH 13.2
   + ô đồng ý 13.4) và `TsuXdLink.parse`; tsudev.com production đã chạy đăng nhập QR (tsudev#374, `/api/xd` + `/x/<id>`).
   Chuẩn: CROSS_DEVICE_LOGIN v1.1.0 trong tsudev-standards **v5.3.0** (sync trong cùng PR). Cách làm (điều phối
   `projects-71`, 24/11):
   - Thay màn chào bằng `TsuSignInScreen`; giữ "Dùng ngay, không cần tài khoản" + "Khôi phục từ tệp sao lưu" qua `extra`.
   - "Quét để đăng nhập": bộ quét camera của app (vd. `mobile_scanner`, xin quyền lúc bấm) ⇒ `TsuXdLink.parse` ⇒ null
     thì báo "Mã QR này không phải của tsudev." ⇒ hợp lệ thì mở `link.uri` bằng trình duyệt hệ thống (Custom Tab);
     trang `/x/<id>` lo chờ Cho phép + gõ mã ⇒ rồi app bắt đầu OIDC như thường trong cùng trình duyệt ⇒ SSO trả mã ngay.
   - KHÔNG gửi khoá E2EE qua QR (chỉ phiên tài khoản; khoá vẫn qua mật khẩu/24 từ như cũ).
   - Vai XÁC NHẬN (app quét QR ở `/login` của PC): CHỜ QR2b, chưa làm.
   - Bắt buộc: phiếu rà soát (đụng xác thực), THREAT_MODEL, test, ảnh chụp Sáng/Tối. Chi tiết:
     `~/projects/logs/handover/20261124-QR1_*` mục 2. Mục 3 (nâng `tsudev_ui`) gộp luôn vào PR này.
5. **(Tuỳ chọn) OCR macOS**: in `supportedRecognitionLanguages()` trong job `desktop-ocr (macos)` để biết Vision có
   tiếng Việt chưa (ADR-0021 mục 5 còn "chưa đo").
6. Sau mỗi tính năng có trong app cài đặt: cắt thẻ beta mới, theo dõi VirusTotal.

## 2. Việc chờ 👤 - và agent làm gì khi 👤 báo kết quả

| Việc 👤 | Hướng dẫn | Khi 👤 báo ĐẠT | Khi 👤 báo LỖI |
| --- | --- | --- | --- |
| Mua thử Pro + Ủng hộ trên điện thoại | `docs/store/google-play.md` bước 4b | Ghi google-play.md + STATE; nhắn phiên tsudev ghi QT5 mục 4 | Log Render `[play]`/`[rp]`, `wrangler tail`, sửa, test, deploy |
| Nghiệm thu P9 ví chung (2 tài khoản, 2 thiết bị) | `logs/handover/20261119-03_p9-xong.md` mục 2b | Đánh dấu P9 trong STATE | Tái hiện bằng test `p9_*`, sửa, phiếu rà soát |
| Nghiệm thu P7b ảnh hoá đơn | `logs/handover/20261120-03_p7b-tep-dinh-kem-xong.md` mục 2b | Đánh dấu P7b | Như trên (`p7b_*`) |
| **Mới**: thử Quét hóa đơn trên máy tính bằng ảnh hóa đơn thật (Windows/macOS/Linux bản `v26.11.2402-beta.1`) | Tự nhập ⇒ Quét hóa đơn ⇒ chọn ảnh | Ghi số đo vào ADR-0021 mục 5 | Windows báo "chưa có bộ nhận dạng" ⇒ hướng dẫn thêm ngôn ngữ OCR; đọc sai tổng ⇒ thêm mẫu vào test `receipt` của lõi |
| (Tuỳ chọn) Gửi thư Cynet | `docs/store/antivirus.md` mục 2 | - | - |
| Bật `PRO_ENFORCE=on` + đồng ý xoá dữ liệu thử nghiệm | ADR-0016/0018 | Đặt biến Worker, deploy, kiểm 402 | - |

Agent KHÔNG tự đăng nhập tài khoản Google/tsudev của 👤, không gõ/đọc mật khẩu, không "nghiệm thu thay".

## 3. Khi 👤 nghiệm thu xong P9 + P7b + mua Pro

Như phiếu `20261124-01` mục 3: bản chính thức `vYY.M.DDNN` ⇒ kênh gói (`docs/RELEASE.md` mục 6) ⇒ AAB Thử nghiệm kín
12 người × 14 ngày ⇒ trang Tải về "Dùng được ngay".

## 4. Bẫy mới (chi tiết AKB `LES-20261124-1642-389a`, `LES-20261124-1642-0786`)

- Linux dev: clang cục bộ ở `~/.cache/lotus-tmp/clang` (LES lotus-share `20261121-1754-3444`), xuất `PATH` +
  `LD_LIBRARY_PATH` trước `flutter test`.
- Thêm phụ thuộc dev trong `pubspec.yaml` ⇒ `flutter pub get` trước `flutter analyze`.
- CI Android đỏ vì Gradle tải mạng ⇒ `gh run rerun --failed`. Repo không bật auto-merge.
- Web app: tự động hoá luồng "Dùng ngay" bằng Playwright vướng bước kiểm 24 từ khôi phục (phải chọn đúng từ thứ N).
