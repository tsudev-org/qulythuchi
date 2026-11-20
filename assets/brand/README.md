# Tài sản thương hiệu Quly Thu Chi

Chuẩn: `.standards/docs/BRAND_ASSETS.md` mục 12 và **15** (logo sản phẩm riêng). Phiếu: `logs/handover/20261120-LG1_*`.

## Ảnh gốc (một tệp duy nhất)

| Tệp | Vai trò | Kích thước | SHA-256 |
| --- | --- | --- | --- |
| `source/logo-qulythuchi.png` | Logo sản phẩm, chủ dự án duyệt 20/11/2026 | 1024x1024, nền trắng | `164b08a7e31c41542babaec7fbdba4573b8a6b85a76e08fc09dcf282f819f0d2` |
| `source/logo-tsudev.png` | Logo tsudev chính thức - CHỈ cho khối nhà làm (mục 15.5) | | `2ad933bd...77ba` (bản gốc ở repo tsudev) |

## Sinh lại

```bash
npm --prefix apps/site run brand            # ghi mọi bản
node apps/site/scripts/brand-assets.mjs --check   # CI: bắt tệp đã commit lệch ảnh gốc
```

Cấu hình: `brand.json`. `mode: "no-white"` xoá nền trắng NỐI LIỀN mép (flood fill); `iconTile: true` đặt logo trên ô
nền đặc `solidBg` bo góc cho mọi bản "icon", vì navy `#122545` của logo chìm trên nền Tối.

`MUST NOT` sửa tay bất kỳ tệp sinh ra nào dưới đây - đổi logo = thay ảnh ở `source/` + chạy lại lệnh.

| Nơi | Tệp sinh ra |
| --- | --- |
| `apps/site/public/` | `favicon.ico` 7 lớp, `favicon-{16,32,96}`, `android-chrome-*` + maskable, `apple-touch-icon`, `og-image`, `brand/logo-*` (`<picture>` AVIF/WebP/PNG) |
| `apps/app/web/` | `favicon.png`, `apple-touch-icon.png`, `icons/Icon-*` + maskable (web app `/app/`) |
| `apps/app/android/.../res/` | `mipmap-*/ic_launcher*.png` (cũ + adaptive + monochrome), `mipmap-anydpi-v26/ic_launcher.xml`, `values/ic_launcher_background.xml` |
| `apps/app/ios/`, `apps/app/macos/` | `AppIcon.appiconset/*.png` (iOS nền đặc không alpha; macOS ô bo góc lưới Big Sur) |
| `apps/app/windows/runner/resources/` | `app_icon.ico` |
| `apps/app/assets/brand/` | `logo-qulythuchi-256.png` (giao diện, PDF xuất, icon cửa sổ Linux), `logo-tsudev-128.png` (khối nhà làm) |
| `assets/brand/app/` | Bộ đóng gói desktop: `qulythuchi.ico`, `qulythuchi.icns`, `linux/qulythuchi-<cỡ>.png` |

URL logo công khai cho danh bạ tsudev.com/apps (mục 15.6): `https://qulythuchi.tsudev.com/brand/logo-qulythuchi.png`.
