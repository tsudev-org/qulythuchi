# ADR-0002: Mã hóa đầu-cuối: phân cấp khóa, libsodium, máy chủ không biết gì

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi (chủ dự án duyệt hướng chung 17/11/2026)

## 1. Bối cảnh
Dữ liệu tài chính là D3. Chủ dự án chọn E2EE: kẻ chiếm được máy chủ/CSDL cũng không đọc được dữ liệu.

## 2. Quyết định
Thư viện: **libsodium** (`sodium_libs` cho Flutter - gốc trên 5 nền tảng, libsodium.js trên web). Không tự chế mật mã.

Phân cấp khóa:
| Khóa | Sinh ra | Bọc bởi | Lưu ở |
| --- | --- | --- | --- |
| Khóa chủ MK (256 bit) | ngẫu nhiên lúc tạo tài khoản mã hóa | KEK mật khẩu **và** KEK khôi phục | máy chủ (đã bọc) + Keychain/Keystore (đã mở, khóa sinh trắc) |
| KEK mật khẩu | Argon2id(mật khẩu mã hóa, salt 16 B, ops/mem tham số hóa, mặc định MODERATE) | - | không lưu |
| KEK khôi phục | 24 từ (256 bit entropy + checksum, từ điển BIP39) → BLAKE2b | - | người dùng tự giữ |
| Khóa ví VK (256 bit) | ngẫu nhiên, mỗi ví một khóa | MK (riêng), hoặc niêm phong tới khóa X25519 thành viên (ví chung, P9) | máy chủ (đã bọc) |
| Cặp khóa danh tính X25519 | ngẫu nhiên | khóa riêng bọc bởi MK | máy chủ (khóa công khai rõ, khóa riêng đã bọc) |

Bản ghi: `XChaCha20-Poly1305-IETF`, nonce ngẫu nhiên 24 B, **AAD** = `phiên-bản ‖ id-bản-ghi ‖ id-ví ‖ loại`
(chống tráo bản ghi giữa ví/loại). Định dạng phong bì có số phiên bản để xoay thuật toán.

Máy chủ chỉ thấy: id ngẫu nhiên (UUID v4 - không dùng v7 vì lộ thời điểm tạo), id ví, rev, kích thước đệm (bản rõ
được đệm theo khối 256 B để giấu độ dài), thời điểm đồng bộ. Không thấy số tiền, danh mục, ghi chú, tên ví.

## 3. Hệ quả
- Quên cả mật khẩu mã hóa lẫn 24 từ ⇒ **mất dữ liệu đồng bộ** (dữ liệu trên thiết bị còn mở khóa vẫn xuất được). Phải
  nói rõ ở màn hình thiết lập, bắt người dùng xác nhận đã lưu 24 từ.
- Báo cáo, tìm kiếm chạy trên thiết bị. Máy chủ không tính toán gì trên dữ liệu.
- Đổi mật khẩu = bọc lại MK, không mã hóa lại dữ liệu. Thu hồi thành viên ví chung = xoay VK + mã hóa lại ví (P9).

## 4. Đường lùi
Định dạng phong bì có trường phiên bản; thêm thuật toán hậu lượng tử (ML-KEM) cho phần niêm phong X25519 khi
libsodium hỗ trợ ổn định.
