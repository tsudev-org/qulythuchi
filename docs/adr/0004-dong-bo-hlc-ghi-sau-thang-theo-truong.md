# ADR-0004: Đồng bộ: nhật ký thay đổi mã hóa, HLC, ghi sau thắng theo trường

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi (chủ dự án duyệt hướng chung 17/11/2026)

## 1. Bối cảnh
Nhiều thiết bị ghi ngoại tuyến rồi đồng bộ. Máy chủ không đọc được nội dung nên không thể hợp nhất hộ.

## 2. Quyết định
- Mỗi bản ghi (giao dịch, ví, danh mục, ngân sách...) là một tài liệu có `id` UUID v4, mỗi **trường** mang dấu thời gian
  HLC (Hybrid Logical Clock: thời gian vật lý + bộ đếm + id thiết bị).
- Thiết bị đẩy **bản ghi đầy đủ đã mã hóa** (gồm HLC từng trường bên trong bản rõ). Máy chủ gán `rev` tăng dần toàn
  tài khoản/ví; thiết bị kéo theo con trỏ `rev`.
- Hợp nhất trên thiết bị: từng trường, HLC lớn hơn thắng; hòa ⇒ so id thiết bị. Xóa là bia mộ (`deleted` có HLC), dọn sau
  90 ngày khi mọi thiết bị đã qua con trỏ.
- Số dư **không lưu** - luôn tính lại từ giao dịch, nên không có xung đột số dư.
- Không dùng khóa lạc quan (`base_rev`): hợp nhất theo trường có tính giao hoán, thứ tự đẩy không ảnh hưởng kết quả.

## 3. Hệ quả
Dung lượng: một giao dịch ~0,5-1 KB mã hóa ⇒ 5 GB D1 dư cho hàng nghìn người dùng. Có giới hạn hạn mức theo tài khoản.
