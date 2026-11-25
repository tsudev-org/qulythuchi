# PHIẾU BÀN GIAO 20261125-03 - Việc cho phiên sau (sau phiên `qulythuchi-11`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-11`, AKB `SES-20261125-1124-2cfb`), 25/11/2026
- **Trạng thái**: MỞ. Thay phiếu `20261125-02` (ĐÓNG). Bảng việc chờ 👤 vẫn ở phiếu `20261124-03` mục 2.

## 0. Hiện trạng (25/11/2026, chiều)

- Mọi PR của phiên 09-11 đã gộp: #89, #96 (= nội dung #90), #92, #93 (+#94 v6.0.0), #95, #91, #97. Không còn PR mở.
- **#90 gộp nhầm** vào nhánh `fix/sodium-macos-posix-spawn` (gộp 2 giây sau #89, GitHub chưa kịp đổi đích) ⇒ cherry-pick
  sang #96. Bài học AKB `LES-20261125-1143-8975`: PR chồng phải chờ đích thành `main` rồi mới gộp.
- **Beta `v26.11.2501-beta.1`** (bản đầu trên Flutter 3.50.1 + pdfrx 3.1.0 + bảng màu v6.0.0): đủ Windows/macOS/Linux/
  APK, ký Sigstore + SLSA + SBOM, VirusTotal đạt, Pre-release đã công bố.
- **Production `deploy-2026.11.25.2`**: `/`, `/app/`, `/tai-ve/`, `/security/`, health, providers 200. Playwright: 5 trang ×
  360/768/1366 × Sáng/Tối 0 lỗi console, 0 tràn ngang, 0 tài nguyên ≥ 400; trang chủ tải lạnh 4G chậm (150 ms,
  1,6 Mbps, CPU ×4): **LCP 1,18 s, CLS 0** (24/11: 1,9 s / ≤ 0,053); `/app/` Sáng + Tối hiện màn chào ~4 s, 0 lỗi.
- Upstream libsodium_dart_bindings#245 vẫn MỞ (sodium 4.1.5+1) ⇒ giữ `third_party/sodium`.

## 1. Việc agent tự làm (theo thứ tự)

1. Theo dõi VirusTotal/AV của `v26.11.2501-beta.1` vài ngày (`docs/store/antivirus.md`; `pdfrx_pdfium_gate.dll` băm mới).
2. UI2 còn: (a) kiểm hệ số font dự phòng trên máy CÓ Arial (Windows/macOS thật hoặc CI `windows-latest` + Playwright) -
   WSL không có Arial/Arimo/Liberation; (b) `tsudev_ui` màn chào theo bảng Sáng v6.0.0 khi gói nâng.
3. `material_ui` khi `tsudev_ui` chuyển (phiếu tsudev-ui-flutter 20261125-MUI1): `dart fix --apply
   --code=migrate_design_widgets`, gỡ 76 dòng ignore + header `l10n.yaml`.
4. QR vai XÁC NHẬN (`TsuXdApprover`, `tsudev_ui` v0.5.0): kiểm QR2b phía tsudev.com trước.
5. Gỡ `third_party/sodium` khi #245 đóng + sodium có bản mới.

## 2. Việc chờ 👤

- Chọn phương án ngân sách APK (a)/(b)/(c) - phiếu 20261125-01 mục 1.4.
- Thử bản `v26.11.2501-beta.1` trên máy thật (đặc biệt macOS: bản đầu dựng bằng hook sodium vá tạm).
- Còn lại không đổi (phiếu 20261124-03 mục 2): mua thử Pro + Ủng hộ; nghiệm thu P9 + P7b; Quét hóa đơn desktop;
  "Quét để đăng nhập"; `PRO_ENFORCE=on`.

## 3. Bẫy mới

- PR chồng: xem mục 0 (kiểm `gh pr view N --json baseRefName` trước khi gộp).
- Playwright mượn từ repo khác lệch bản Chromium ⇒ `chromium.launch({ executablePath: '~/.cache/ms-playwright/
  chromium_headless_shell-1254/.../chrome-headless-shell' })`. Cổng 4329 đang do tiến trình khác giữ - dùng
  `python3 -m http.server <cổng> -d apps/site/dist`.
- `flutter build web` lần này 326 s (máy rảnh); dựng app trước, site sau bằng `./scripts/build-web.sh --bo-app`.
