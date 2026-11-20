# IDENTITY - Quly Thu Chi trên cửa hàng (nguồn sự thật cho mọi kênh)

> Soạn 20/11/2026 (phiên `qulythuchi-dd7b`, phiếu toàn hệ `20261120-GP1`) TỪ MÃ NGUỒN, không bịa. Mỗi dòng ghi nguồn.
> Đổi hành vi app (quyền, dữ liệu, Pro) ⇒ sửa tệp này + `google-play.md` CÙNG PR (`STORE_SUBMISSION.md` mục 1.2).
> Chi tiết từng trường Play Console: [`google-play.md`](google-play.md).

## 1. Định danh

| Trường | Giá trị | Nguồn |
| --- | --- | --- |
| Tên sản phẩm | **Quly Thu Chi** (12 ký tự, giống nhau vi/en) | `AndroidManifest.xml` `android:label`; `apps/site/src/lib/site` |
| Package / mã app | `com.tsudev.qulythuchi` | `apps/app/android/app/build.gradle.kts` `applicationId`; `docs/PLAN.md` |
| Nhà phát triển | TsuDEV (tài khoản Play cá nhân `6673606179625007616`) | phiếu GP1 mục 1 |
| Danh mục | Ứng dụng › **Tài chính** (Finance) | bản chất app: sổ thu chi cá nhân |
| Website | `https://qulythuchi.tsudev.com` | ADR-0013 |
| Email liên hệ | `contact@tsudev.com` | chân trang site, `SECURITY.md` |
| Chính sách quyền riêng tư | `https://qulythuchi.tsudev.com/bao-mat` (phần riêng của app, dẫn tới `https://tsudev.com/privacy`) | `apps/site/src/pages/bao-mat.astro` |
| Xoá tài khoản / dữ liệu | Trang `https://qulythuchi.tsudev.com/bao-mat#xoa-tai-khoan` và `#xoa-du-lieu`: trong app Thêm › Tài khoản & đồng bộ › Xóa tài khoản đồng bộ (30 ngày đổi ý); tài khoản TsuDEV ở `https://tsudev.com/settings/security` | phiếu GP1 mục 4.2; ADR-0010 |
| Giấy phép | AGPL-3.0-only, mã nguồn `https://github.com/tsudev-org/qulythuchi` | ADR-0005 |
| Ngôn ngữ app | Tiếng Việt (mặc định), English | `apps/app/lib/l10n/*.arb` |
| Icon | `assets/store/play-icon-512.png` (sinh từ `assets/brand/source/logo-qulythuchi.png`) | `BRAND_ASSETS.md` mục 15 |

## 2. Câu chữ

**Mô tả ngắn** (≤ 80 ký tự):

- vi: `Sổ thu chi mã hóa đầu-cuối: ghi nhanh, ngân sách, báo cáo. Không quảng cáo.`
- en: `End-to-end encrypted money tracker: quick entry, budgets, reports. No ads.`

**Mô tả đầy đủ** (≤ 4000 ký tự) - vi:

