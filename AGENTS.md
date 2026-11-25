# AGENTS.md - qulythuchi

> **ĐỌC FILE NÀY ĐẦU TIÊN trong mọi phiên làm việc mới.**

## Phần A - Quy ước chung của hệ sinh thái (KHÔNG SỬA Ở ĐÂY)

Toàn bộ quy ước chung nằm trong bản sao chỉ-đọc tại
[`.standards/AGENTS.md`](.standards/AGENTS.md). `MUST` đọc file đó trước.

Bản quy ước repo này đang dùng: xem [`.standards-version`](.standards-version).

| Cần gì | Đọc file nào |
| --- | --- |
| Điểm vào, nguyên tắc chung | `.standards/AGENTS.md` |
| Quy trình phiên, khóa file, bàn giao | `.standards/docs/AGENT_PROTOCOL.md` |
| Bảo mật bắt buộc | `.standards/docs/SECURITY_BASELINE.md` |
| Quy tắc `.gitignore` | `.standards/docs/GITIGNORE_POLICY.md` |
| Nhánh, commit, PR, phát hành | `.standards/docs/GIT_WORKFLOW.md` |
| Đăng nhập, đăng ký, xác minh tài khoản | `.standards/docs/AUTH_AND_ACCOUNT.md` |
| Giao diện và token | `.standards/docs/DESIGN_SYSTEM.md` |
| Bảng bản ghi, bộ chọn số bản ghi | `.standards/docs/DATA_TABLE.md` |
| Logo, favicon, icon ứng dụng | `.standards/docs/BRAND_ASSETS.md` |
| tsudev.com, ảnh đại diện, trang hồ sơ | `.standards/docs/ECOSYSTEM_IDENTITY.md` |
| Cấu trúc thư mục | `.standards/docs/PROJECT_STRUCTURE.md` |
| Chọn ngôn ngữ, framework | `.standards/docs/LANGUAGE_SELECTION.md` |
| Hạ tầng 0 đồng | `.standards/docs/FREE_TIER_STACK.md` |
| Trình soạn thảo nội dung | `.standards/docs/RICH_TEXT_EDITOR.md` |
| Tìm kiếm và lọc tiếng Việt | `.standards/docs/SEARCH_AND_FILTER.md` |
| Kiểm thử và chất lượng mã | `.standards/docs/TESTING_QUALITY.md` |
| Khả năng truy cập | `.standards/docs/ACCESSIBILITY.md` |

`MUST NOT` sửa bất kỳ file nào trong `.standards/`. Cần đổi quy ước thì mở đề
xuất tại repo `tsudev-standards` theo `.standards/docs/SYNC.md` mục 1.

## Phần B - Riêng của repo này

### B.1. Repo này là gì

- **Loại**: app di động + desktop + web app + website + dịch vụ (monorepo, hình trạng B của `PROJECT_STRUCTURE.md`)
- **Stack**: Dart thuần (`packages/core`), Flutter (`apps/app`, 6 đích kể cả web), TypeScript + Cloudflare Workers +
  Hono + D1 + R2 (`services/sync-api`), Astro (`apps/site`). Lý do: `docs/ARCHITECTURE.md`, `docs/adr/0001-*`.
- **Hạng xác thực**: B - app có kết nối; IdP tsudev.com (OIDC) qua máy chủ (ADR-0003).
- **Mức phân loại dữ liệu cao nhất**: **D3** (dữ liệu tài chính) - mọi thay đổi đụng mã hóa/đồng bộ/xác thực `MUST`
  có phiếu rà soát theo `.standards/docs/templates/SECURITY_REVIEW.md`.
- **Người liên hệ khi có sự cố**: chủ dự án tsudev (GitHub `tsudev-tsudev`).
- **Agent chính**: agent-qulythuchi. Kế hoạch theo phase: `docs/PLAN.md`.

### B.2. Chạy trong 5 phút

```bash
./scripts/check-standards.sh
export PATH="$HOME/tools/flutter/bin:$PATH"          # Flutter 3.50.1 (ghim trong CI)
(cd packages/core && dart test)                      # lõi
cd apps/app && flutter test && flutter run -d linux  # app (Linux cần clang, libsecret-1-dev, libgtk-3-dev)
./tool/fetch_web_assets.sh && flutter run -d chrome  # web: tải sodium.js + sqlite3.wasm có checksum
```

Sinh lại mã: `flutter gen-l10n` (chuỗi trong `lib/l10n/*.arb`), `dart run tool/gen_tokens.dart` (token thiết kế).

### B.3. Ranh giới sở hữu file

