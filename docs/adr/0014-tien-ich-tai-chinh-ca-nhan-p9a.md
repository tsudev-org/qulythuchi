# ADR-0014: P9a - tiện ích tài chính cá nhân (số dư theo kỳ, khoản thu nhiều đợt, thuế TNCN, QR thanh toán, tiền tệ ISO, nhập theo tệp mẫu, lối đăng nhập)

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 19/11/2026
- **Người quyết định**: agent-qulythuchi (theo yêu cầu chủ dự án 19/11/2026)
- **Liên quan**: `packages/core/lib/src/{money/iso4217.dart,domain/ledger.dart,domain/models.dart,tax/,payment/}`,
  `apps/app/lib/ui/{income,tax,payment,overview/period_card.dart,widgets/currency_field.dart,widgets/sign_in_buttons.dart}`,
  `apps/app/lib/services/import_template.dart`, `services/sync-api/src/auth/{oidc,routes}.ts`,
  `docs/security-reviews/20261119-p9a-tien-ich.md`; bổ sung ADR-0003, 0004, 0009

## 1. Bối cảnh
Chủ dự án yêu cầu thêm: chuyển số dư tháng trước sang tháng sau; chuẩn hóa mục thu và theo dõi thu nhập không cố định
(freelance nhận nhiều đợt); thông tin và nhắc hạn thuế TNCN; quét QR thanh toán đi thẳng app ngân hàng; chọn được mọi
tiền tệ; nhập dữ liệu từ app khác bằng tệp mẫu; đăng nhập Google/Apple, không đăng nhập thì là khách.

## 2. Quyết định
1. **Số dư theo kỳ TÍNH, không lưu** (giữ ADR-0004: số dư luôn tính từ giao dịch). `Ledger.periodSummary` trả đầu kỳ
   (= cuối kỳ trước), thu, chi, chuyển ròng, phí, điều chỉnh, cuối kỳ theo từng tiền tệ. "Chuyển số dư" là cách HIỂN
   THỊ (tùy chọn `carryOverBalance`, mặc định bật), không sinh giao dịch kết chuyển - tránh bút toán giả bị đồng bộ
   chồng/nhân đôi giữa thiết bị. Ngân sách vẫn dùng `rollover` riêng (P3).
2. **Khoản thu nhiều đợt** = bản ghi mới `income_plan` (cấp tài khoản, E2EE như mọi bản ghi) + trường giao dịch
   `incomePlanId`, `taxWithheld`. `amount` của giao dịch thu là số THỰC NHẬN (khớp số dư ví); `taxWithheld` lưu phần bên
   trả giữ lại, không ảnh hưởng số dư, dùng cho thu nhập trước thuế và quyết toán. Tiến độ/đợt kế tiếp/quá hạn tính từ
   giao dịch. Bản cũ của app đọc bản ghi mới: bỏ qua loại lạ, giữ nguyên trường lạ khi hợp nhất (HLC theo trường).
3. **Thuế TNCN là dữ liệu có phiên bản** (`VnPitRules.fromYear`): 2020 (7 bậc, 11tr/4,4tr) và 2026 (Luật 109/2025/QH15:
   5 bậc 5-35%, 15,5tr/6,2tr; ngưỡng hộ kinh doanh 500tr/năm; Nghị định 253/2026/NĐ-CP: khấu trừ vãng lai 10% từ
   5tr/lần). Văn bản mới ⇒ thêm bộ mới, KHÔNG sửa bộ cũ (quyết toán năm cũ dùng luật năm đó). Mỗi bộ ghi nguồn + ngày
   đối chiếu; giao diện luôn hiện "chỉ để tham khảo". Danh mục thu có `taxType`; danh mục con chưa phân loại theo cha.
   Hồ sơ thuế (người phụ thuộc, bảo hiểm, cư trú) là bản ghi `tax_profile` E2EE, UUID cố định.
4. **QR thanh toán đọc/tạo hoàn toàn trên máy**: bộ đọc EMVCo MPM trong lõi, BẮT BUỘC kiểm CRC-16 (mã bị sửa ⇒ từ chối,
   cảnh báo không thanh toán); nhận VietQR (GUID A000000727), PromptPay, PayNow, DuitNow, QRIS, QR Ph, KHQR, UPI; số tiền
   đọc bằng số nguyên theo chữ số thập phân của tiền tệ (thẻ 53 ⇒ bảng ISO 4217), không làm tròn. Tạo mã VietQR nhận
   tiền tại máy, không lưu số tài khoản.
