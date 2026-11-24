# MÔ HÌNH ĐE DỌA - Quly Thu Chi

> Phiếu rà soát gốc theo `.standards/docs/templates/SECURITY_REVIEW.md`, áp cho toàn hệ thống (dữ liệu **D3**).
> Mọi PR đụng `packages/core/lib/src/crypto`, `sync`, xác thực hoặc máy chủ `MUST` cập nhật mục liên quan.
> Phiên bản: P1 (17/11/2026) - lõi mã hóa; P5 máy chủ; P6 (18/11/2026) đồng bộ app (ADR-0011); P7 (18/11/2026) tự nhập (ADR-0012); P9 (19/11/2026) ví chung (ADR-0015).

## 1. Tài sản và ranh giới tin cậy

| Tài sản | Mức | Nơi ở | Bảo vệ |
| --- | --- | --- | --- |
| Giao dịch, ví, ngân sách, ghi chú | D3 | Thiết bị (SQLCipher), máy chủ (bản mã) | XChaCha20-Poly1305 theo khóa ví |
| Khóa chủ MK | D3 | Keychain/Keystore (đã mở), máy chủ (đã bọc 2 lần) | Argon2id(mật khẩu) / KDF(24 từ) |
| Mật khẩu mã hóa, 24 từ | D3 | Chỉ trong đầu người dùng / giấy | Không bao giờ truyền đi |
| Phiên đăng nhập TsuDEV | D3 | Kho bí mật OS | Token xoay vòng, thu hồi thiết bị |
| Email + id tài khoản | D2 | Máy chủ | TLS, không log |

Ranh giới: **thiết bị đã mở khóa** là vùng tin cậy duy nhất. Máy chủ, mạng, CDN, sao lưu đám mây đều là vùng KHÔNG tin cậy.

## 2. STRIDE theo kịch bản