```text
Quly Thu Chi ghi lại từng khoản tiền vào ra, lập ngân sách và cho bạn thấy tiền đi đâu. Mọi dữ liệu được mã hóa ngay trên thiết bị: kể cả máy chủ đồng bộ của chúng tôi cũng không đọc được.

GHI MỘT CÂU LÀ XONG
• Gõ hoặc nói "ăn trưa 50 nghìn", "hôm qua đổ xăng 80k": app tự tách số tiền, ngày, thu hay chi và gợi ý danh mục.
• Máy tính ngay trong ô số tiền, widget "Ghi nhanh" trên màn hình chính.

TỰ NHẬP TỪ NGÂN HÀNG
• Nhập sao kê CSV/XLSX, quét hóa đơn bằng nhận dạng chữ ngay trên máy.
• Với Pro: đọc thông báo biến động số dư của các app ngân hàng bạn tự chọn (cần bạn cấp quyền truy cập thông báo) và email chuyển tiếp.
• Mọi khoản tự nhập vào hàng chờ để bạn xác nhận trước khi ghi.

NGÂN SÁCH VÀ MỤC TIÊU
• Nhiều ví: tiền mặt, ngân hàng, thẻ tín dụng, ví điện tử, tiết kiệm; danh mục 2 tầng.
• Ngân sách theo kỳ và danh mục, phương pháp 6 hũ, mục tiêu tiết kiệm.
• Khoản định kỳ, hóa đơn có nhắc, sổ cho vay - đi vay, sự kiện, nhiều tiền tệ.
• Quét mã VietQR để ghi khoản chi, ước tính thuế thu nhập cá nhân.

BÁO CÁO DỄ ĐỌC
• Thu chi theo kỳ so với kỳ trước, cơ cấu danh mục, lịch chi tiêu, "an toàn để tiêu".
• Biểu đồ nào cũng có bảng số. Xuất CSV miễn phí; sao lưu tệp .qtbak đã mã hóa.

TIỀN LÀ CHUYỆN RIÊNG
• Dùng ngay không cần tài khoản, dữ liệu nằm trong cơ sở dữ liệu mã hóa trên máy.
• Khóa ứng dụng bằng mật khẩu, mã PIN hoặc sinh trắc; tự khóa khi rời app; che nội dung trong trình chuyển app.
• Không quảng cáo, không công cụ phân tích hành vi, không bán dữ liệu.
• Mã nguồn mở AGPL-3.0: ai cũng kiểm được cách mã hóa.

TSUDEV PRO (TÙY CHỌN)
Đồng bộ nhiều thiết bị và sao lưu đám mây mã hóa đầu-cuối, tạo ví chung cho gia đình, xuất PDF/XLSX, báo cáo nâng cao (nhiều kỳ, tài sản ròng), tự nhập từ thông báo ngân hàng và email chuyển tiếp là tính năng TsuDEV Pro: gói 1 năm, KHÔNG tự gia hạn. Hết hạn, app trở về bản miễn phí; dữ liệu trên thiết bị giữ nguyên. Cần đăng nhập tài khoản TsuDEV.

Bạn cũng có thể ủng hộ nhà phát triển bằng một khoản tùy chọn trong app.

Bảo mật và quyền riêng tư: https://qulythuchi.tsudev.com/bao-mat
```

**Mô tả đầy đủ** - en:

```text
Quly Thu Chi records every bit of money in and out, sets budgets and shows you where your money goes. Everything is encrypted on your device: even our sync server cannot read it.

ONE SENTENCE IS ENOUGH
• Type or say "lunch 50k", "fuel 80k yesterday": the app picks out the amount, date, income or expense and suggests a category.
• A calculator right in the amount field, plus a "Quick add" home screen widget.

AUTO-IMPORT FROM YOUR BANK
• Import CSV/XLSX statements, scan receipts with on-device text recognition.
• With Pro: read balance-change notifications from the banking apps you choose (needs notification access you grant) and email forwarding.
• Every imported item waits in a queue for you to confirm.

BUDGETS AND GOALS
• Multiple wallets: cash, bank, credit card, e-wallet, savings; two-level categories.
• Budgets by period and category, the 6-jar method, savings goals.
• Recurring items, bills with reminders, a lending and borrowing ledger, events, multiple currencies.
• Scan VietQR codes to record a payment, estimate Vietnamese personal income tax.

CLEAR REPORTS
• Income and spending per period versus the previous one, category breakdown, spending calendar, "safe to spend".
• Every chart comes with a data table. Free CSV export; encrypted .qtbak backup files.

MONEY IS PRIVATE
• Use it right away without an account; data lives in an encrypted database on your device.
• Lock the app with a password, PIN or biometrics; auto-lock when you leave; content hidden in the app switcher.
• No ads, no behavioural analytics, no selling of data.
• Open source under AGPL-3.0: anyone can audit the encryption.

TSUDEV PRO (OPTIONAL)
Multi-device sync and end-to-end encrypted cloud backup, shared family wallets, PDF/XLSX export, advanced reports (multi-period, net worth), importing from bank notifications and email forwarding are TsuDEV Pro features: a 1-year plan that does NOT renew automatically. When it expires, the app returns to the free version; data on your device stays intact. Requires a TsuDEV account.

You can also support the developer with an optional tip in the app.

Security and privacy: https://qulythuchi.tsudev.com/bao-mat
```

