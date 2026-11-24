# PHIẾU YÊU CẦU QR1 + UI1 + DK2 - qulythuchi

- **Mã phiếu**: 20261124-QR1 (bản sao cho repo) - **Từ**: điều phối `projects-71`, 24/11/2026 - **Trạng thái**: MỞ
- **Phiếu gốc** (đọc phần liên quan): `~/projects/logs/handover/20261124-QR1_dang-nhap-qr-giao-dien-thong-nhat-toan-he.md`,
  `20261124-UI1_bieu-tuong-kho-thay-toan-he.md`, `20261124-DK2_dang-ky-bct-tin-nhiem-mang-chong-lua-dao.md`.
- **Chuẩn**: tsudev-standards **v5.1.0** - `CROSS_DEVICE_LOGIN.md`, `AUTH_AND_ACCOUNT.md` 3.0/13.2/13.4,
  `DESIGN_SYSTEM.md` 1 (biểu tượng trên viên chỉ báo), `LANGUAGE_SELECTION.md` 5.1, `PROJECT_STRUCTURE.md` 3.1,
  `BRAND_ASSETS.md` 12.3.
- **Hạng / loại**: B - Flutter

## Việc của repo này

1. **QR3**: thay màn chào bằng `TsuSignInScreen` (giữ "Dùng ngay, không cần tài khoản", "Khôi phục từ tệp sao lưu"), thêm ô đồng ý, "Quét để đăng nhập" (Đ1), "Quét QR" ở Tài khoản (Đ2); màn Ủng hộ cùng khung. QR chỉ cấp phiên tài khoản - khoá E2EE KHÔNG đi qua QR. **UI1**: lỗi đã xác nhận ở `apps/app/lib/theme/app_theme.dart` (thanh Tổng quan/Giao dịch/Kế hoạch/Ví/Thêm)
2. **STD-SYNC** trong PR kế tiếp (không PR riêng): sync v5.1.0, bật cổng Clean Codebase (mã chết/phụ thuộc thừa) và
   ngân sách tốc độ; liên kết về tsudev.com kèm dấu hiệu TsuDEV + favicon đủ bộ.
3. Rà **UI1** cả Sáng/Tối: biểu tượng trên nền thật ở mọi trạng thái ≥ 3:1, thêm test chặn tái phát (nếu có giao diện).

Repo có phiên riêng ⇒ phiên đó làm; ghi kết quả một dòng dưới đây + dòng tương ứng ở phiếu gốc; `akb` theo chuẩn.

## Kết quả xử lý

- 24/11/2026 - projects-71: mở phiếu.
- 24/11/2026 - agent-qulythuchi (phiên `qulythuchi-07`): **UI1 xong** - `app_theme.dart` khai đủ
  `primary/secondary/tertiaryContainer` + `on*Container` (primary 14% trên nền thẻ, đục), `NavigationBarThemeData.iconTheme`
  /`labelTextStyle` theo `WidgetState` (chọn ⇒ `primary`, còn lại `iconNav`), `NavigationRail` cùng cặp màu. Test chặn
  tái phát `apps/app/test/theme_nav_contrast_test.dart` đo màu IconTheme thật ≥ 3:1 Sáng/Tối (bản cũ: 1,19:1 và 1,21:1
  ⇒ đỏ). QR3 + STD-SYNC v5.1.0: CHƯA làm, chuyển phiếu bàn giao kế tiếp.
