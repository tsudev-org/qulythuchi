# ADR-0023: Đăng nhập bằng mã QR (QR3, vai thiết bị mới) + màn chào thống nhất `TsuSignInScreen`

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0003 - đăng nhập OIDC qua máy chủ; không thay thế)
- **Ngày**: 24/11/2026
- **Người quyết định**: agent-qulythuchi (phiếu `logs/handover/20261124-02_viec-phien-sau.md` mục 1.4, phiếu toàn hệ
  `20261124-QR1` phase QR3)
- **Căn cứ**: tsudev-standards v5.3.0 `CROSS_DEVICE_LOGIN.md` v1.1.0, `AUTH_AND_ACCOUNT.md` 13.2 + 13.4
- **Liên quan**: `apps/app/lib/ui/account/xd_scan.dart`, `apps/app/lib/ui/onboarding/onboarding.dart`,
  `apps/app/lib/ui/account/account_page.dart`, `apps/app/test/qr_sign_in_test.dart`,
  `docs/security-reviews/20261124-qr3-dang-nhap-qr.md`, THREAT_MODEL T34

## 1. Bối cảnh

tsudev.com (IdP) đã chạy đăng nhập chéo thiết bị (tsudev#374): trang `/x/<id>` hai vai, vé một lần đổi thành phiên
tsudev.com. `tsudev_ui` v0.4.0 có `TsuSignInScreen` (13.2 + ô đồng ý 13.4) và `TsuXdLink.parse` (T9). Chuẩn đòi RP
KHÔNG tự dựng phiên QR, chỉ mở URL đã quét trong trình duyệt hệ thống rồi đi OIDC như cũ.

## 2. Quyết định

1. **Màn chào = `TsuSignInScreen`**: lối vào lấy từ IdP (`/api/v1/auth/providers`, ADR như STD43) + "Tài khoản tsudev";
   ô đồng ý KHÔNG tích sẵn, bấm lối vào khi chưa tích ⇒ bảng "Đồng ý và tiếp tục"; "Dùng ngay, không cần tài khoản"
   (khách) không bắt tích; "Khôi phục từ tệp sao lưu" ở `extra`. Liên kết dùng `tsudev.com/terms`, `/privacy` (đường
   `/dieu-khoan`, `/quyen-rieng-tu` của 13.1 còn 404 ngày 24/11 - đổi khi IdP có).
2. **"Quét để đăng nhập" (Đ1) chỉ Android/iOS** (màn chào + Tài khoản khi chưa đăng nhập): `mobile_scanner` (đã có cho QR
   thanh toán; quyền camera xin lúc mở màn quét) ⇒ `TsuXdLink.parse`: không hợp lệ ⇒ "Mã QR này không phải của tsudev.",
   KHÔNG mở gì; mã Đ2 (`f=k`) ⇒ báo dùng máy đã đăng nhập; mã Đ1 (`f=d`) ⇒ mở CHÍNH URL đó bằng
   `LaunchMode.externalApplication` - cùng trình duyệt mà luồng OIDC của app dùng (`login_launcher_io.dart`) ⇒ người
   dùng xác nhận tài khoản + gõ mã trên trang IdP ⇒ quay lại bấm "Tiếp tục" ⇒ app chạy `signIn()` như cũ, IdP đã có
   phiên nên trả mã ngay.
3. **QR KHÔNG mang khoá E2EE**: chỉ cấp phiên tài khoản. Sau đăng nhập, tài khoản có dữ liệu vẫn đi
   `signInAndRestoreFlow` (mật khẩu hoặc 24 từ). Hộp thoại "Tiếp tục" nói rõ điều này.
4. **Vai XÁC NHẬN trong app (Đ2) CHƯA làm**: chờ QR2b (IdP nhận access token OIDC cho `scan/approve`).
5. **Máy tính/web**: không có nút quét; dùng khung "Mã QR" ở trang đăng nhập IdP trong luồng `/authorize` (không sửa gì).
6. Nâng `tsudev_ui` v0.2.0 ⇒ v0.4.0; theme điều hướng dùng `tsuNavigationBarTheme`/`tsuNavigationRailTheme` (phiếu UI1).

## 3. Hệ quả

- Không thêm phụ thuộc mới (mobile_scanner, url_launcher có sẵn). Không đổi máy chủ đồng bộ, không migration.
- Trang Tài khoản chưa có ô đồng ý 13.4 (dùng `SignInButtons` cũ) - việc sau: chuyển sang `TsuSignInScreen` khi đổi bố
  cục trang Tài khoản.
- Nghiệm thu E2E Đ1 trên máy thật (PC đã đăng nhập hiện QR ở `/settings/security#qr`, điện thoại quét) là việc 👤.
