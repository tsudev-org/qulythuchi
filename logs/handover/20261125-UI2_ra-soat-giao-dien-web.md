# PHIẾU - UI2: rà quét sâu giao diện web + hiện đại hoá (qulythuchi)

- **Mã phiếu**: 20261125-UI2 (phiếu con của `~/projects/logs/handover/20261125-UI2_ra-soat-giao-dien-web-toan-he.md`)
- **Từ**: chủ dự án (25/11/2026), phát bởi phiên `tsudev-3e` - **Đến**: agent của repo `qulythuchi`
- **Trạng thái**: MỞ - đợt 1 (phần A + B.1) xong 25/11, còn đợt 2 (xem Kết quả)
- **Phạm vi**: A + B (thuộc hệ sinh thái TsuDEV)
- **Ủy quyền**: chủ dự án cho agent TỰ MỞ TRÌNH DUYỆT (Playwright/Chromium headless) để rà website của repo này.

## Việc cần làm

1. Đọc phiếu toàn hệ (đường dẫn ở trên) - mục 0 là ba nguyên nhân "trang nhúng khi Ctrl+F5" đã gặp ở tsudev.com; kiểm
   cả ba ở repo này TRƯỚC (fade-in ở màn đầu, font không preload/dự phòng lệch số đo, scroll-reveal ẩn trước khi đo).
2. Làm phần A (rà quét sâu bằng trình duyệt: quay khung hình tải lạnh, ảnh 3 khổ × Sáng/Tối, console/mạng, tiếng
   Việt, bàn phím, LCP/CLS/INP).
3. Làm phần B (hiện đại hoá) - thay đổi bảng màu/font CHUNG chờ bản phát hành tsudev-standards, không tự đổi hex.
4. Ghi từng lỗi + cách sửa vào mục Kết quả; sửa theo PR nhỏ; `akb new issue` cho lỗi tốn > 10 phút.

## Kết quả xử lý

- 25/11/2026 - tsudev-3e: mở phiếu.
- 25/11/2026 - agent-qulythuchi (phiên `qulythuchi-10`): phần A + B đợt 1. Công cụ: Playwright 1.65 (Chromium headless
  shell 1254), CDP tắt cache + 150 ms / 4 Mbps + `Page.startScreencast`; kịch bản `film.js`, `sweep.js`, `app-check.js`
  (scratchpad phiên, mô tả ở đây để chép lại). Rà production `deploy-2026.11.25.1`: 6 trang (`/`, `/tinh-nang/`,
  `/bao-mat/`, `/tai-ve/`, `/security/`, 404) × 360/768/1366 × Sáng/Tối + `/app/`.

  | # | Trang / khổ / chế độ | Lỗi | Nguyên nhân | Sửa |
  | --- | --- | --- | --- | --- |
  | 1 | Mọi trang, mọi khổ | Ctrl+F5: khung đầu vẽ font hệ thống, tiêu đề/đoạn văn đổi bề rộng, nút đổi cỡ (mục 0 nguyên nhân 2) | woff2 chỉ bắt đầu tải SAU khi CSS về; không có mặt chữ dự phòng chỉnh số đo | PR #92: preload 400+600 latin+vietnamese, `Be Vietnam Pro Fallback` (Arial/Arimo/Liberation Sans, 105,4%/102,4%), số liệu thẻ nét 600 |
  | 2 | `/` 360 px Sáng + Tối | Tràn ngang 45 px | `.bang-dieu-khien { grid-template-columns: 1fr }`: `1fr` có cận dưới min-content, dải mục `nowrap` ép cột | PR #92: `minmax(0, 1fr)` |
  | 3 | `/app/` mọi khổ | Nền đen trống 13-15 s (4 Mbps), cả ở chế độ Sáng rồi bật sang sáng | `index.html` chỉ có `background: #0A0A0A`, không màn chờ | PR #93: `splash.js` đặt `data-theme` theo `flutter.theme`/hệ thống, logo + vòng xoay + chữ, gỡ ở `flutter-first-frame` |
  | 4 | `/app/` màn chào | "Tài khoản tsudev (email)", "...không phải của tsudev." | Sai tên hiển thị (ECOSYSTEM_IDENTITY: `TsuDEV`) | PR #93 |
  | 5 | Phần B | Nền Sáng trắng phẳng | Bảng màu cũ (v5.3.0) | PR #94: sync tsudev-standards v6.0.0 (nền giấy `#EEF1F5`, bề mặt `#F8FAFC`), sinh lại `tokens.g.dart`, `theme.js`/`splash.js`/widget Android |

  Không có: fade-in màn đầu (nguyên nhân 1), scroll-reveal (nguyên nhân 3), lỗi console (trừ 404 chủ đích), ảnh vỡ,
  em-dash, ngày khác `DD/MM/YYYY`; Tab có `focus-visible` (viền 2 px). App `/app/` hiện tiếng Anh khi trình duyệt
  `en-US` - đúng thiết kế (vi/en theo máy). Cảnh báo `GL Driver Message ... ReadPixels` là GPU phần mềm của headless.

  Chưa làm / còn lại: (a) kiểm hệ số font dự phòng trên máy có Arial (máy dựng WSL không có Arial/Arimo/Liberation) -
  quay lại production sau deploy; (b) B.2 hoạ tiết header/footer, B.3 hoạ tiết nền thẻ theo thể loại + chuyển động icon
  khi rê (DESIGN_SYSTEM.md mục 5 v6.0.0) - làm đợt 2 sau khi #94 gộp; (c) Lighthouse đo lại sau deploy (24/11: LCP trung
  vị 1,9 s, CLS ≤ 0,053); (d) `tsudev_ui` (màn chào `TsuSignInScreen`) có bảng màu riêng - theo v6.0.0 khi gói nâng.
