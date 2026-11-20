# Chính sách bảo mật - Quly Thu Chi

## Báo lỗ hổng

**KHÔNG mở issue công khai.** Dùng [Báo cáo lỗ hổng riêng tư của GitHub](https://github.com/tsudev-org/qulythuchi/security/advisories/new).
Gửi kèm: thành phần (app/web/máy chủ), phiên bản, cách tái hiện, tác động. Phản hồi trong 7 ngày, bản sửa lỗi
nghiêm trọng trong 30 ngày. Quy trình chung: [`.standards/SECURITY.md`](.standards/SECURITY.md).

## Cam kết bảo mật (dữ liệu mức D3)

- **Mã hóa đầu-cuối**: máy chủ chỉ giữ bản mã; khóa giải mã sinh từ mật khẩu mã hóa không bao giờ rời thiết bị
  (libsodium: Argon2id, XChaCha20-Poly1305, X25519) - [ADR-0002](docs/adr/0002-ma-hoa-dau-cuoi-phan-cap-khoa.md).
- **Local-first**: CSDL trên máy mã hóa SQLCipher, khóa nằm trong kho bí mật của hệ điều hành; khóa app bằng sinh trắc/PIN.
- **Đăng nhập** OIDC + PKCE qua tsudev.com, trình duyệt hệ thống, token xoay vòng, thu hồi thiết bị -
  [ADR-0003](docs/adr/0003-dang-nhap-tsudev-qua-may-chu.md).
- **Truyền**: TLS 1.3 + ghim chứng chỉ; web có HSTS, CSP chặt.
- **Ngoại lệ duy nhất**: email chuyển tiếp (tắt mặc định) - [ADR-0006](docs/adr/0006-tu-nhap-giao-dich.md).

## Kiểm chứng bản tải về

Chưa có bản cài đặt nào được phát hành (app đang phát triển, xem `docs/PLAN.md`). Khi phát hành, mỗi bản kèm
`SHA256SUMS` và chứng thực nguồn gốc bản build:

```bash
gh attestation verify <tệp> --repo tsudev-org/qulythuchi
```

## English summary

**Reporting a vulnerability**: do not open a public issue. Use GitHub's
[private vulnerability reporting](https://github.com/tsudev-org/qulythuchi/security/advisories/new) and include the
component (app / web / sync server), version, steps to reproduce and impact. We reply within 7 days and ship a fix for
serious issues within 30 days. Fixed vulnerabilities are published as GitHub Security Advisories and listed in
`CHANGELOG.md`.

**Security design** (financial data, class D3): end-to-end encryption - the server only stores ciphertext and the keys
derived from your encryption password never leave your device (libsodium: Argon2id, XChaCha20-Poly1305, X25519, X-Wing
for shared wallets); local database encrypted (SQLite3MultipleCiphers) with the key in the OS secret store; sign-in via tsudev.com OIDC + PKCE with rotating refresh
tokens; TLS with certificate pinning in the apps, HSTS and a strict CSP on the web. The only opt-in exception is email
forwarding for auto-import (off by default). No installable release has been published yet; once released, every
release ships `SHA256SUMS` and build provenance (`gh attestation verify <file> --repo tsudev-org/qulythuchi`).
