# Nhật ký thay đổi

Theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), phiên bản theo `.standards/docs/VERSIONING.md`.

## [Chưa phát hành]

### Sửa
- Phần trăm hiển thị theo ngôn ngữ: tiếng Việt dùng dấu phẩy thập phân ("97,9%"), tính bằng số nguyên.

### Thêm
- Báo cáo + dữ liệu (P4): báo cáo theo kỳ (thu, chi, chênh lệch, tỉ lệ tiết kiệm, so với kỳ trước), thu chi 6
  tháng, cơ cấu chi theo danh mục, tài sản ròng, lịch chi tiêu; mọi biểu đồ có bảng dữ liệu thay thế và màu từ token;
  thẻ "An toàn để tiêu" ở Tổng quan; lọc giao dịch nhiều điều kiện (loại, ví, danh mục, khoảng ngày, khoảng tiền) và
  lưu bộ lọc; xuất CSV/XLSX/PDF (cảnh báo tệp không mã hóa, chống tiêm công thức), nhập CSV từ app khác (ghép cột,
  xem trước), sao lưu/khôi phục tệp mã hóa `.qtbak` (ADR-0009).
- Nghiệp vụ nâng cao (P3): ngân sách theo danh mục/ví/kỳ (tuần, tháng, năm, tùy chọn) có chuyển dư và cảnh báo,
  phương pháp 6 hũ (sửa tỉ lệ, chia thu nhập khớp từng đồng), mục tiêu tiết kiệm (tiến độ, mức góp mỗi tháng, góp qua
  chuyển ví), giao dịch định kỳ (tự ghi hoặc chờ xác nhận), hóa đơn (sắp đến hạn, đánh dấu đã trả, nhắc bằng thông báo
  không lộ nội dung), sổ nợ/cho vay (giải ngân, trả dần, quá hạn, nhắc hạn), sự kiện/chuyến đi, tỉ giá nhập tay + tổng
  quy đổi; điều hướng Tổng quan · Giao dịch · Kế hoạch · Ví · Thêm.
- App Flutter `apps/app` (6 đích): khởi tạo tài khoản cục bộ mã hóa (mật khẩu Argon2id, 24 từ + xác nhận 3 từ), màn
  khóa (mật khẩu, PIN có chờ tăng dần, sinh trắc, 24 từ), tự khóa sau 60 giây ở nền, ẩn số dư, chặn chụp màn hình
  Android; ví (7 loại, 17 tiền tệ, số dư đầu, lưu trữ), danh mục 2 tầng (bộ mặc định 28 mục vi/en), giao dịch
  thu/chi/chuyển ví (2 bản ghi, phí, tiền nhận khi khác tiền tệ), máy tính trong ô số tiền, tìm kiếm không dấu;
  giao diện token tsudev Sáng/Tối/Hệ thống, tiếng Việt + English; CSDL SQLite3MultipleCiphers (ADR-0008).
- Lõi `packages/core`: tiền tệ số nguyên, nghiệp vụ thu chi, mã hóa đầu-cuối libsodium (phong bì v1, phân cấp khóa,
  24 từ khôi phục, chia sẻ X-Wing hậu lượng tử), đồng bộ HLC; vector đối chiếu `conformance/`; mô hình đe dọa.
- Nền móng dự án: bộ quy ước tsudev v3.6.0, kế hoạch 11 phase, kiến trúc, ma trận tính năng, ADR 0001-0006, CI khung.
