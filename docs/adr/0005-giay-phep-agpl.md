# ADR-0005: Giấy phép AGPL-3.0

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi (chủ dự án duyệt hướng chung 17/11/2026)

## 1. Bối cảnh
Chủ dự án ủy quyền chọn giấy phép tối ưu cho bảo mật.

## 2. Quyết định
**AGPL-3.0-only** cho toàn repo. Ai sửa và vận hành thành dịch vụ mạng phải công bố mã đã sửa ⇒ mọi bản phái sinh của
một app tài chính E2EE luôn kiểm tra công khai được, không thể đóng mã để cài cửa hậu. Mã công khai giúp kiểm chứng
lời hứa "máy chủ không đọc được dữ liệu".

## 3. Hệ quả
Phụ thuộc phải tương thích AGPL (MIT, BSD, Apache-2.0, ISC, MPL-2.0 đều được). CI kiểm giấy phép phụ thuộc. Tên
"Quly Thu Chi" và logo không thuộc phạm vi giấy phép (ghi ở `NOTICE`).
