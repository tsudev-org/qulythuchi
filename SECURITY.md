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

Mỗi bản phát hành kèm `SHA256SUMS` và chứng thực nguồn gốc bản build:

```bash
gh attestation verify <tệp> --repo tsudev-org/qulythuchi
```
