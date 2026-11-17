# ADR-0003: Đăng nhập tsudev qua máy chủ Quly Thu Chi, mã một lần + PKCE cho app

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-qulythuchi (chủ dự án duyệt hướng chung 17/11/2026)

## 1. Bối cảnh
IdP tsudev.com dùng token mờ, tắt CORS, chưa có client native (đo ngày 17/11/2026, xem sound-db ADR-0003).

## 2. Quyết định
Dùng lại mẫu đã chạy ở sound-db: Worker là RP OIDC duy nhất (client `qulythuchi`, redirect
`https://qulythuchi.tsudev.com/auth/callback`), tự cấp mã một lần 60 giây ràng buộc PKCE S256 cho app (trình duyệt hệ
thống, không WebView; di động `com.tsudev.qulythuchi:/auth/callback`, desktop vòng lặp `127.0.0.1`). Token app: access
JWT 15 phút + refresh mờ xoay vòng 30 ngày, phát hiện dùng lại ⇒ thu hồi cả chuỗi. Mỗi thiết bị một bản ghi, thu hồi được.

Bổ sung cho mức D3:
- Ghim chứng chỉ: SPKI của tập CA mà Cloudflare dùng (Google Trust Services, Let's Encrypt, SSL.com) + ít nhất 1 ghim dự
  phòng; ghim lệch ⇒ chặn đồng bộ, không chặn dùng ngoại tuyến. Danh sách ghim cập nhật qua bản app mới.
- Web: cookie `__Host-` HttpOnly Secure SameSite=Strict, CSP không `unsafe-inline` cho script.
- Danh tính tsudev chỉ mở được **bản mã**; dữ liệu cần thêm mật khẩu mã hóa (ADR-0002).

## 3. Hệ quả
Chủ dự án đăng ký client OIDC `qulythuchi` (phiếu ở P5).
