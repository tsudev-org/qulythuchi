# PHIẾU RÀ SOÁT BẢO MẬT - P7b Tệp đính kèm ảnh hóa đơn mã hóa đầu-cuối

- **PR / nhánh**: `feat/p7b-tep-dinh-kem`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (ủy quyền cho agent, xem mục 7)
- **Ngày**: 20/11/2026
- **Quyết định thiết kế**: `docs/adr/0017-tep-dinh-kem-anh-hoa-don-e2ee.md`

## 1. Thay đổi này đụng vào đâu

- [ ] Xác thực hoặc quản lý phiên (không đổi)
- [x] Phân quyền hoặc kiểm tra quyền sở hữu đối tượng (tệp của ví chung theo quyền chủ/ghi/xem)
- [x] Tải tệp lên hoặc phục vụ tệp (R2 qua Worker, ảnh do người dùng chọn được giải mã + mã hóa lại trên máy)
- [x] Truy vấn cơ sở dữ liệu có dữ liệu do người dùng nhập (D1 migration 0005, SQLite cục bộ schema v3 - tham số hóa)
- [ ] Hiển thị nội dung HTML
- [ ] Gọi ra dịch vụ ngoài (chỉ máy chủ của mình)
- [x] Xử lý dữ liệu bí mật (D3): ảnh hóa đơn, khóa tệp

## 2. Phân loại dữ liệu

| Dữ liệu chạm tới | Mức | Mã hóa khi truyền | Mã hóa khi lưu | Thời hạn lưu |
| --- | --- | --- | --- | --- |
| Ảnh hóa đơn (đã làm sạch) | D3 | TLS + E2EE (khóa tệp FK) | Bản mã trong CSDL máy (sqlite3mc trên máy gốc) + R2 | Tới khi xóa ảnh/giao dịch |
| Khóa tệp FK | D3 | Trong bản ghi `attachment` E2EE (khóa ví) | Trong bản ghi đã mã hóa | Như ảnh |
| Cỡ ảnh, loại, điểm ảnh, giao dịch gắn với | D3 | Trong bản ghi E2EE | Trong bản ghi đã mã hóa | Như ảnh |
| EXIF/GPS/tên tệp gốc | D3 | KHÔNG rời khỏi bộ nhớ máy | Không lưu | Bỏ ngay khi làm sạch |
| Số tệp, cỡ đã đệm (bội 64 KiB), ví, người tải lên | D1 | TLS | D1 | Như ảnh |

## 3. Đối chiếu OWASP (ASVS máy chủ + MASVS app)

| Rủi ro | Có liên quan | Biện pháp đã áp dụng |
| --- | --- | --- |
| A01 Kiểm soát truy cập | Có | R2 khóa theo `u/<user từ phiên>/` hoặc `w/<ví>/` sau khi kiểm thành viên; người ngoài 404; người xem không tải lên/xóa; tệp cá nhân không nhận `wallet_id` ví chung |
| A02 Mật mã | Có | Chỉ libsodium (XChaCha20-Poly1305, `randombytes`); FK riêng mỗi tệp; AAD gắn ví + giao dịch + tệp; vector đối chiếu kiểm bằng libsodium độc lập |
| A03 Tiêm | Có | Câu SQL tham số hóa; id kiểm UUID; ảnh giải mã bằng thư viện Dart thuần (bộ nhớ an toàn), có trần cỡ + điểm ảnh |
| A04 Thiết kế | Có | Máy chủ chỉ giữ bản mã, không chuyển mã/xem trước; ảnh luôn mã hóa lại ⇒ không siêu dữ liệu nào lọt |
| A05 Cấu hình sai | Có | Phục vụ `application/octet-stream` + `Content-Disposition: attachment` + `no-store` (không trình duyệt nào hiển thị trực tiếp) |
| A08 Toàn vẹn | Có | Bản ghi đính kèm mở được mới có FK; tệp mở sai ngữ cảnh ⇒ lỗi chung |
| A09 Ghi log | Có | Không log tên tệp, cỡ gốc, nội dung; lỗi hiện theo mã |
| A10 SSRF | Không | - |

## 4. Ca tấn công đã cân nhắc

