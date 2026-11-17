# KIẾN TRÚC - Quly Thu Chi

## 1. Tổng quan

```
 ┌──────── Thiết bị (nguồn sự thật) ────────┐          ┌──── Cloudflare (chỉ thấy bản mã) ────┐
 │ apps/app (Flutter: Android, iOS, Win,     │  HTTPS   │ services/sync-api (Worker + Hono)    │
 │   macOS, Linux, Web/PWA)                  │ ───────► │  • RP OIDC tsudev.com, token app     │
 │  └ packages/core (Dart thuần): miền, tiền,│  ghim    │  • /api/v1/sync: đẩy/kéo bản ghi mã  │
 │     mã hóa libsodium, HLC, hợp nhất       │  chứng   │  • D1: users, devices, records(blob) │
 │  └ drift + SQLCipher (CSDL mã hóa cục bộ) │  chỉ     │  • R2: ảnh hóa đơn đã mã hóa         │
 │  └ khóa trong Keystore/Keychain/DPAPI     │          │  • Email Worker: niêm phong email    │
 └───────────────────────────────────────────┘          └──────────────────────────────────────┘
 apps/site (Astro, trang giới thiệu) - Cloudflare, cùng tên miền qulythuchi.tsudev.com
```

## 2. Thành phần monorepo (hình trạng B)

| Đường dẫn | Công nghệ | Vai trò |
| --- | --- | --- |
| `packages/core` | Dart thuần (không phụ thuộc Flutter) | Mô hình miền, tiền tệ, quy tắc ngân sách/định kỳ, phong bì mã hóa, HLC, hợp nhất đồng bộ, phân tích sao kê/thông báo |
| `apps/app` | Flutter 3.x, Riverpod, go_router, drift + sqlcipher, sodium_libs, flutter_secure_storage, local_auth | App cho cả 6 đích, gồm web |
| `services/sync-api` | TypeScript, Cloudflare Workers, Hono, D1, R2, Email Workers, Vitest | Máy chủ đồng bộ zero-knowledge |
| `apps/site` | Astro + TypeScript | Trang giới thiệu, tải về, riêng tư, trợ giúp |
| `conformance/` | JSON | Vector đối chiếu phong bì mã hóa giữa Dart và TypeScript (Worker niêm phong email) |

## 3. Vì sao chọn như vậy (tóm tắt, chi tiết ở ADR)

- **Một mã nguồn Dart cho mọi nền tảng, kể cả web** - logic tiền và mã hóa chỉ có một bản, không lệch giữa web và
  app (ADR-0001). Khác sound-db: ở đây không có thuật toán nặng nên không cần Rust.
- **libsodium** (XChaCha20-Poly1305, Argon2id, X25519, BLAKE2b) - thư viện mật mã được kiểm định rộng, có bản gốc cho
  mọi nền tảng và bản WASM cho web (ADR-0002).
- **Local-first**: mọi thao tác ghi vào CSDL cục bộ trước, đồng bộ là việc nền. App dùng được khi mất mạng.
- **Tiền là số nguyên** (`int` đơn vị nhỏ nhất + mã ISO 4217). Cấm `double` cho tiền.

## 4. Luồng bảo mật chính

1. Đăng nhập (danh tính) qua tsudev.com - ADR-0003. Danh tính ≠ khóa mã hóa.
2. Mật khẩu mã hóa (không bao giờ rời thiết bị) → Argon2id → KEK → mở Khóa chủ → mở Khóa ví → mở bản ghi - ADR-0002.
3. Đồng bộ: bản ghi mã hóa + siêu dữ liệu tối thiểu (id ngẫu nhiên, ví, rev) - ADR-0004.
4. Truyền: TLS 1.3, ghim SPKI theo tập CA dự phòng; HSTS, CSP chặt cho web.

## 5. Mô hình đe dọa

Viết đầy đủ ở P1 theo `.standards/docs/templates/SECURITY_REVIEW.md` → `docs/THREAT_MODEL.md` (STRIDE cho:
thiết bị mất, máy chủ bị chiếm, MITM, kẻ xấu trong nhóm ví chung, app độc đọc thông báo, chuỗi cung ứng).