| # | Kịch bản | Loại | Biện pháp | Trạng thái |
| --- | --- | --- | --- | --- |
| T1 | Kẻ tấn công chiếm toàn bộ máy chủ/D1/R2 | I | E2EE: máy chủ chỉ có bản mã, khóa bọc; id UUID v4 không lộ thời điểm; đệm 256 B giấu độ dài | ✅ P1 (lõi) |
| T2 | Máy chủ độc tráo bản ghi giữa ví/loại/id, hoặc trả bản cũ | T | AAD ràng buộc ví+loại+id; `RecordCipher.open` đối chiếu bản rõ với siêu dữ liệu; HLC chặn ghi đè bằng bản cũ hơn | ✅ P1 (tráo); ✅ P6 kiểm rev tăng chặt + rev cấp mới > rev đã thấy (không ký được vì người ký là máy chủ) |
| T3 | Máy chủ độc gửi tham số Argon2id yếu để dò mật khẩu nhanh | I | Sàn ops ≥ 2, mem ≥ 19 MiB khi mở; test `máy chủ không ép được tham số KDF yếu` | ✅ P1 |
| T4 | Máy chủ độc gửi gói khóa giả để người dùng mã hóa dữ liệu mới bằng khóa của kẻ tấn công | S | Gói giả không mở được bằng mật khẩu thật (AEAD); thiết bị ghim dấu vân tay khóa danh tính sau lần đầu | ✅ AEAD; ✅ P6 ghim vân tay + gói máy chủ phải mở được bằng khóa chủ (ADR-0011) |
| T5 | Dò mật khẩu ngoại tuyến từ gói khóa bị lộ | I | Argon2id 64 MiB/3 lượt; mật khẩu ≥ 10 ký tự sau NFKC; 24 từ = 256 bit | ✅ P1; ⏳ P10 đo độ mạnh (zxcvbn) |
| T6 | MITM / CA giả | T, I | TLS 1.3 + chỉ tin tập CA gốc ghim (ADR-0011 mục 8); E2EE vẫn che nội dung | ✅ P6 (web: trình duyệt) |
| T7 | Mất điện thoại đang mở khóa | I | Khóa app sinh trắc/PIN, tự khóa khi nền, MK trong Keystore yêu cầu xác thực; thu hồi thiết bị từ xa | ✅ P2 (khóa app), ✅ P6 (thu hồi từ màn Tài khoản) |
| T8 | App độc trên máy đọc CSDL/ảnh chụp màn hình | I | SQLCipher, FLAG_SECURE/ẩn khi đa nhiệm, không ghi D3 ra log | ⏳ P2 |
| T9 | Thành viên ví chung bị thu hồi vẫn giữ khóa cũ | I | Xoay khóa ví + mã hóa lại trong một giao tác máy chủ; ghi bằng phiên bản cũ ⇒ `stale_key`; người rời ⇒ chủ ví tự xoay; chia sẻ bằng X-Wing (lai hậu lượng tử) | ✅ P1 (chia sẻ); ✅ P9 (xoay, ADR-0015) - dữ liệu đã tải trước khi bị thu hồi vẫn ở máy họ |
| T10 | Kẻ thu thập bản mã hôm nay, giải bằng máy tính lượng tử sau này | I | Dữ liệu dùng khóa đối xứng 256 bit (an toàn trước Grover); trao khóa bằng X-Wing ML-KEM-768 + X25519 | ✅ P1; email dùng X25519 (ngoại lệ, ADR-0006) |
| T11 | Email chuyển tiếp lộ trên máy chủ | I | Tắt mặc định + màn công bố ngoại lệ E2EE; niêm phong `crypto_box_seal` trước khi ghi D1, không log nội dung, xóa khi app tải về hoặc sau 30 ngày; địa chỉ 128 bit đổi/tắt được | ✅ P7 (ADR-0012) - rủi ro còn lại: thấy bản rõ trong lượt xử lý |
| T12 | Chuỗi cung ứng: gói phụ thuộc độc | T | Ghim phiên bản, Dependabot, gitleaks, CodeQL, chỉ phụ thuộc đã khai (mục 5) | ✅ P0-P1 |
| T13 | Sai lệch giữa các nền tảng làm hỏng giải mã/tiền | D | Vector đối chiếu kiểm bằng libsodium độc lập (`conformance/verify_libsodium.py`); tiền số nguyên ≤ 2^53-1; mật khẩu NFKC | ✅ P1 |
| T14 | Đồng hồ thiết bị sai/giả để thắng mọi xung đột | T | Chặn HLC lệch > 5 phút so với giờ nhận; bộ đếm tràn chuyển sang mili giây kế tiếp | ✅ P1 |
| T15 | Dữ liệu đồng bộ hỏng/độc làm sập app | D | Giải mã thất bại ⇒ lỗi chung; `fromBytes` từ chối số thực, kiểu lạ, tên trường lạ; mô hình đọc trường lỗi về giá trị an toàn | ✅ P1 |
| T16 | Người dùng khác đọc/ghi đè dữ liệu qua API (IDOR), chiếm phiên bằng token cắp | S, I, E | Mọi truy vấn lọc `user_id` từ phiên; khóa `(user_id, id)`; refresh xoay vòng phát hiện dùng lại; thu hồi thiết bị tức thì; cookie `__Host-` Strict + CSRF; test `services/sync-api/test/*` | ✅ P5 |
| T17 | Lấp đầy D1/R2 hoặc dồn yêu cầu (từ chối dịch vụ gói 0 đồng) | D | Giới hạn tần suất theo IP/tài khoản, giới hạn thân, hạn mức 200 MiB + 1 GiB (Pro, ADR-0016), cỡ tối đa bản ghi/tệp | ✅ P5 |
| T18 | Máy chủ độc/thiết bị lẫn tài khoản làm trộn hai khóa chủ hoặc đẩy dữ liệu sang tài khoản TsuDEV khác | T, I | So danh tính gói khóa, ràng buộc CSDL với id người dùng, không tự trộn (ADR-0011 mục 3, 6) | ✅ P6 |
| T19 | App độc/thư rác/máy chủ độc chèn giao dịch giả qua thông báo, email, sao kê | S, T | Chỉ nghe gói app người dùng chọn; mọi giao dịch tự nhập vào hàng chờ "Cần xác nhận" (tự xác nhận tắt mặc định); OTP bị bỏ; hộp thư ≤ 200 thư | ✅ P7 |
| T21 | Máy chủ độc thay khóa công khai của người được mời bằng khóa của nó để nhận khóa ví chung | S, I | Bằng chứng nhận lời mời BLAKE2b có khóa = bí mật mã mời (máy chủ không có), chủ ví kiểm trên thiết bị trước khi chia khóa; mã an toàn để so qua kênh ngoài | ✅ P9 (ADR-0015) |
| T22 | Máy chủ độc gửi thành viên khóa ví do nó tạo để đọc dữ liệu họ ghi | S, I | KEK khối chia sẻ = BLAKE2b(khóa = bí mật cặp, bí mật chung X-Wing ‖ bản mã) ⇒ khối giả không mở được | ✅ P9 |
| T23 | Leo thang quyền trong ví chung (người xem ghi, người ghi sửa/xóa ví, người ngoài đọc) | E | Máy chủ kiểm thành viên + quyền ở mọi lượt (`read_only`, `forbidden`, 404); app chặn sớm | ✅ P9 |
| T24 | Lộ mã mời qua kênh ngoài (tin nhắn bị đọc trộm) | S | Mã dùng một lần, sống 7 ngày; chủ ví thấy tài khoản đã nhận và thu hồi được; mã một mình không mở được khối khóa | ✅ P9 - rủi ro còn lại: kẻ nhận trước người thật |
| T25 | Giả mạo quyền lợi Pro (app tự báo, JWS giả/của app khác/của người khác) để đồng bộ miễn phí | S, E | Gate ở máy chủ; chỉ tin JWS ES256 tsudev.com ký, kiểm `iss`/`aud`/`typ`/`sub`/`exp`; lỗi kênh ⇒ 503 không cấp quyền | ✅ T7 (ADR-0016) |
| T26 | Vượt gate qua đường không chặn (khoá, ví chung của chủ ví đã hết Pro) | E | Ví chung kiểm Pro của chủ ví; `PUT /keys/*` mở có chủ đích nhưng giới hạn 32/512 KiB | ✅ T7 - rủi ro còn lại nhỏ |
| T27 | Liệt kê/theo dõi thiết bị qua mã cài đặt | I | Mã ngẫu nhiên 128 bit, máy chủ chỉ lưu SHA-256, chỉ trả số đếm `devices_30d` | ✅ T7 |
| T28 | Lộ khoá riêng RP (`RP_PRIVATE_JWK`) | I | Secret Cloudflare + tệp 600 ngoài repo; chỉ đọc được quyền lợi, không dữ liệu tài chính; xoay bằng `scripts/rp-key.mjs` | ✅ T7 |
| T29 | Ảnh hóa đơn lộ vị trí/thiết bị (EXIF/GPS), máy chủ tráo ảnh giữa giao dịch, ảnh "bom giải nén" | I, T, D | Làm sạch + mã hóa lại JPEG trên máy trước khi mã hóa; khóa tệp riêng + AAD `attf|ví|giao dịch|tệp`; trần 25 MiB/50 triệu điểm ảnh đọc trước khi giải mã; tệp ví chung theo quyền thành viên (ADR-0017) | ✅ P7b |
| T20 | Rò nội dung thông báo/ảnh hóa đơn/giọng nói khỏi thiết bị | I | Hàng đợi thông báo mã hóa Keystore, không sao lưu; OCR ML Kit trên máy, xóa ảnh tạm; giọng nói `onDevice`, dịch vụ HĐH chỉ khi đồng ý; widget không hiện dữ liệu | ✅ P7 |
| T30 | App tự cấp Pro / giả JWS trong đệm cục bộ để mở nút | S, E | JWS kiểm lại mỗi lần đọc (ES256 + JWKS, `aud` = `qulythuchi`, `exp` ≤ 7 ngày); trường không ký chỉ đổi lời nhắn; máy chủ vẫn gate mọi lượt đẩy (T25) | ✅ T7 app (ADR-0019) |
| T31 | Dùng lại biên nhận Play cho tài khoản khác / app tự tin biên nhận / bản Play dẫn ra thanh toán web | S, E | `obfuscatedAccountId` từ `sub` của JWS đã kiểm; app chỉ chuyển biên nhận (máy chủ ⇒ tsudev.com xác minh), chỉ hoàn tất giao dịch khi xác minh xong; danh sách mã cố định, không `thang`; kênh mặc định an toàn (Android ⇒ Play) | ✅ T7 app (ADR-0019) |
| T32 | Sao kê PDF độc khai thác lỗi bộ nhớ của PDFium / tệp phình to / lộ mật khẩu PDF | T, D, I, E | PDFium (`pdfrx` 3.0.0 ghim, bản không V8) chỉ lấy chữ; giới hạn 15 MiB/200 trang/2 triệu ký tự; mật khẩu chỉ trong bộ nhớ; sandbox nền tảng; SHA-256 ghim bản PDFium | ✅ Sao kê PDF (ADR-0020) |
| T33 | Ảnh hóa đơn độc khai thác bộ giải mã ảnh / chiếm tệp chạy Tesseract / ảnh lớn làm treo (OCR desktop) | T, D, I, E | OCR của hệ điều hành (Windows.Media.Ocr, Vision) + Tesseract hệ thống qua đường dẫn tuyệt đối, không shell, ảnh qua stdin; ≤ 25 MiB; timeout 60 giây giết tiến trình; không mạng/tệp tạm | ✅ OCR desktop (ADR-0021) |

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
- Ví chung: máy chủ thấy ai cùng ví với ai, quyền, ai ghi lần cuối; tên/email thành viên hiện cho người cùng ví (ADR-0015 mục 3).
