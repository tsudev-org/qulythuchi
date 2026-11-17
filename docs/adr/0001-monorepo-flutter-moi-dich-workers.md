# ADR-0001: Monorepo, Flutter cho mọi đích (kể cả web), lõi Dart thuần, máy chủ Workers + D1 + R2

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi (chủ dự án duyệt hướng chung 17/11/2026)

## 1. Bối cảnh
Cần app Android/iOS/Windows/macOS/Linux + web, đồng bộ cùng tài khoản, 0 đồng. Logic tiền và mã hóa phải giống hệt
nhau ở mọi nơi - một lệch nhỏ là mất tiền hoặc không giải mã được.

## 2. Phương án
| Phương án | Ưu | Nhược |
| --- | --- | --- |
| A. Flutter app + web React riêng | web nhẹ, SEO tốt | logic tiền/mã hóa có 2 bản (Dart + TS) |
| B. Lõi Rust qua FFI + WASM | một bản lõi | 5 chuỗi công cụ gốc, CI rủi ro (xem sound-db ADR-0002); lõi không nặng tính toán |
| C. Flutter cho cả 6 đích, lõi Dart thuần, site giới thiệu Astro | một bản logic; một bộ UI | bản web nặng hơn (~2-4 MB), giải quyết bằng PWA + bộ nhớ đệm |

## 3. Quyết định
Chọn **C**. Máy chủ: Cloudflare Workers (Hono) + D1 + R2 + Email Workers - nằm trong `FREE_TIER_STACK.md`, đã chạy
được ở sound-db. Site giới thiệu Astro để SEO; web app Flutter phục vụ ở `/app`.

## 4. Hệ quả
- Web không có SQLCipher: CSDL web (sqlite3 WASM trên OPFS) chỉ chứa **bản ghi còn mã hóa**; giải mã vào bộ nhớ sau khi
  mở khóa, tự khóa khi rảnh. Ghi ở `AGENTS.md` B.4.
- Worker niêm phong email bằng TypeScript ⇒ định dạng phong bì có vector đối chiếu ở `conformance/`.

## 5. Đường lùi
Nếu bản web Flutter quá nặng cho người dùng: thêm web app React dùng lõi biên dịch `dart compile js/wasm` của
`packages/core` - vẫn một bản logic.
