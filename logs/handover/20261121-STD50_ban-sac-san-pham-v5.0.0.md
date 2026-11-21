# PHIẾU YÊU CẦU - Bản sắc riêng của Quly Thu Chi (tsudev-standards v5.0.0)

- **Mã phiếu**: 20261121-STD50
- **Từ**: phiên tsudev-standards, 21/11/2026 - **Đến**: phiên kế tiếp của `qulythuchi`
- **Trạng thái**: ĐANG LÀM - PR 1 xong mã (agent-qulythuchi 21/11/2026), PR 2 chưa
- **Nguồn**: https://github.com/tsudev-org/tsudev-standards/releases/tag/v5.0.0 - `docs/DESIGN_SYSTEM.md` mục 1.2,
  CHANGELOG 5.0.0 "Hướng dẫn nâng cấp"
- **Bối cảnh**: chủ dự án muốn mỗi sản phẩm có đặc trưng nổi bật riêng (màu, giao diện, bố cục). Trước v5.0.0, 9/11
  sản phẩm dùng cùng một màu xanh. Từ v5.0.0: nền/chữ/trạng thái/tiếp cận là chung; màu nhấn, bố cục, bo góc, hoạ
  tiết, font tiêu đề là riêng, khai ở `.standards/tokens/products/qulythuchi.json` - KHÔNG tự khai lại tại repo này.

## Bản sắc đã chốt cho `qulythuchi`

| Trường | Giá trị |
| --- | --- |
| `data-product` | `qulythuchi` |
| Màu chính Tối / Sáng | `#39BA81` / `#05794F` (hue OKLCH 160; lý do: xanh lục bảo của ví và mũi tên tăng) |
| Bố cục `layout` | `bang-dieu-khien` - thanh bên trái cố định + vùng làm việc + thẻ số liệu trên cùng |
| Bo góc `shape` | `mem` - 6/10/14px, nút 10px |
| Hoạ tiết `motif` | `cot-tang-truong` (tĩnh, ở hero + `og-image`, phủ ≤ 15%) |
| Font tiêu đề | Be Vietnam Pro (tự host woff2 bộ `vietnamese`, tối đa 2 độ đậm) |

Muốn đổi bất kỳ giá trị nào: PR vào tsudev-standards (sửa `hue`/`layout`... + chạy `gen-product-palette.mjs`), cổng
kiểm chống trùng phải xanh. KHÔNG ghi đè tại repo này.

## Việc cần làm - chia hai PR, mỗi PR một phiên

**PR 1 - màu + hình** (`feat(ui): bản sắc qulythuchi theo tsudev-standards v5.0.0`):
1. Sync `.standards/` lên v5.0.0 (bước `curl` sync-standards.sh trước, theo `docs/SYNC.md`).
2. Web: nạp `.standards/tokens/tokens.css` rồi `.standards/tokens/products.css`; `<html data-product="qulythuchi">` (cạnh
   `data-theme`). Desktop/di động: gộp đè `products/qulythuchi.json` lên `color.light`/`color.dark` lúc build.
3. Xoá bảng màu tự khai (`palette.css`, `extensions.*.json`, dải `--color-*` riêng) và mã màu cứng còn sót.
4. Giá trị đã lưu `warm` đọc thành `light` (khối `warm` đã gỡ khỏi token).
5. Nút dùng `var(--radius-control)`; h1-h3 và số liệu lớn dùng `var(--font-display)`.
6. Ảnh chụp trước/sau, Sáng + Tối, đính vào PR. Cổng kiểm + test xanh.

**PR 2 - bố cục** (`feat(ui): bố cục bang-dieu-khien + hoạ tiết cot-tang-truong`):
1. Dựng phần THÂN trang chủ website / màn hình đầu app theo `bang-dieu-khien`; header, khu tài khoản, chân trang, bộ chọn
   giao diện giữ theo `ECOSYSTEM_IDENTITY.md` mục 4.
2. Hoạ tiết `cot-tang-truong` tĩnh ở hero, vẽ bằng `accent`/`glow`; sinh lại `og-image.png` cùng hoạ tiết.
3. Ảnh chụp trước/sau, Sáng + Tối.

## Việc riêng của repo này

- Màu xanh lục bảo khớp logo ví (hue 160). Màu thu/chi trong biểu đồ vẫn dùng `success`/`danger` chung, không dùng `primary`.

## Kết quả xử lý

- **PR 1** (nhánh `feat/ban-sac-qulythuchi-v5`, agent-qulythuchi 21/11/2026):
  - `.standards` v5.0.0 (sync-standards.sh lấy lại từ tag v5.0.0 trước).
  - Website: nạp `.standards/tokens/tokens.css` + `products.css` trực tiếp từ `Trang.astro`, `<html data-theme
    data-product="qulythuchi">`, `<body data-platform="web">`; XOÁ `apps/site/src/styles/tokens.css` (bảng xanh trời tự
    khai); nút `var(--radius-control)`, thẻ/khối dùng `--radius-sm/md/lg`; h1-h3 `var(--font-display)`; `check-dist`
    đòi `data-product`. Thân bài website giữ Be Vietnam Pro tự host như tsudev.com (đã có 400/600/700 bộ vietnamese).
  - App: `tool/gen_tokens.dart` gộp đè `products/qulythuchi.json` lên `color.light/dark` + đọc bo góc bộ `mem` từ
    `products.css`, sinh `QtBrand` (font tiêu đề, layout, motif); nút `QtRadius.control`; `headlineMedium/Small`,
    `titleLarge` (h1-h3 + số tiền lớn) = Be Vietnam Pro 600/700 TTF đóng gói kèm + giấy phép OFL trong LicenseRegistry.
    Test `brand_tokens_test.dart`.
  - Mã màu cứng sót: web app `index.html`/`manifest.json` `#0F1B2D` ⇒ `#0A0A0A`; widget Android navy ⇒ nền chung.
  - Giữ: `design/tokens.qulythuchi.json` chỉ có màu biểu đồ dataviz (không trùng vai trò chuẩn); nút Google/GitHub giữ
    màu thương hiệu của họ; `warm` ⇒ `light` đã có sẵn (app + theme.js).
  - Ảnh: `logs/anh/20261121-STD50/pr1-*` (trước/sau, Sáng/Tối).
