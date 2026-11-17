# ADR-0008: Lưu trữ trong app (sqlite3 + SQLite3MultipleCiphers) và mở khóa nhanh bằng PIN/sinh trắc

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0001 mục 4 và ADR-0002, không thay thế)
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `apps/app/lib/data/*`, `apps/app/lib/security/vault.dart`, `docs/security-reviews/20261117-p2-app.md`

## 1. Bối cảnh
Phiếu bàn giao P2 đề xuất `drift` + `sqlcipher_flutter_libs` + `sodium_libs`. Khi cài đặt (17/11/2026):
`sqlcipher_flutter_libs` 0.7.0 đã EOL (không còn làm gì) và `sodium_libs` đã ngừng - cả hai được thay bằng build hook
của `sqlite3` 3.x và `sodium` 4.x. Lược đồ app chỉ có 3 bảng chứa byte đã niêm phong, không cần ORM sinh mã.

## 2. Quyết định
1. **CSDL**: dùng thẳng `package:sqlite3` 3.x (không `drift`). Trên máy: nguồn `sqlite3mc` (SQLite3MultipleCiphers,
   MIT, mặc định ChaCha20-Poly1305) chọn qua `hooks.user_defines` trong `pubspec.yaml`; khóa 32 B ngẫu nhiên ở kho bí
   mật của thiết bị (`qt.dbKey`), đặt bằng `PRAGMA hexkey`. Chọn sqlite3mc thay vì bản SQLCipher của gói vì không
   kéo OpenSSL và giấy phép đơn giản. Web: `sqlite3.wasm` thường + IndexedDB (đúng ADR-0001 mục 4).
2. **Bảng**: `meta(k, v)`, `wallet_keys(wallet_id, wrapped, dirty)`, `records(id, type, wallet_id, sealed, rev,
   dirty)`. Bản rõ chỉ tồn tại trong bộ nhớ sau khi mở khóa; khóa app ⇒ huỷ khóa và bỏ dữ liệu đã giải mã.
   Bản ghi cấp tài khoản (danh mục) mã hóa bằng "khóa tài khoản" ngẫu nhiên bọc bởi khóa chủ (ngữ cảnh `wk|account`),
   không dùng thẳng khóa chủ.
3. **libsodium**: `sodium` 4.x trực tiếp; web dùng `sodium.js` sumo 0.8.4 tự phục vụ, tải lúc build bởi
   `apps/app/tool/fetch_web_assets.sh` (sha512 do gói kiểm + sha256 ghim), không CDN lúc chạy.
4. **Mở nhanh (chỉ nơi có kho bí mật: Android/iOS/macOS/Windows/Linux)**:
   - PIN 6-12 số: `meta.pinWrap` = phong bì(khóa chủ, KEK = BLAKE2b-keyed(khóa thiết bị, Argon2id(PIN, 2 lượt/19 MiB)))
     ⇒ cần CẢ khóa thiết bị trong Keystore/Keychain lẫn PIN; trộm tệp CSDL không dò PIN ngoại tuyến được.
   - Sai PIN: 5 lần đầu tự do, sau đó chờ 30 giây nhân đôi (tối đa 1 giờ); lần thứ 10 xóa bản bọc PIN/sinh trắc.
     Bộ đếm tăng TRƯỚC khi thử và lưu ở kho bí mật.
   - Sinh trắc (tùy chọn, cần PIN): `meta.bioWrap` = phong bì(khóa chủ, khóa thiết bị); chỉ mở sau khi `local_auth`
     thành công. Đây là cổng giao diện, không phải ràng buộc phần cứng - rủi ro chấp nhận, xem phiếu rà soát.
   - Web không có PIN/sinh trắc (trình duyệt không có kho bí mật an toàn): chỉ mật khẩu hoặc 24 từ.
5. **Bảo vệ màn hình**: Android `FLAG_SECURE`; iOS lớp mờ khi `UIScene` mất tiêu điểm; Flutter che nội dung khi app
   `inactive`; tự khóa khi ở nền ≥ 60 giây. Android tắt sao lưu đám mây/chuyển thiết bị cho dữ liệu app.

## 3. Hệ quả
- Đổi bố cục bảng ⇒ tăng `RecordStore.schemaVersion` + migration (không sửa migration cũ).
- Đổi cách bọc PIN/sinh trắc ⇒ ADR mới; bản bọc cũ có thể xóa an toàn (người dùng đặt lại PIN).
- Khi cập nhật gói `sqlite3`/`sodium` phải cập nhật checksum trong `fetch_web_assets.sh` (script tự báo lệch phiên bản).
- Đo thời gian Argon2id 64 MiB trên điện thoại thật ở P10; hiện chạy trên luồng giao diện kèm vòng quay (~0,5-2 giây).