| Vùng | Chủ sở hữu | Ghi chú |
| --- | --- | --- |
| `packages/core` | agent-qulythuchi (lõi) | Đổi định dạng phong bì ⇒ tăng phiên bản + sinh lại `conformance/` CÙNG PR |
| `apps/app` | agent-qulythuchi (app) | |
| `services/sync-api` | agent-qulythuchi (máy chủ) | Migration D1 đã áp dụng là BẤT BIẾN |
| `apps/site` | agent-qulythuchi (web) | `public/` icon/favicon là sản phẩm SINH RA |
| `docs/adr` | agent-qulythuchi | ADR đã chấp nhận chỉ được thay bằng ADR mới |

### B.4. Điểm lệch chuẩn đã biết

| Lệch ở đâu | Vì sao | Kế hoạch |
| --- | --- | --- |
| Web không có SQLCipher | sqlite3 WASM không hỗ trợ | CSDL web chỉ chứa bản ghi còn mã hóa, giải mã trong bộ nhớ (ADR-0001 mục 4) |
| iOS chưa phát hành | Apple Developer tốn phí, chủ dự án hoãn | Mã iOS vẫn build trên CI; iPhone dùng PWA |
| Web app `/app/` vượt ngân sách JS ban đầu ≤ 170 KB gzip (LANGUAGE_SELECTION 5.1) | Flutter web: đo 25/11/2026 (Flutter 3.50.1, `gzip -9`) `main.dart.js` 1,88 MB gzip + `canvaskit.wasm` 2,93 MB gzip (24/11 trên 3.47.8: 1,81 + 2,85); website Astro 1,8 KB gzip (đạt) | Chấp nhận cho web app (PWA cho iPhone/máy không cài được); trang chủ/Tải về là Astro tĩnh. Website đo 24/11 (Playwright, 4G chậm 150 ms/1,6 Mbps, CPU ×4, 7 lần): LCP trung vị 1,9 s, CLS ≤ 0,053 (đạt). Khởi động desktop (CI 25/11, bản release tới khung hình đầu, `tool/do_khoi_dong.py`): chạy lại trung vị Windows 429 ms, macOS 323 ms, Linux 415 ms (đạt ≤ 1 s); lần chạy ĐẦU (tạo khóa + CSDL) 672 / 1 382 / 565 ms - macOS lần đầu vượt, chỉ một lần |
| APK mỗi ABI vượt ≤ 25 MB (LANGUAGE_SELECTION 5.1) | Đo 24/11/2026 trên `v26.11.2403-beta.1`: arm64 ~57 MB cài đặt (thư viện native lưu không nén), ~27,5 MB tải về nén; armv7 ~48 MB, x86_64 ~61 MB. Gốc: ML Kit OCR 11 MB, quét mã vạch 4,9 MB, PDFium 6,6 MB, Flutter 26 MB | Thử ML Kit/mobile_scanner bản "unbundled" (tải mô hình qua Google Play services, bớt ~16 MB) - phải giữ chạy được khi máy không có Play services |
| `// ignore: deprecated_member_use` trên từng dòng import `flutter/material.dart` / `GlobalMaterialLocalizations` (76 dòng) + `header` trong `apps/app/l10n.yaml` | Flutter 3.50 tách Material ra gói `material_ui` (bản sao, khác kiểu); `tsudev_ui` v0.4.0 còn trả kiểu `flutter/material` cho `ThemeData` ⇒ app chuyển một mình sẽ lỗi biên dịch | Phiếu `tsudev-ui-flutter` 20261125-MUI1; khi `tsudev_ui` lên `material_ui`: `dart fix --apply --code=migrate_design_widgets`, gỡ ignore + header, bọc `MaterialUiCompatibilityBridge` nếu còn gói cũ |
| Giấy phép AGPL-3.0 thay vì Apache-2.0 phổ biến trong hệ | Bảo đảm bản phái sinh của app tài chính E2EE luôn công khai mã | ADR-0005 |

### B.5. Việc riêng của repo cần biết trước khi sửa

- **Tiền là số nguyên** đơn vị nhỏ nhất + mã ISO 4217. Cấm `double`/`num` cho tiền ở mọi tầng.
- **Không tự chế mật mã.** Chỉ dùng hàm libsodium; mọi định dạng phong bì có số phiên bản và AAD (ADR-0002).
- **Không ghi dữ liệu D3 ra log**, thông báo lỗi, URL, analytics, báo cáo lỗi (Sentry/GlitchTip phải lọc).
- **Repo GitHub**: `tsudev-org/qulythuchi`. Chạy `gh api user -q .login` trước mọi lệnh gh/push.