1. **Ca**: máy chủ độc tráo ảnh của giao dịch A sang giao dịch B hoặc sang ví khác. - **Chặn ở**: FK riêng + AAD `attf|ví|
   giao dịch|tệp` ⇒ không mở được, app báo "không mở được ảnh". - **Test**: lõi `attachments_test.dart` "tráo…".
2. **Ca**: ảnh lộ vị trí nhà/nơi làm việc qua GPS EXIF, hoặc ảnh thu nhỏ nhúng còn bản gốc. - **Chặn ở**: giải mã + mã
   hóa lại JPEG mới, xóa EXIF/ICC/chú thích. - **Test**: lõi "ảnh có GPS ⇒ đầu ra không còn EXIF".
3. **Ca**: ảnh "bom giải nén" (kích thước khai 60000 x 60000) làm treo/hết bộ nhớ máy. - **Chặn ở**: trần 25 MiB đầu vào
   + đọc kích thước khai trước khi giải mã, > 50 triệu điểm ảnh ⇒ từ chối. - **Test**: lõi "quá nhiều điểm ảnh".
4. **Ca**: IDOR - người ngoài ví đoán id ví/tệp để tải. - **Chặn ở**: UUID v4; kiểm thành viên từ phiên, người ngoài 404.
   - **Test**: `files.test.ts` "người ngoài ví…".
5. **Ca**: người xem (viewer) xóa/ghi đè ảnh của ví chung. - **Chặn ở**: máy chủ 403 `read_only`; app ẩn nút. -
   **Test**: `files.test.ts` "người xem…".
6. **Ca**: người dùng miễn phí lách gate Pro bằng tệp. - **Chặn ở**: `PUT` cá nhân `requirePro`; `PUT` ví chung theo Pro
   chủ ví. - **Test**: `files.test.ts` "402…".
7. **Ca**: dồn ví chung của người khác đầy để chủ ví hết hạn mức. - **Chặn ở**: chỉ chủ/người ghi tải lên; giới hạn tần
   suất 60/phút; hạn mức 1 GiB chung của chủ ví. Rủi ro còn: người ghi được tin cậy.
8. **Ca**: thành viên bị thu hồi tiếp tục tải ảnh. - **Chặn ở**: hết là thành viên ⇒ 404. Ảnh đã tải trước vẫn còn ở
   máy họ (bản chất E2EE).
9. **Ca**: 402 khi hết Pro làm mất ảnh vừa chụp. - **Chặn ở**: app giữ bản mã cục bộ trạng thái chờ, không xóa. -
   **Test**: app `attachments_test.dart` "402…".

## 5. Kiểm tra bắt buộc

- [x] Không secret trong mã/log/test (ảnh test sinh trong bộ nhớ).
- [x] Phụ thuộc mới: `image` 4.13.1 ở lõi (MIT, Dart thuần; đã có sẵn trong cây phụ thuộc app dạng gián tiếp).
- [x] Migration MỚI `0005_wallet_files.sql`; 0001-0004 không đổi.
- [x] Vector đối chiếu thêm mục `attachment-file`, kiểm bằng libsodium hệ thống.
- [x] Lõi 101 test (6 mới), máy chủ 71 (3 mới + 402 tệp ví chung), app toàn bộ đạt (6 test đồng bộ + 2 widget mới);
  PR #32 CI xanh.

## 6. Rủi ro còn lại

- Máy chủ thấy số ảnh, cỡ đệm 64 KiB, thời điểm tải lên, ai tải lên ví chung.
- Ảnh đã tải về máy thành viên bị thu hồi không thu hồi được.
- Giải mã ảnh bằng thư viện Dart thuần chậm trên máy yếu (~1-3 giây ảnh 12 MP); chạy trong isolate trên máy gốc.
- Không có xem trước ảnh trong thông báo/đa nhiệm (Android FLAG_SECURE đã có từ P2 cho toàn app).

## 7. Kết luận của người rà soát

- [ ] Đạt - được merge
- [x] Đạt có điều kiện - merge được; rà soát độc lập trước P10 cùng phần trao khóa P9
- [ ] Không đạt - lý do:

Ký: agent-qulythuchi ký THAY theo ủy quyền của chủ dự án. Không phải rà soát độc lập.
