# ADR-0013: Web + site P8 - một Worker phục vụ site Astro, web app Flutter ở /app/ và API

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 18/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `apps/site/**`, `apps/app/web/{index.html,flutter_bootstrap.js}`, `services/sync-api/wrangler.jsonc`,
  `scripts/build-web.sh`, `assets/brand/**`, `docs/security-reviews/20261118-p8-web-site.md`; bổ sung ADR-0001, 0003, 0010

## 1. Bối cảnh
P8 cần trang giới thiệu, trang tải về, trang bảo mật/quyền riêng tư và bản web (PWA) của app. Máy chủ đồng bộ đã chạy
ở `qulythuchi.tsudev.com` (Worker `qulythuchi`), phiên web dùng cookie `__Host-qt_session` cùng gốc (ADR-0003, 0011).

## 2. Quyết định
1. **Một Worker, một tên miền**: Worker `qulythuchi` thêm Workers Static Assets trỏ `apps/site/dist`;
   `run_worker_first` chỉ `/api/*`, `/auth/*`. Mọi đường khác là tệp tĩnh (không tính lượt gọi Worker, gói 0 đồng).
   Cùng khung với sounddb.tsudev.com. Web app cùng gốc với API ⇒ cookie `__Host-`, không CORS, CSP `connect-src 'self'`.
2. **Site Astro tĩnh** `apps/site`: `/`, `/tinh-nang/`, `/bao-mat/`, `/tai-ve/`, 404, sitemap; bảng màu đen + tím
   (ECOSYSTEM_IDENTITY mục 4.2), bộ chọn giao diện `tsudev-theme`, không script/CSS nội tuyến. Trang `/bao-mat/` BỔ
   SUNG (không thay) chính sách riêng tư chung của tsudev.com và nói rõ phần riêng: máy chủ thấy gì, ngoại lệ email,
   quyền thông báo/máy ảnh/micro, ML Kit gửi số liệu sử dụng ẩn danh.
3. **Web app ở `/app/`**: `flutter build web --release --base-href /app/ --csp --no-web-resources-cdn` (không mã động,
   CanvasKit tự phục vụ), gom vào `dist/app/` bởi `apps/site/scripts/gom-app.mjs` (không gom service worker, source
   map, bảng ký hiệu). `web/flutter_bootstrap.js` riêng KHÔNG đăng ký service worker (Flutter đã ngừng hỗ trợ; bản
   offline-first làm người dùng kẹt ở bản cũ). `/app/*` trả `Cache-Control: no-cache` (tệp Flutter không băm tên).
4. **Hai CSP**: site dùng CSP chặt ở `_headers` (`script-src 'self'`, không `unsafe-*`). App cần
   `'wasm-unsafe-eval'` (CanvasKit, sqlite3, libsodium) và `style-src 'unsafe-inline'` (engine chèn `<style>`), nên
   `_headers` GỠ CSP chung ở `/app/*` (`! Content-Security-Policy`) và app đặt CSP bằng `<meta>` trong `index.html`.
   Hai header CSP chồng nhau sẽ bị trình duyệt áp cả hai. `frame-ancestors` không đặt được bằng `<meta>` ⇒
   `X-Frame-Options: DENY` từ header chung vẫn áp.
5. **Dây chuyền thương hiệu** `apps/site/scripts/brand-assets.mjs` (chép từ sound-db): một ảnh gốc
   `assets/brand/source/logo-tsudev.png` (logo tsudev chính thức, chưa có logo riêng - AGENTS.md B.4) sinh favicon,
   icon PWA, og-image cho site và icon web của app; CI chạy `--check`. Icon app gốc (Android/iOS/desktop) sinh ở P10.
6. **Deploy**: `./scripts/build-web.sh` rồi `cd services/sync-api && npm run deploy`; `scripts/kiem-tinh.mjs` chặn
   deploy khi thiếu site hoặc `/app/` (deploy thiếu sẽ xóa chúng khỏi production).

## 3. Phương án đã loại
- Cloudflare Pages riêng cho site: cần CNAME tay, khác gốc với API ⇒ mất cookie `__Host-` cùng gốc.
- Worker đặt CSP cho `/app/*` (chạy Worker cho mọi tệp app): tốn lượt gọi; `<meta>` đủ cho trang HTML duy nhất.
- Bản wasm (`--wasm`, skwasm): cần header COOP/COEP cho đa luồng và trình duyệt hỗ trợ WasmGC; để sau.

## 4. Hệ quả
- Đổi cờ build web phải đổi cả `scripts/build-web.sh` và CI; `gom-app.mjs` kiểm base href, CSP `<meta>`, CanvasKit
  tự phục vụ.
- Thiếu glyph ngoài phông Inter ⇒ Flutter thử tải phông dự phòng từ gstatic và bị CSP chặn (hiện ô trống) - chấp nhận,
  Inter phủ tiếng Việt.
