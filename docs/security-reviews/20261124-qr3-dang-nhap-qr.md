# PHIẾU RÀ SOÁT BẢO MẬT - Đăng nhập bằng mã QR (QR3) + màn chào `TsuSignInScreen` (ADR-0023)

- **PR / nhánh**: `feat/qr3-dang-nhap-qr`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (uỷ quyền cho agent)
- **Ngày**: 24/11/2026
- **Căn cứ**: ADR-0023, ADR-0003, `.standards/docs/CROSS_DEVICE_LOGIN.md` v1.1.0 mục 3, `SECURITY_BASELINE.md`,
  AGENTS.md B.5

## 1. Thay đổi này đụng vào đâu

- [x] Xác thực (lối vào đăng nhập mới) - [ ] Phân quyền - [ ] Tải tệp - [ ] CSDL - [x] Gọi dịch vụ ngoài (mở URL
  tsudev.com trong trình duyệt hệ thống)
- [x] Đầu vào không tin cậy (nội dung mã QR từ camera)
- [ ] Mã hoá / khoá E2EE - KHÔNG đổi

## 2. Ca tấn công đã cân nhắc

1. **QR độc giả tên miền (T9)**: chỉ `TsuXdLink.parse` quyết định; nhận đúng `https://tsudev.com/x/<22>?f=d#<43>`,
   từ chối `tsudev.com.evil.io`, http, cổng, userinfo, tham số thừa, thiếu bí mật. Sai ⇒ chỉ báo, không mở liên kết.
   Test `qr_sign_in_test.dart` 10 mẫu xấu.
2. **Nhầm tài khoản / login CSRF (T3)**: kẻ gian cho nạn nhân quét QR từ PC của kẻ gian. Trang `/x/<id>` của IdP hiện
   email che + "Đúng tài khoản của tôi" trước khi cấp phiên, cộng mã khớp hiện trên PC (T4). Thêm ở app: tài khoản có dữ
   liệu trên máy chủ vẫn đòi mật khẩu/24 từ ⇒ không đọc được dữ liệu của ai khác; ví mới tạo sẽ hiện đúng email ở Tài
   khoản.
3. **Lộ bí mật QR**: bí mật nằm sau `#` (không vào log máy chủ); app không ghi URL ra log/toast/analytics; chỉ truyền
   cho trình duyệt hệ thống. Thông báo lỗi trình duyệt không chứa URL.
4. **Khoá E2EE qua QR**: KHÔNG - QR chỉ cấp phiên tsudev.com; mã uỷ quyền vẫn đổi qua máy chủ đồng bộ với PKCE
   (ADR-0003). Khoá dữ liệu mở bằng mật khẩu/24 từ như cũ.
5. **Camera**: xin quyền khi người dùng bấm quét; không chụp/lưu ảnh; `NSCameraUsageDescription` cập nhật đúng mục đích.
6. **Ô đồng ý (13.4)**: không tích sẵn; lối vào đăng nhập/quét đều qua bảng đồng ý; khách không bắt tích.
7. **Chuỗi cung ứng**: `tsudev_ui` ghim tag `v0.4.0` (repo tsudev-org); không thêm gói mới.

## 3. Kiểm chứng

- `flutter analyze --fatal-infos` sạch; `flutter test` toàn bộ đạt (gồm `qr_sign_in_test.dart`: classify Đ1/Đ2/T9,
  luồng quét ⇒ trình duyệt ⇒ Tiếp tục ⇒ đăng nhập, huỷ/không mở trình duyệt ⇒ không đăng nhập, ô đồng ý + bảng, Tối).
- `theme_nav_contrast_test.dart` vẫn đạt sau khi chuyển sang `tsuNavigationBarTheme`.

## 4. Kết luận

Chấp nhận. Còn lại: 👤 E2E Đ1 trên điện thoại thật; vai xác nhận Đ2 chờ QR2b.
