# Quly Thu Chi - app Flutter

App 6 đích (Android, iOS, Windows, macOS, Linux, web) của Quly Thu Chi. Hướng dẫn chạy: `AGENTS.md` mục B.2 ở gốc repo.
Kiến trúc lưu trữ và khóa: `docs/adr/0008-*`; rà soát bảo mật: `docs/security-reviews/20261117-p2-app.md`.

- `lib/data` - SQLite (sqlite3mc trên máy, WASM trên web), kho bí mật của thiết bị
- `lib/security` - kho khóa: mật khẩu, 24 từ, PIN, sinh trắc
- `lib/sync` - đồng bộ P6 (ADR-0011): `ApiClient`, ghim CA (`pinned_roots.g.dart` sinh bởi `tool/gen_pinned_roots.sh`),
  đăng nhập PKCE, `SyncEngine`. Kiểm đầu-cuối với máy chủ thật: `dart run tool/sync_smoke.dart [health|login]`
- `lib/state` - repository sổ sách (niêm phong/giải mã), Riverpod
- `lib/ui` - màn hình; `lib/theme` - token tsudev (`tokens.g.dart` sinh bởi `tool/gen_tokens.dart`)
- `lib/l10n` - chuỗi vi (mặc định) + en