5. **Mở app ngân hàng qua `dl.vietqr.io` CHỈ khi người dùng đồng ý một lần**: Android/iOS không có chuẩn chung để
   chuyển lệnh VietQR sang app ngân hàng; liên kết của VietQR.io (Casso) hỗ trợ ~33 app có điền sẵn. Gửi đi chỉ gồm
   số tài khoản NGƯỜI NHẬN, số tiền, nội dung - không dữ liệu sổ. Không đồng ý ⇒ vẫn sao chép từng trường hoặc quét lại
   bằng app ngân hàng. Danh bạ BIN sinh từ dữ liệu công khai, đóng gói trong app (không gọi API lúc chạy).
6. **Camera quét QR** dùng `mobile_scanner` trên Android/iOS/macOS. Web KHÔNG bật (thư viện ZXing của gói tải từ CDN,
   trái CSP `script-src 'self'` của `/app/` - ADR-0013) và Windows/Linux chưa có plugin ⇒ dán nội dung mã.
7. **Tiền tệ**: bảng ISO 4217 đầy đủ (157 mã đang lưu hành) trong lõi; bản ghi tiếp tục lưu `currency` + chỉ thêm
   `currencyDigits` khi mã KHÔNG thuộc ISO (tương thích ngược). Bộ chọn có tìm kiếm không dấu.
8. **Nhập theo tệp mẫu**: tệp mẫu CSV (UTF-8 BOM) / XLSX có cột cố định (vi hoặc en); khi đọc tệp có đủ Ngày, Loại,
   Số tiền, Ví ⇒ tự ánh xạ, tạo ví (kèm khóa ví mới) và danh mục còn thiếu, nhận chuyển ví, điều chỉnh, thuế khấu trừ,
   bỏ dòng trùng; mọi bản ghi kiểm hợp lệ TRƯỚC rồi ghi trong một giao tác. Tệp khác vẫn đi luồng ghép cột của P4.
9. **Lối đăng nhập**: màn chào và "Tài khoản & đồng bộ" có ĐỦ ba lối đúng thứ tự `AUTH_AND_ACCOUNT.md` mục 3 (Google,
   GitHub, tài khoản tsudev) + nhãn "Lần trước bạn dùng cách này", và lối "Dùng ngay, không cần tài khoản" (chế độ khách
   - đủ chức năng, không gọi mạng, mục 14). Cả ba đi qua IdP tsudev.com; máy chủ chỉ nhận `provider ∈ {google, github}`
   và chuyển thành tham số `idp_hint` cho tsudev.com (IdP chưa hỗ trợ thì bỏ qua - vẫn hiện đủ lối). **Apple ID KHÔNG
   làm**: mục 3 cấm thêm nhà cung cấp thứ tư khi chưa có đề xuất được duyệt; iOS còn hoãn phát hành. Đã mở đề xuất
   (xem mục 4).

## 3. Hệ quả
- Thêm hai loại bản ghi (`income_plan`, `tax_profile`) và ba trường (`incomePlanId`, `taxWithheld`, `taxType`) - không
  đổi phong bì, không đổi máy chủ ngoài tham số `provider`.
- Số liệu thuế lỗi thời là rủi ro chính ⇒ ghi nguồn + ngày, có test cho từng bậc; mỗi đầu năm cần đối chiếu lại.
- Thêm phụ thuộc `mobile_scanner` (ML Kit barcode trên Android) và `qr` (đã có gián tiếp qua `pdf`).

## 4. Việc mở
- Phiếu cho repo tsudev (QT4): IdP nhận `idp_hint` (google/github) - ĐÃ GỘP tsudev#326 (19/11/2026).
- Đề xuất tsudev-standards: thêm "Đăng nhập với Apple" (bắt buộc theo App Store 4.8 khi phát hành iOS có Google).
- Quét QR trên web: tự phục vụ ZXing (có checksum, như sodium.js) hoặc dùng `BarcodeDetector` khi trình duyệt có.
