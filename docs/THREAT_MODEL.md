# MÔ HÌNH ĐE DỌA - Quly Thu Chi

> Phiếu rà soát gốc theo `.standards/docs/templates/SECURITY_REVIEW.md`, áp cho toàn hệ thống (dữ liệu **D3**).
> Mọi PR đụng `packages/core/lib/src/crypto`, `sync`, xác thực hoặc máy chủ `MUST` cập nhật mục liên quan.
> Phiên bản: P1 (17/11/2026) - lõi mã hóa. Bổ sung ở P5 (máy chủ), P6 (đồng bộ app), P7 (tự nhập), P9 (ví chung).

## 1. Tài sản và ranh giới tin cậy

| Tài sản | Mức | Nơi ở | Bảo vệ |
| --- | --- | --- | --- |
| Giao dịch, ví, ngân sách, ghi chú | D3 | Thiết bị (SQLCipher), máy chủ (bản mã) | XChaCha20-Poly1305 theo khóa ví |
| Khóa chủ MK | D3 | Keychain/Keystore (đã mở), máy chủ (đã bọc 2 lần) | Argon2id(mật khẩu) / KDF(24 từ) |
| Mật khẩu mã hóa, 24 từ | D3 | Chỉ trong đầu người dùng / giấy | Không bao giờ truyền đi |
| Phiên đăng nhập tsudev | D3 | Kho bí mật OS | Token xoay vòng, thu hồi thiết bị |
| Email + id tài khoản | D2 | Máy chủ | TLS, không log |

Ranh giới: **thiết bị đã mở khóa** là vùng tin cậy duy nhất. Máy chủ, mạng, CDN, sao lưu đám mây đều là vùng KHÔNG tin cậy.

## 2. STRIDE theo kịch bản

| # | Kịch bản | Loại | Biện pháp | Trạng thái |
| --- | --- | --- | --- | --- |
| T1 | Kẻ tấn công chiếm toàn bộ máy chủ/D1/R2 | I | E2EE: máy chủ chỉ có bản mã, khóa bọc; id UUID v4 không lộ thời điểm; đệm 256 B giấu độ dài | ✅ P1 (lõi) |
| T2 | Máy chủ độc tráo bản ghi giữa ví/loại/id, hoặc trả bản cũ | T | AAD ràng buộc ví+loại+id; `RecordCipher.open` đối chiếu bản rõ với siêu dữ liệu; HLC chặn ghi đè bằng bản cũ hơn | ✅ P1 (tráo); ⏳ P6 (phát hiện rollback bằng con trỏ ký) |
| T3 | Máy chủ độc gửi tham số Argon2id yếu để dò mật khẩu nhanh | I | Sàn ops ≥ 2, mem ≥ 19 MiB khi mở; test `máy chủ không ép được tham số KDF yếu` | ✅ P1 |
| T4 | Máy chủ độc gửi gói khóa giả để người dùng mã hóa dữ liệu mới bằng khóa của kẻ tấn công | S | Gói giả không mở được bằng mật khẩu thật (AEAD); thiết bị ghim dấu vân tay khóa danh tính sau lần đầu | ✅ AEAD; ⏳ P6 ghim vân tay |
| T5 | Dò mật khẩu ngoại tuyến từ gói khóa bị lộ | I | Argon2id 64 MiB/3 lượt; mật khẩu ≥ 10 ký tự sau NFKC; 24 từ = 256 bit | ✅ P1; ⏳ P6 đo độ mạnh (zxcvbn) |
| T6 | MITM / CA giả | T, I | TLS 1.3 + ghim SPKI nhiều CA dự phòng (ADR-0003); E2EE vẫn che nội dung | ⏳ P6 |
| T7 | Mất điện thoại đang mở khóa | I | Khóa app sinh trắc/PIN, tự khóa khi nền, MK trong Keystore yêu cầu xác thực; thu hồi thiết bị từ xa | ⏳ P2, P6 |
| T8 | App độc trên máy đọc CSDL/ảnh chụp màn hình | I | SQLCipher, FLAG_SECURE/ẩn khi đa nhiệm, không ghi D3 ra log | ⏳ P2 |
| T9 | Thành viên ví chung bị thu hồi vẫn giữ khóa cũ | I | Xoay khóa ví + mã hóa lại; chia sẻ bằng X-Wing (lai hậu lượng tử) | ✅ P1 (chia sẻ); ⏳ P9 (xoay) |
| T10 | Kẻ thu thập bản mã hôm nay, giải bằng máy tính lượng tử sau này | I | Dữ liệu dùng khóa đối xứng 256 bit (an toàn trước Grover); trao khóa bằng X-Wing ML-KEM-768 + X25519 | ✅ P1; email dùng X25519 (ngoại lệ, ADR-0006) |
| T11 | Email chuyển tiếp lộ trên máy chủ | I | Tắt mặc định, niêm phong ngay, không lưu bản rõ, xóa sau 30 ngày | ⏳ P7 |
| T12 | Chuỗi cung ứng: gói phụ thuộc độc | T | Ghim phiên bản, Dependabot, gitleaks, CodeQL, chỉ phụ thuộc đã khai (mục 5) | ✅ P0-P1 |
| T13 | Sai lệch giữa các nền tảng làm hỏng giải mã/tiền | D | Vector đối chiếu kiểm bằng libsodium độc lập (`conformance/verify_libsodium.py`); tiền số nguyên ≤ 2^53-1; mật khẩu NFKC | ✅ P1 |
| T14 | Đồng hồ thiết bị sai/giả để thắng mọi xung đột | T | Chặn HLC lệch > 5 phút so với giờ nhận; bộ đếm tràn chuyển sang mili giây kế tiếp | ✅ P1 |
| T15 | Dữ liệu đồng bộ hỏng/độc làm sập app | D | Giải mã thất bại ⇒ lỗi chung; `fromBytes` từ chối số thực, kiểu lạ, tên trường lạ; mô hình đọc trường lỗi về giá trị an toàn | ✅ P1 |

## 3. Phụ thuộc mật mã (SECURITY_BASELINE mục 5)

| Gói | Phiên bản | Vai trò | Lý do tin cậy |
| --- | --- | --- | --- |
| `sodium` (libsodium 1.0.22 đóng gói) | 4.1.2+1 | Toàn bộ mật mã | libsodium được kiểm định rộng; binding mã nguồn mở |
| `crypto` (dart-lang) | 3.x | SHA-256 cho tổng kiểm BIP39 | Gói chính thức của nhóm Dart |
| `unorm_dart` | 0.3.x | Chuẩn hóa NFKC mật khẩu | Thuần Dart, không mạng, chỉ ảnh hưởng chuẩn hóa chuỗi |

## 4. Rủi ro còn lại (chấp nhận có điều kiện)

- Quên cả mật khẩu lẫn 24 từ ⇒ mất dữ liệu đồng bộ. Chấp nhận - là bản chất E2EE, phải cảnh báo rõ ở P6.
- Siêu dữ liệu lộ: số bản ghi, kích thước đệm, thời điểm đồng bộ, số ví. Chấp nhận; xem xét gộp lô ở P6.
- Web không có SQLCipher (ADR-0001 mục 4).
