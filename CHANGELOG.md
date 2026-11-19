# Nhật ký thay đổi

Theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), phiên bản theo `.standards/docs/VERSIONING.md`.

## [Chưa phát hành]

### Sửa
- Máy chủ: giải mã thực thể HTML của email một lượt (không giải mã kép, CodeQL).
- Test app: cầu thông báo Android và bộ nghe lối tắt ghi nhanh ghi đè được (flutter test giả lập Android, không có plugin).
- Phần trăm hiển thị theo ngôn ngữ: tiếng Việt dùng dấu phẩy thập phân ("97,9%"), tính bằng số nguyên.

### Thêm
- Ví chung gia đình (P9, ADR-0015):
  - "Chia sẻ và thành viên" trong mỗi ví: chia sẻ ví, mời theo quyền Người ghi hoặc Người xem bằng mã/liên kết/QR (dùng
    một lần trong 7 ngày), đổi quyền, thu hồi, hủy lời mời, mã an toàn 12 chữ số để so với người cùng ví.
  - "Tham gia ví chung" (nút trên màn Ví, liên kết web `#/moi/<mã>`): dán mã, xem lời mời, tham gia; ví xuất hiện khi chủ
    ví mở app. Thành viên rời ví được, dữ liệu ví bị xóa khỏi máy.
  - Mã hóa đầu-cuối giữ nguyên: khóa ví trao bằng X-Wing kèm bí mật của mã mời (máy chủ không giả được thành viên hay
    khóa ví); thu hồi thành viên = đổi khóa ví và mã hóa lại toàn ví; danh mục người khác dùng trong ví hiện đúng tên.
  - Máy chủ: migration 0003, không gian bản ghi theo ví, phân quyền chủ/ghi/xem, xoay khóa trong một giao tác; xuất dữ
    liệu và xóa tài khoản xử lý ví chung.
- Tiện ích tài chính cá nhân (P9a, ADR-0014):
  - Thẻ "Số dư theo tháng" ở Tổng quan: số dư đầu tháng chuyển từ tháng trước + thu - chi = số dư cuối tháng chuyển
    sang tháng sau, xem lùi/tới từng tháng, tỉ lệ để dành; tắt "Chuyển số dư sang tháng sau" để chỉ xem thu/chi.
  - Màn "Khoản thu": cộng thu theo tháng/năm, gộp theo người trả, danh mục hoặc khoản thu; khoản thu nhiều đợt cho job
    freelance/hợp đồng (tổng thỏa thuận, các đợt dự kiến, đã nhận, còn lại, đợt kế tiếp, quá hạn); ghi lần nhận tiền tự
    tính thuế 10% bên trả khấu trừ. Giao dịch thu có trường "Thuế TNCN bị khấu trừ" và "Thuộc khoản thu".
  - Màn "Thuế thu nhập cá nhân": ước tính quyết toán năm từ sổ (biểu 5 bậc, giảm trừ 15,5 triệu/6,2 triệu từ 2026;
    biểu cũ cho năm trước), tính lương gross/net, hạn quyết toán và khai quý, phân loại thuế cho danh mục thu, bộ danh
    mục thu chuẩn; nhắc hạn bằng thông báo (tự bật).
  - "QR thanh toán": quét mã VietQR/EMVCo (camera trên Android/iOS/macOS, dán nội dung ở web/máy tính), kiểm CRC chống
    mã bị sửa, xem ngân hàng/số tài khoản/số tiền/nội dung, mở app ngân hàng điền sẵn (qua VietQR.io, hỏi đồng ý một
    lần), ghi khoản chi; tạo mã VietQR nhận tiền. Đọc được PromptPay, PayNow, DuitNow, QRIS, QR Ph, KHQR, UPI.
  - Chọn được mọi tiền tệ ISO 4217 (157 mã) bằng ô tìm kiếm có tên tiếng Việt.
  - Nhập dữ liệu từ app khác: tải tệp mẫu CSV/Excel, điền rồi nhập - tự tạo ví, danh mục, nhận chuyển ví, điều chỉnh,
    thuế khấu trừ, bỏ dòng trùng.
  - Đăng nhập: ba lối đúng chuẩn (Tiếp tục với Google, Tiếp tục với GitHub, Tài khoản tsudev) có nhãn "Lần trước bạn dùng
    cách này"; lối "Dùng ngay, không cần tài khoản" (chế độ khách). Máy chủ chuyển gợi ý lối tới tsudev.com
    (`idp_hint`). Apple ID chờ đề xuất chuẩn.
