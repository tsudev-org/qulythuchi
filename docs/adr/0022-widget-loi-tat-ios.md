# ADR-0022: Widget "Ghi nhanh" và lối tắt nhấn giữ trên iOS

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0012 mục 11 - widget Android; không thay thế)
- **Ngày**: 24/11/2026
- **Người quyết định**: agent-qulythuchi (phiếu `logs/handover/20261124-01_viec-phien-sau.md` mục 1.4)
- **Liên quan**: `apps/app/ios/QuickWidget/**`, `apps/app/ios/Runner/SceneDelegate.swift`,
  `apps/app/ios/Runner.xcodeproj/project.pbxproj`, `.github/workflows/apple.yml`, `apps/app/lib/services/quick_links.dart`,
  `docs/security-reviews/20261124-widget-ios.md`

## 1. Bối cảnh

Android có widget ba nút Gõ/Nói/Quét (ADR-0012 mục 11). iOS chưa có lối vào Ghi nhanh từ ngoài app. Ràng buộc giữ
nguyên: widget nằm NGOÀI khoá app (hiện cả trên màn hình khoá) ⇒ không được hiển thị số dư hay dữ liệu D3 nào.

## 2. Quyết định

1. **WidgetKit extension** `QuickWidgetExtension` (`com.tsudev.qulythuchi.QuickWidget`, iOS 15.5 như app): cỡ nhỏ (chạm
   ⇒ Gõ), cỡ vừa (ba `Link` Gõ/Nói/Quét), màn hình khoá `accessoryCircular` (iOS 16+). Dòng thời gian tĩnh
   (`policy: .never`), **không App Group, không đọc dữ liệu app, không mạng** - widget không có gì để lộ.
2. **Quick Actions** (nhấn giữ biểu tượng app): đặt động trong `SceneDelegate` (tiêu đề vi/en theo ngôn ngữ máy); chọn ⇒
   mở chính liên kết ghi nhanh `com.tsudev.qulythuchi:/quick?mode=…` ⇒ `app_links` ⇒ `pendingQuickEntryProvider`, đi
   cùng đường với widget Android. App vẫn đòi mở khoá trước khi hiện Ghi nhanh.
3. **App Intents / Siri / nút Điều khiển iOS 18**: CHƯA làm - cần iOS 16+/18+, thêm bề mặt (Siri đọc tham số) mà lợi ích
   trùng với hai lối trên. Xét lại khi app phát hành trên App Store (Apple Developer Program, đầu 2027).
4. **Kiểm chứng**: `apple.yml` dựng iOS release thật và kiểm `.appex` được nhúng, đúng điểm mở rộng WidgetKit, đúng mã
   gói, cùng phiên bản với app. Thử bấm widget/lối tắt trên máy thật là việc nghiệm thu khi có bản iOS (chưa phát hành).

## 3. Hệ quả

- Thêm một target Xcode (sửa `project.pbxproj` bằng tay, pha "Embed Foundation Extensions" đặt TRƯỚC "Thin Binary" để
  tránh vòng lặp dựng của Flutter).
- Khi ký bản phát hành (2027) cần thêm App ID `com.tsudev.qulythuchi.QuickWidget` vào hồ sơ ký.
