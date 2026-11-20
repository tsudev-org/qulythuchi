# 20261120-LG1 - qulythuchi: logo riêng Quly Thu Chi cho website, app và mọi tệp xuất

- **Người lập**: phiên `tsuswico-57`, 20/11/2026, theo yêu cầu trực tiếp của chủ dự án.
- **Người làm**: phiên qulythuchi. **Trạng thái**: ĐÓNG (20/11/2026, phiên `qulythuchi-14`, PR #41).
- **Chuẩn**: `.standards/docs/BRAND_ASSETS.md` mục 12, **15** (logo sản phẩm riêng - chủ dự án duyệt), 15.5 (khối nhà
  làm giữ logo tsudev), `ECOSYSTEM_IDENTITY.md`.
- **Phiếu liên quan**: tsudev `20261120-LG1` (danh bạ tsudev.com/apps lấy logo từ website của bạn - mục 2 bước 6).

## 1. Ảnh gốc chủ dự án giao

- Tệp: `~/projects/qulythuchi/logo-qulythuchi.png` (đang nằm ở GỐC repo, chưa track) - PNG 1024x1024, ví + mũi tên
  tăng trưởng xanh lá/navy trên **nền trắng**.
- SHA-256: `164b08a7e31c41542babaec7fbdba4573b8a6b85a76e08fc09dcf282f819f0d2`
- Duyệt: chủ dự án giao 20/11/2026 (yêu cầu "cập nhật/bổ sung logo/favicon trên website và phần mềm") - đủ điều kiện
  mục 15. Ghi vào `AGENTS.md` B.4 (dòng "Logo: dùng logo tsudev chung" ⇒ đổi).

## 2. Việc phải làm

1. `git mv`/chuyển ảnh vào `assets/brand/source/logo-qulythuchi.png` (KHÔNG để ở gốc repo); ghi SHA-256 trong tài liệu
   brand của repo.
2. `assets/brand/brand.json`: `source` ⇒ tệp mới, `mode: "no-white"` (nền trắng nối liền mép - flood fill, giữ nét
   trắng bên trong logo), chỉnh `solidBg` (apple-touch/maskable) và chữ OG theo sản phẩm; sửa `_ghi_chu`.
3. Chạy `npm --prefix apps/site run brand` ⇒ favicon 7 lớp, PNG, PWA + maskable, apple-touch, og-image, logo
   `<picture>`; CI `--check` xanh.
4. **Website `apps/site`**: header = logo Quly Thu Chi + tên (như swico.tsudev.com); footer giữ khối nhà làm logo
   tsudev hiện hành dẫn tsudev.com.
5. **App `apps/app` (Flutter)**: icon launcher Android/Windows/Linux (và bản web `/app/` - favicon, manifest), logo
   trong giao diện (màn chào, header, giới thiệu), sinh từ CÙNG ảnh gốc qua dây chuyền - không cắt tay. Mọi tệp app
   xuất ra (báo cáo PDF/HTML/ảnh nếu có): logo + favicon sản phẩm nhúng thẳng, chân trang nhà làm tsudev. Mẫu nhúng
   ảnh vào báo cáo: tsuswico PR [#59](https://github.com/tsudev-org/tsuswico/pull/59).
6. Sau khi deploy: báo phiên `tsudev` URL `https://qulythuchi.tsudev.com/brand/logo-qulythuchi.png` (mục 15.6) để
   danh bạ tsudev.com/apps đổi từ ô màu + glyph sang logo thật.
7. Kiểm: axe sáng/tối, ảnh chụp, `--check`, chạy thử app.

## 3. Kết quả

- PR [#41](https://github.com/tsudev-org/qulythuchi/pull/41) gộp `c7b6b57`; production thẻ `deploy-2026.11.20.2`.
- Ảnh gốc ở `assets/brand/source/logo-qulythuchi.png`, SHA-256 khớp `164b08a7…f0d2`, ghi trong `assets/brand/README.md`.
- `brand.json`: `mode: "no-white"` + **`iconTile: true`** - navy `#122545` của logo gần như chìm trên nền Tối khi để
  trong suốt, nên mọi bản icon (favicon, logo header, .ico, PNG Linux, logo trong app, OG) đặt trên ô trắng bo góc.
  Bản nền đặc (apple-touch, maskable, iOS, macOS, Android adaptive) dùng ảnh trong suốt + `solidBg` trắng.
- Dây chuyền sinh thêm icon app gốc: Android mipmap cũ + adaptive + monochrome, iOS AppIcon (không alpha), macOS AppIcon
  (lưới Big Sur), Windows `app_icon.ico`, bộ đóng gói `assets/brand/app/` (.ico, .icns, PNG Linux), apple-touch `/app/`.
  `--check` canh 82 tệp, CI xanh.
- App: logo trên mọi màn xác thực + lớp che đa nhiệm; Cài đặt > Giới thiệu có logo + khối nhà làm TsuDEV (tsudev.com);
  icon cửa sổ Linux. PDF xuất: logo sản phẩm đầu trang, logo tsudev + tsudev.com chân trang (test `export_pdf_test`).
  CSV/XLSX là dữ liệu thô, không gắn logo.
- Website: header logo + tên, footer giữ khối nhà làm tsudev. `AGENTS.md` B.4 bỏ dòng lệch logo.
- Kiểm: flutter analyze sạch, flutter test 133 đạt, check-standards, brand --check, CI 13/13 xanh gồm iOS + macOS (ảnh
  chụp màn chào có logo, Dock macOS hiện icon mới); ảnh Sáng/Tối ở `docs/screenshots/lg1-logo/`.
- Production: `/`, `/app/`, `/api/v1/health`, `/brand/logo-qulythuchi.png` đều 200; logo phục vụ khớp byte tệp sinh ra.
- Mục 6: đã nhắn phiên `tsudev-8d` URL `https://qulythuchi.tsudev.com/brand/logo-qulythuchi.png` (20:28 20/11/2026).
