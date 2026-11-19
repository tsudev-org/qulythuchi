# PHIẾU TRAO ĐỔI - T3 đã gộp vào main (qulythuchi#20) trong lúc phiên P9a đang làm

- **Mã phiếu**: 20261119-T3-QT
- **Từ**: phiên điều phối `~/projects` (projects-d2), 19/11/2026
- **Đến**: phiên **qulythuchi-cc** (nhánh `feat/p9a-tien-ich`)
- **Trạng thái**: ĐÓNG (19/11/2026, qulythuchi-cc)

## 1. Đã gộp

`tsudev-org/qulythuchi#20` (`a024fb0`, worktree riêng, không đụng checkout `~/projects/qulythuchi`), phiếu toàn hệ
`~/projects/logs/handover/20261119-T3_*` (tsudev-standards PRODUCT_POLICY mục 1):

- `lib/theme/app_theme.dart`: `ThemeChoice.parse(null)` ⇒ `system` (trước: `dark`).
- `lib/state/settings.dart`: `AppSettings.theme` mặc định `system`; thêm `resolveAppLocale()` (vi/en, còn lại ⇒ **en**),
  `kDefaultsV2`, `migrateFirstRunDefaults()` (máy đã cài chưa từng chọn ⇒ ghi `theme=dark`, `locale=vi` nếu hệ thống
  không phải vi/en).
- `lib/app.dart`: `localeResolutionCallback: (device, _) => resolveAppLocale(device)`; nhắc hoá đơn dùng
  `resolveAppLocale(PlatformDispatcher.instance.locale)`.
- `lib/main.dart`: gọi `migrateFirstRunDefaults` sau `bootstrap()` (`_dbExisted`).
- `lib/ui/startup_error.dart`, `test/system_defaults_test.dart` (mới), `.standards/` v3.8.3.

## 2. Việc của phiên P9a

1. Rebase `feat/p9a-tien-ich` lên `origin/main` (nhánh đang sửa `lib/app.dart`, `lib/state/settings.dart` ⇒ có thể xung
   đột; giữ cả hai phần).
2. **Deploy web app CHƯA làm**: phiên điều phối đã định build ở checkout này nhưng phát hiện nhánh P9a + thay đổi chưa
   commit nên DỪNG trước khi biên dịch xong (không có gì lên production; `npm ci` đã chạy lại ở `apps/site` và
   `services/sync-api` với lockfile hiện có). Khi P9a gộp: `./scripts/build-web.sh` + `(cd services/sync-api && npm run
   deploy)` từ main sạch ⇒ production có luôn T3.
3. Ghi một dòng vào mục 3.

## 3. Kết quả xử lý

- 19/11/2026 - projects-d2: mở phiếu.
- 19/11/2026 - qulythuchi-cc: đã rebase `feat/p9a-tien-ich` lên `a024fb0` (không xung đột); deploy web chạy từ main sau
  khi P9a gộp (gồm luôn T3). Tin nhắn trả lời projects-d2 không gửi được (phiên đã thoát) ⇒ ghi tại đây.
- 19/11/2026 - qulythuchi-cc: P9a gộp (#21, `adf7374`); `build-web.sh` + deploy từ main sạch ⇒ production có T3 + P9a
  (Worker version `f14986a1`).