## 3. Hành vi thật (cơ sở cho tờ khai)

| Mục | Sự thật | Nguồn |
| --- | --- | --- |
| Quảng cáo | Không có SDK quảng cáo | `apps/app/pubspec.yaml`; `PRODUCT_POLICY.md` mục 3 |
| Phân tích / báo lỗi | Không có (không Firebase, Sentry, GlitchTip) | `pubspec.yaml` |
| Tài khoản | Không bắt buộc ("Dùng ngay, không cần tài khoản"). Đăng nhập qua tsudev.com: Google, GitHub hoặc tài khoản tsudev (email + mật khẩu) - chỉ để đồng bộ/Pro | ADR-0003, site `index.astro` |
| Dữ liệu tài chính | Mã hóa đầu-cuối (libsodium XChaCha20-Poly1305) trước khi rời máy; máy chủ chỉ giữ bản mã + siêu dữ liệu tối thiểu | ADR-0002, `bao-mat.astro` |
| Máy chủ giữ ở dạng đọc được | Từ OIDC: `sub`, email, tên hiển thị, URL ảnh đại diện (bảng `users`); danh sách thiết bị (tên, nền tảng, lần cuối hoạt động), mã cài đặt (`X-Tsu-Installation`), băm IP; tsudev.com giữ lịch sử mua Pro/ủng hộ | `services/sync-api/migrations/0001_init.sql`, `src/auth/routes.ts`, ADR-0019, `bao-mat.astro` |
| Email chuyển tiếp (Pro, tắt mặc định) | Thư đi qua Cloudflare ở dạng thường, máy chủ niêm phong ngay bằng khóa công khai người dùng, không ghi bản rõ | ADR-0012, `bao-mat.astro` |
| Mua hàng | Google Play Billing: `tsudev_pro` (gói trả trước `nam`), `ung_ho_20k/50k/100k/200k`; máy chủ quyền lợi tsudev.com ghi lịch sử mua | `apps/app/lib/pro/purchases.dart`, ADR-0016, ADR-0019 |
| Quyền Android | `INTERNET`, `USE_BIOMETRIC`, `RECORD_AUDIO` (ghi bằng giọng nói, chỉ xin khi bấm "Nói"), `RECEIVE_BOOT_COMPLETED` (nhắc hóa đơn), dịch vụ `BIND_NOTIFICATION_LISTENER_SERVICE` (người dùng tự bật, chỉ app ngân hàng đã chọn) | `AndroidManifest.xml` |
| Máy ảnh | Không xin quyền CAMERA; quét hóa đơn/QR qua `image_picker` (app máy ảnh hệ thống) + Google ML Kit trên máy | `pubspec.yaml`, `bao-mat.astro` |
| SDK bên thứ ba gửi dữ liệu | Google ML Kit có thể gửi số liệu sử dụng ẩn danh cho Google (không gồm ảnh/chữ); nhận dạng giọng nói của Google chỉ khi người dùng đồng ý mỗi lần; VietQR.io chỉ khi người dùng bấm "Mở app ngân hàng" | `bao-mat.astro` |
| Sao lưu Android | `allowBackup=false` | `AndroidManifest.xml` |
| Đối tượng | Người lớn (18+), quản lý tài chính cá nhân | bản chất app |
| Tính năng tài chính | CHỈ ghi chép/quản lý chi tiêu cá nhân; KHÔNG cho vay, đầu tư, ví tiền, chuyển tiền, ngân hàng (nút VietQR chỉ mở app ngân hàng của người dùng) | phiếu GP1 mục 3 |
