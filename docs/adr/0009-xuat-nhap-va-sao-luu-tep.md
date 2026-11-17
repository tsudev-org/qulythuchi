# ADR-0009: Xuất/nhập dữ liệu và tệp sao lưu mã hóa `.qtbak`

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0002, không thay thế)
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `apps/app/lib/services/export.dart`, `apps/app/lib/services/import_csv.dart`,
  `apps/app/lib/security/vault.dart` (`createBackup`/`restoreBackup`), `apps/app/lib/ui/data/data_page.dart`,
  `docs/security-reviews/20261117-p4-bao-cao-du-lieu.md`

## 1. Bối cảnh
P4 cần: xuất giao dịch CSV/XLSX/PDF, nhập CSV từ app khác, sao lưu ra tệp. Dữ liệu là D3. Xuất ra bảng tính bắt buộc
là bản rõ (người dùng cần mở bằng Excel); sao lưu thì không có lý do gì để là bản rõ. Chưa có máy chủ đồng bộ (P5/P6)
nên tệp sao lưu là cách duy nhất chuyển dữ liệu sang thiết bị mới.

## 2. Quyết định
1. **Xuất bản rõ có cảnh báo**: mỗi lần xuất hiện hộp thoại "Tệp xuất KHÔNG mã hóa" và chỉ lưu khi người dùng bấm
   Tiếp tục. Web: tải xuống; nền tảng khác: hộp thoại "Lưu thành" (`file_saver`). Không tự gửi tệp đi đâu.
2. **Định dạng xuất**: CSV UTF-8 có BOM, RFC 4180, CRLF; ô chữ bắt đầu bằng `= + - @ tab CR` thêm `'` (chống CSV
   injection); số tiền là chuỗi thập phân dấu chấm sinh từ số nguyên (không `double`), chi mang dấu âm. XLSX tự sinh
   OOXML tối giản (`archive` nén zip) - không kéo thư viện bảng tính lớn; ô số là kiểu số thật. PDF bằng `pdf` với font
   Inter đóng gói (đủ dấu tiếng Việt), ngày DD/MM/YYYY.
3. **Nhập CSV**: tối đa 5 MB / 20.000 dòng; tự nhận `,` `;` tab; người dùng ghép cột (đoán sẵn theo tiêu đề vi/en
   không dấu), chọn kiểu ngày và quy ước dấu; xem trước 5 dòng. Danh mục ghép theo tên không dấu đúng loại thu/chi,
   không khớp thì để trống (không tự tạo danh mục). Dòng lỗi chỉ được ĐẾM. Toàn bộ ghi trong một giao tác,
   `source = import`.
4. **Tệp sao lưu `.qtbak` v1** (JSON):
   `{format: "qulythuchi-backup", v: 1, id, bundle, payload}`.
   - `bundle`: gói khóa tài khoản như đang lưu trên máy (khóa chủ bọc bằng Argon2id(mật khẩu) và bằng 24 từ).
   - `payload`: phong bì v1 niêm phong bằng khóa chủ, ngữ cảnh `bak|<id>` (AAD gắn id ⇒ đổi id là không mở được),
     chứa khóa tài khoản đã bọc, khóa ví đã bọc và mọi bản ghi ĐÃ niêm phong. Không có bản rõ nào trong tệp.
   - Khôi phục chỉ trên thiết bị CHƯA có tài khoản (không trộn hai tài khoản); kiểm cấu trúc trước, mở bằng mật khẩu
     hoặc 24 từ, ghi meta + khóa + bản ghi trong MỘT giao tác (`RecordStore.transaction` lồng được).
   - Đổi cấu trúc tệp ⇒ tăng `v`, giữ khả năng đọc `v` cũ.

## 3. Hệ quả
- Tệp `.qtbak` rơi vào tay kẻ xấu cho phép dò mật khẩu ngoại tuyến (giống gói khóa trên máy chủ ở P6): sức chịu đựng
  phụ thuộc Argon2id 64 MiB/3 và độ mạnh mật khẩu (sàn đã áp ở ADR-0007). 24 từ (256 bit) không dò được.
- Khôi phục mang theo khóa tài khoản/khóa ví cũ ⇒ khi P6 đồng bộ, thiết bị khôi phục là cùng tài khoản E2EE.
- Tệp xuất bản rõ nằm ngoài tầm bảo vệ của app - đã cảnh báo, ghi rõ trong `SECURITY.md`/FEATURES khi phát hành.
- Phụ thuộc mới: `file_selector` 1.1.0 (flutter.dev, BSD-3), `file_saver` 0.7.0 (BSD-3), `pdf` 3.13.1
  (DavBfr, Apache-2.0), `archive` 4.7.1 (MIT, Brendan Duncan).