- Web + site (P8, ADR-0013): `qulythuchi.tsudev.com` có trang giới thiệu, Tính năng, Bảo mật và quyền riêng tư (máy
  chủ thấy gì, ngoại lệ email, quyền thông báo/máy ảnh/micro, ML Kit), Tải về; bản web của app ở `/app/` (PWA, cài
  lên màn hình chính, cũng là cách dùng trên iPhone). Một Worker phục vụ cả tệp tĩnh lẫn API; web app tự phục vụ mọi
  tài nguyên (không CDN), không service worker, CSP riêng. Favicon, icon PWA, ảnh chia sẻ sinh từ logo tsudev bằng
  dây chuyền thương hiệu (`apps/site/scripts/brand-assets.mjs`).
- Tự nhập + thông minh (P7, ADR-0012): màn "Tự nhập" và nút "Ghi nhanh" ở Tổng quan - gõ hoặc nói một câu ("ăn trưa
  50 nghìn", "hôm qua đổ xăng 80k", "nhận lương 15 triệu", "hai trăm rưỡi"), app tách số tiền/ngày/thu-chi và gợi ý
  danh mục; quét hóa đơn bằng OCR trên máy (Android/iOS, ảnh không rời máy); giọng nói nhận dạng trên máy, chỉ dùng
  dịch vụ hệ điều hành khi người dùng đồng ý. Đọc thông báo biến động số dư của app ngân hàng người dùng chọn
  (Android; hàng đợi mã hóa Keystore) thành giao dịch chờ xác nhận. Nhập sao kê CSV/XLSX: tự tìm bảng giao dịch, cột
  ghi nợ/ghi có, bỏ dòng đã có, gợi ý danh mục, tùy chọn vào hàng chờ. Email chuyển tiếp niêm phong (tắt mặc định,
  ngoại lệ E2EE có công bố): địa chỉ riêng 128 bit, máy chủ niêm phong ngay bằng khóa của người dùng, app mở trên máy.
  Gợi ý danh mục học từ lịch sử trên máy, cảnh báo ghi trùng. Widget "Ghi nhanh" trên màn hình chính Android (không
  hiển thị dữ liệu). Máy chủ: migration `0002_email_inbox`, API `/api/v1/inbox`, Email Worker.
- Đồng bộ trong app (P6): màn "Tài khoản & đồng bộ" - đăng nhập tsudev.com bằng trình duyệt hệ thống (PKCE; di động
  qua `com.tsudev.qulythuchi:/auth/callback`, máy tính qua vòng lặp 127.0.0.1), refresh token trong kho bí mật của
  thiết bị, đồng bộ nền (khi mở khóa, sau khi sửa, mỗi 10 phút, khi quay lại app) kéo trước - hợp nhất theo trường -
  đẩy sau, trạng thái và số thay đổi chờ gửi, danh sách/thu hồi thiết bị, dung lượng máy chủ, xuất dữ liệu máy chủ,
  xóa tài khoản (30 ngày, hủy được), đăng xuất giữ dữ liệu trên máy. Thiết bị mới "Đăng nhập để lấy dữ liệu đã đồng
  bộ" mở bằng mật khẩu mã hóa hoặc 24 từ. Bảo vệ: chỉ tin tập CA gốc ghim, không trộn hai khóa chủ, ghim vân tay danh
  tính, phát hiện máy chủ quay lui, bỏ bản ghi bị tráo, phát hiện đổi tài khoản TsuDEV (ADR-0011).
- Máy chủ đồng bộ zero-knowledge `services/sync-api` (P5) trên Cloudflare Workers + D1 + R2, chạy tại
  `https://qulythuchi.tsudev.com`: đăng nhập qua tsudev.com (OIDC + PKCE, mã một lần cho app, token truy cập 15 phút
  + làm mới xoay vòng phát hiện dùng lại, phiên web cookie `__Host-`), đẩy/kéo bản ghi đã mã hóa theo con trỏ `rev`
  (lũy đẳng, cô lập tài khoản), gói khóa tài khoản và khóa ví đã bọc, tệp đính kèm mã hóa trên R2, quản lý/thu hồi
  thiết bị, xuất dữ liệu máy chủ, xóa tài khoản có ân hạn 30 ngày, giới hạn tần suất và hạn mức, header bảo mật,
  CORS đúng gốc (ADR-0010).
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
