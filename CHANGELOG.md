# Nhật ký thay đổi

Theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), phiên bản theo `.standards/docs/VERSIONING.md`.

## [Chưa phát hành]

### Thêm
- App Flutter `apps/app` (6 đích): khởi tạo tài khoản cục bộ mã hóa (mật khẩu Argon2id, 24 từ + xác nhận 3 từ), màn
  khóa (mật khẩu, PIN có chờ tăng dần, sinh trắc, 24 từ), tự khóa sau 60 giây ở nền, ẩn số dư, chặn chụp màn hình
  Android; ví (7 loại, 17 tiền tệ, số dư đầu, lưu trữ), danh mục 2 tầng (bộ mặc định 28 mục vi/en), giao dịch
  thu/chi/chuyển ví (2 bản ghi, phí, tiền nhận khi khác tiền tệ), máy tính trong ô số tiền, tìm kiếm không dấu;
  giao diện token tsudev Sáng/Tối/Hệ thống, tiếng Việt + English; CSDL SQLite3MultipleCiphers (ADR-0008).
- Lõi `packages/core`: tiền tệ số nguyên, nghiệp vụ thu chi, mã hóa đầu-cuối libsodium (phong bì v1, phân cấp khóa,
  24 từ khôi phục, chia sẻ X-Wing hậu lượng tử), đồng bộ HLC; vector đối chiếu `conformance/`; mô hình đe dọa.
- Nền móng dự án: bộ quy ước tsudev v3.6.0, kế hoạch 11 phase, kiến trúc, ma trận tính năng, ADR 0001-0006, CI khung.
