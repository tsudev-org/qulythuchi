# PHIẾU RÀ SOÁT BẢO MẬT - Widget "Ghi nhanh" + lối tắt iOS (ADR-0022)

- **PR / nhánh**: `feat/widget-ios`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (uỷ quyền cho agent)
- **Ngày**: 24/11/2026
- **Căn cứ**: ADR-0022, ADR-0012 mục 11, `.standards/docs/SECURITY_BASELINE.md`, AGENTS.md B.5

## 1. Thay đổi này đụng vào đâu

- [ ] Xác thực - [ ] Phân quyền - [ ] Tải tệp - [ ] CSDL - [ ] Gọi dịch vụ ngoài
- [x] Bề mặt ngoài khoá app (widget màn hình chính/khoá, lối tắt nhấn giữ)
- [x] Đầu vào liên kết sâu (`com.tsudev.qulythuchi:/quick?mode=…`)

## 2. Ca tấn công đã cân nhắc

1. **Lộ dữ liệu D3 trên màn hình khoá**: widget không có App Group, không đọc tệp/khoá của app, chỉ chữ cố định "Ghi
   nhanh"/Gõ/Nói/Quét. Không có số dư/giao dịch nào để lộ.
2. **Liên kết sâu giả từ app khác** (`com.tsudev.qulythuchi:/quick?mode=x`): đã có từ trước (Android + scheme đăng
   nhập); Dart chỉ nhận `type|voice|scan` (giá trị khác ⇒ `type`), chỉ MỞ màn Ghi nhanh SAU khi người dùng mở khoá app,
   không ghi gì khi người dùng chưa bấm lưu. Lối tắt Swift cũng chỉ nhận ba giá trị.
3. **Chuỗi cung ứng**: không thêm phụ thuộc; chỉ SwiftUI/WidgetKit của hệ thống.

## 3. Kiểm chứng

- `apple.yml`: dựng iOS release, kiểm `.appex` nhúng đúng (điểm mở rộng, mã gói, phiên bản khớp app).
- `apps/app/test/pending_quick_entry_test.dart`: chỉ nhận `type|voice|scan`, giá trị lạ ⇒ `type`, lấy một lần.

## 4. Kết luận

Chấp nhận. Còn lại: thử bấm trên máy thật khi có bản iOS ký (2027).
