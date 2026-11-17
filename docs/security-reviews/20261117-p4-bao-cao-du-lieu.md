# PHIẾU RÀ SOÁT BẢO MẬT - P4 Báo cáo + dữ liệu

- **PR / nhánh**: `feat/p4-bao-cao`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (ủy quyền cho agent, xem mục 7)
- **Ngày**: 17/11/2026

## 1. Thay đổi này đụng vào đâu

- [ ] Xác thực hoặc quản lý phiên (khôi phục từ tệp sao lưu mở kho khóa - xem mục 4)
- [ ] Phân quyền hoặc kiểm tra quyền sở hữu đối tượng
- [x] Tải tệp lên hoặc phục vụ tệp (đọc tệp CSV/`.qtbak` do người dùng chọn; ghi tệp xuất)
- [x] Truy vấn cơ sở dữ liệu có dữ liệu do người dùng nhập (SQLite cục bộ, tham số hóa)
- [ ] Hiển thị nội dung do người dùng tạo ra HTML
- [ ] Gọi ra dịch vụ ngoài (KHÔNG)
- [x] Xử lý dữ liệu bí mật (D3): báo cáo, bộ lọc đã lưu, tệp xuất, tệp sao lưu, nhập giao dịch

## 2. Phân loại dữ liệu

| Dữ liệu chạm tới | Mức | Đã mã hóa khi truyền | Đã mã hóa khi lưu | Thời hạn lưu |
| --- | --- | --- | --- | --- |
| Báo cáo, "An toàn để tiêu" | D3 | Không truyền | Chỉ tính trong bộ nhớ | Không lưu |
| Bộ lọc đã lưu (`saved_filter`, cấp tài khoản) | D3 | Chưa truyền (P6) | Phong bì, khóa tài khoản | Tới khi xóa |
| Tệp xuất CSV/XLSX/PDF | D3 | Không | **KHÔNG** (người dùng yêu cầu bản rõ; có cảnh báo) | Do người dùng |
| Tệp sao lưu `.qtbak` | D3 | Không | Phong bì v1 khóa chủ + gói khóa Argon2id | Do người dùng |
| Tệp CSV nhập vào | D3 | Không | Chỉ đọc vào bộ nhớ, ghi lại dạng niêm phong | Không giữ tệp |

## 3. Đối chiếu OWASP

| Rủi ro | Có liên quan | Biện pháp đã áp dụng |
| --- | --- | --- |
| A01 Kiểm soát truy cập | Có | Khôi phục chỉ khi thiết bị chưa có tài khoản (không ghi đè/trộn tài khoản khác) |
| A02 Mật mã | Có | Sao lưu dùng phong bì v1 sẵn có, ngữ cảnh `bak|<id>` (AAD); không tự chế; tệp không chứa bản rõ |
| A03 Tiêm mã | Có | CSV/XLSX chống tiêm công thức (`'` trước `= + - @ tab CR`); XML thoát ký tự, bỏ ký tự điều khiển |
| A04 Thiết kế | Có | Nhập giới hạn 5 MB/20.000 dòng; ghi một giao tác; khôi phục một giao tác (giao tác lồng được) |
| A05 Cấu hình sai | Không | |
| A08 Toàn vẹn dữ liệu | Có | Tệp sao lưu bị sửa 1 bit/đổi id ⇒ từ chối (AEAD); JSON sai cấu trúc ⇒ `FormatException` |
| A10 SSRF | Không | Không gọi mạng |

## 4. Ca tấn công đã cân nhắc

1. **Ca**: kẻ gian sửa tệp `.qtbak` (đổi bản ghi, đổi id) để cài dữ liệu giả. - **Chặn ở**: AEAD phong bì + AAD
   `bak|<id>`; bản ghi bên trong vẫn là phong bì riêng có AAD id/loại. - **Test**: `data_io_test.dart` "sai mật khẩu,
   tệp hỏng, bị sửa...".
2. **Ca**: tệp `.qtbak` bị lộ ⇒ đọc dữ liệu. - **Chặn ở**: không có bản rõ (test "không chứa bản rõ"); mở cần mật
   khẩu (Argon2id) hoặc 24 từ. Còn lại: dò mật khẩu ngoại tuyến - xem mục 6.
3. **Ca**: tệp CSV độc chứa công thức `=HYPERLINK(...)` được xuất lại và mở trong Excel. - **Chặn ở**: `_safeText`.
   - **Test**: "CSV có BOM, chống công thức...".
4. **Ca**: tệp CSV khổng lồ/nhiều dòng làm treo app. - **Chặn ở**: kiểm kích thước trước khi đọc, `maxImportRows`.
5. **Ca**: khôi phục lỗi giữa chừng để lại thiết bị "có tài khoản" thiếu khóa ví ⇒ mất dữ liệu ngầm. - **Chặn ở**:
   một giao tác. - **Test**: "giao tác lồng nhau: lỗi ở lớp trong hủy cả lớp ngoài".
6. **Ca**: lộ D3 qua thông báo lỗi khi nhập. - **Chặn ở**: dòng lỗi chỉ đếm; thông báo cố định.
7. **Ca**: người dùng vô tình xuất bản rõ lên thư mục đồng bộ đám mây. - **Chặn ở**: hộp thoại cảnh báo mỗi lần
   (test `p4_app_test.dart`); không có xuất ngầm/tự động.

## 5. Kiểm tra bắt buộc

- [x] Đầu vào kiểm tra tại biên: `parseAmount` (số nguyên, không `double`, chặn vượt `Money.maxSafe`), `parseDate`
  (ngày không tồn tại ⇒ null), `importTxns` chạy `_checkTxn` cho từng dòng.
- [x] Không secret/D3 trong log, thông báo lỗi.
- [x] Giới hạn kích thước: nhập 5 MB/20.000 dòng, ghi chú 500 ký tự; ngữ cảnh sao lưu theo lõi (id ≤ 4096).
- [x] Phụ thuộc mới đã rà: `pdf` 3.13.1 (Apache-2.0), `archive` 4.7.1 (MIT), `file_saver` 0.7.0 (BSD-3),
  `file_selector` 1.1.0 (BSD-3, flutter.dev). Ghi vào `NOTICE`. Không cần quyền Android mới (dùng SAF/hộp thoại hệ thống).
- [x] `gitleaks` trên CI.

## 6. Rủi ro còn lại

- Tệp xuất là bản rõ ngoài tầm bảo vệ của app (đã cảnh báo).
- Tệp `.qtbak` cho phép dò mật khẩu ngoại tuyến; giảm thiểu bằng Argon2id 64 MiB/3 + sàn độ mạnh mật khẩu.
- Bản web: tệp tải xuống nằm trong thư mục Downloads của trình duyệt.

## 7. Kết luận của người rà soát

- [ ] Đạt - được merge
- [x] Đạt có điều kiện - phải sửa các điểm ghi ở mục 6 trước khi phát hành
- [ ] Không đạt - lý do:

Ký: agent-qulythuchi ký THAY theo ủy quyền của chủ dự án (17/11/2026: "tự động thực hiện tất cả các bước cần thiết").
Không phải rà soát độc lập; điều kiện như phiếu P2 mục 7 (rà soát độc lập trước P10).
