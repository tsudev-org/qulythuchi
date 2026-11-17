# ADR-0007: Chi tiết mật mã chốt ở P1 - X-Wing, NFKC, tham số Argon2id, phong bì v1

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0002, không thay thế)
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `packages/core/lib/src/crypto/*`, `conformance/envelope-v1.json`, `docs/THREAT_MODEL.md`

## 1. Bối cảnh
Khi cài đặt ADR-0002 bằng gói `sodium` 4.1.2 (libsodium 1.0.22) phát sinh các điểm cần chốt.

## 2. Quyết định
1. **Chia sẻ khóa ví dùng X-Wing** (`crypto_kem`: ML-KEM-768 + X25519, khóa công khai 1216 B, bản mã 1120 B) thay vì
   niêm phong X25519 - chống "thu trước, giải sau" bằng máy tính lượng tử. KEK = `crypto_kdf(shared, "QTSHARE1", 1)`.
   Đường lùi hậu lượng tử trong ADR-0002 mục 4 coi như đã thực hiện cho phần trao khóa.
2. Email chuyển tiếp vẫn dùng `crypto_box_seal` X25519 (Worker TypeScript cần thư viện phổ biến) - ngoại lệ có ghi.
3. **Mật khẩu chuẩn hóa NFKC** trước Argon2id - chữ Việt có dấu gõ trên iOS/Windows/Linux có thể khác dạng NFC/NFD.
4. Argon2id mặc định **3 lượt / 64 MiB**; khi mở khóa từ chối dưới **2 lượt / 19 MiB** (sàn OWASP) - máy chủ độc
   không ép được tham số yếu. Mật khẩu mã hóa ≥ 10 ký tự sau chuẩn hóa.
5. Phong bì v1 cố định: `'Q' 'T' 01 01 ‖ nonce 24 ‖ XChaCha20-Poly1305(sodium_pad(bản rõ, khối))`, AAD = 4 byte đầu ‖
   ngữ cảnh. Khối đệm: bản ghi 256 B, khóa 16 B, tệp 4096 B. Có vector đối chiếu, kiểm bằng libsodium độc lập trên CI.
6. KEK khôi phục = `crypto_kdf(entropy 24 từ, "QTRECOV1", 1)`; 24 từ theo BIP39 tiếng Anh (có tổng kiểm).

## 3. Hệ quả
Đổi bất kỳ điểm nào ở trên ⇒ phong bì/gói khóa phiên bản mới + ADR mới + sinh lại vector; dữ liệu cũ vẫn đọc được.
