# Google Play Console - hồ sơ Quly Thu Chi (`com.tsudev.qulythuchi`)

> Phiếu toàn hệ `~/projects/logs/handover/20261120-GP1_*` mục 4. Nguồn chữ: [`IDENTITY.md`](IDENTITY.md).
> Điền 20-21/11/2026 (phiên `qulythuchi-dd7b`) bằng `~/projects/logs/tools/browser/tsb.sh` hồ sơ `play`; mỗi trang
> đã đọc lại bằng `fields` và đối chiếu. Chưa có nút gửi/phát hành nào được bấm.

## Khởi động (phiên sau)

`tsb.sh status` → `tsb.sh run play <bước>.cjs --as qulythuchi-<phiên>` → `fields` → đối chiếu tệp này → lưu nháp →
`tsb.sh release play`. Mã app Play: **4975262284467716976** (tài khoản nhà phát triển `6673606179625007616`).

Bẫy đã gặp: chữ có dấu trong vài danh sách thả xuống là Unicode NFD (so khớp phải `normalize('NFC')`); nhóm trong
An toàn dữ liệu là accordion (chỉ nhóm đang mở có ô); thanh dưới cố định che tiêu đề ở đáy trang (cuộn `block:center`);
tải ảnh qua bảng "Tải lên" bên phải, tệp phải nằm trên ổ C: (`tsudev-browser\tmp\`).

## Bước 1 - Tạo ứng dụng ✅

| Trường | Giá trị |
| --- | --- |
| Tên ứng dụng | Quly Thu Chi (12/30) |
| Tên gói | com.tsudev.qulythuchi ("Tên gói có sẵn") |
| Ngôn ngữ mặc định | Tiếng Việt – vi |
| Ứng dụng / Miễn phí | Ứng dụng, Miễn phí |
| Cam kết | Chính sách chương trình nhà phát triển ✓, Luật xuất khẩu Hoa Kỳ ✓ |
| Tự động bảo vệ (installer check) | để mặc định (bật) - chỉ áp bản tải từ Play; APK ngoài Play ký khoá khác nên không bị ảnh hưởng |

## Bước 2 - Nội dung ứng dụng ✅ (11/11 tờ khai) + Cài đặt cửa hàng ✅

| Tờ khai | Giá trị | Cơ sở |
| --- | --- | --- |
| Chính sách quyền riêng tư | `https://qulythuchi.tsudev.com/bao-mat` | IDENTITY 1 |
| Quảng cáo | Không | không SDK quảng cáo |
| Thông tin đăng nhập | Có hạn chế. Bộ "Google Play review account (TsuDEV Pro)": hướng dẫn tiếng Anh (441 ký tự, dưới đây); ô "truy cập đầy đủ" ✓; cho Google dùng để kiểm thử trước ra mắt: bật. **👤 điền tên đăng nhập + mật khẩu** của tài khoản tsudev MEMBER riêng cho Google, đã cấp Pro, TRƯỚC khi gửi duyệt | GP1 4.2 |
| Mức phân loại nội dung (IARC) | Email `contact@tsudev.com`; "Mọi loại ứng dụng khác"; nội dung tải xuống: Không; chia sẻ nội dung người dùng: **Có** (ví chung: ghi chú/ảnh hóa đơn giữa người được mời) - không phải nguồn chính, không khỏa thân/bạo lực công khai, chặn được (chủ ví thu hồi thành viên), không báo cáo, không kiểm duyệt chat, giới hạn "bạn bè được mời"; nội dung trực tuyến: Không; hàng giới hạn tuổi: Không; vị trí chính xác: Không; mua hàng kỹ thuật số: **Có**, không ngẫu nhiên; phần thưởng tiền/NFT: Không; trình duyệt: Không; giáo dục/tin tức: Không. Kết quả: PEGI 3, ESRB Everyone, ClassInd 14+, "Người dùng tương tác", "Mua hàng trong ứng dụng" | mã app |
| Đối tượng mục tiêu | 18 tuổi trở lên | app tài chính |
| An toàn dữ liệu | Xem mục dưới | mã máy chủ + app |
| Mã nhận dạng quảng cáo | Không | manifest không có `AD_ID` |
| Ứng dụng chính phủ | Không | |
| Tính năng tài chính | Khác: "Sổ ghi chép thu chi và lập ngân sách cá nhân do người dùng tự nhập; ứng dụng không xử lý tiền thật. Không cho vay, không thanh toán, không chuyển tiền, không đầu tư, không ví điện tử." Không cần tài liệu | GP1 mục 3 |
| Sức khoẻ | Không có tính năng sức khoẻ | |
| Tư cách người bán | Có (app bán Pro); Điều khoản dịch vụ `https://tsudev.com/terms` | |
| Danh mục | Ứng dụng › Tài chính; thẻ: chưa chọn (tùy chọn) | IDENTITY 1 |
| Liên hệ | `contact@tsudev.com`, `https://qulythuchi.tsudev.com`, không số điện thoại | IDENTITY 1 |

Hướng dẫn cho người duyệt (nguyên văn, khớp nhãn thật `welcomeGuest`/`signInTsudev`/`syncTitle` trong `app_en.arb`):

```text
All on-device features work without an account: on the welcome screen tap "Use now without an account" and create any encryption password. TsuDEV Pro features (cloud sync, shared wallets, PDF/XLSX export, advanced reports, bank-notification and email import) need sign-in: on the welcome screen tap "tsudev account (email)" (or later More > Account & sync) and use the username and password above. This review account already has TsuDEV Pro.
```

### An toàn dữ liệu

Quy tắc Google (đọc 20/11/2026, support.google.com/googleplay/android-developer/answer/10787469): dữ liệu mã hóa
đầu-cuối mà nhà phát triển không đọc được KHÔNG tính là thu thập ⇒ giao dịch, ví, ghi chú, ảnh hóa đơn không khai.
Dữ liệu xử lý tạm thời vẫn phải khai (không hiện trên Play). Cloudflare là nhà cung cấp dịch vụ ⇒ không tính "chia sẻ".

- Thu thập/chia sẻ: Có. Mã hóa khi truyền: Có. Tạo tài khoản: Tên người dùng và mật khẩu (tsudev email) + OAuth (Google, GitHub).
- URL xoá tài khoản: `https://qulythuchi.tsudev.com/bao-mat#xoa-tai-khoan`; xoá một phần dữ liệu: Có,
  `https://qulythuchi.tsudev.com/bao-mat#xoa-du-lieu` (mục mới trên trang bảo mật - phải lên production trước khi gửi duyệt).
- Không chia sẻ dữ liệu với bên thứ ba.

| Loại | Thu thập | Tạm thời | Bắt buộc? | Mục đích | Nguồn trong mã |
| --- | --- | --- | --- | --- | --- |
| Tên | ✓ | Không | Tùy chọn | Chức năng, Quản lý tài khoản | `users.display_name` (OIDC) |
| Địa chỉ email | ✓ | Không | Tùy chọn | Chức năng, Quản lý tài khoản | `users.email` |
| Mã nhận dạng người dùng | ✓ | Không | Tùy chọn | Chức năng, Quản lý tài khoản | `users.oidc_sub` |
| Nhật ký mua hàng | ✓ | Không | Tùy chọn | Chức năng | Pro/ủng hộ qua tsudev.com (ADR-0019) |
| Email (thư) | ✓ | **Có** | Tùy chọn | Chức năng | hộp thư chuyển tiếp, niêm phong ngay (ADR-0012) |
| Thông tin chẩn đoán | ✓ | Không | Tùy chọn | Phân tích | Google ML Kit (OCR/QR) |
| Mã thiết bị hoặc mã khác | ✓ | Không | Tùy chọn | Chức năng, Phân tích, Chống lừa đảo/bảo mật, Quản lý tài khoản | `devices`, `X-Tsu-Installation`, ML Kit, băm IP |

## Bước 3 - Trang thông tin cửa hàng ✅ (đã Lưu, chưa gửi)

| Trường | vi (mặc định) | en-US |
| --- | --- | --- |
| Tên | Quly Thu Chi | Quly Thu Chi |
| Mô tả ngắn | IDENTITY 2 (75/80) | IDENTITY 2 (74/80) |
| Mô tả đầy đủ | IDENTITY 2 (2054/4000) | IDENTITY 2 (2166/4000) |
| Biểu tượng | `assets/store/play-icon-512.png` (512, PNG 32-bit) | dùng bản mặc định |
| Ảnh đầu trang | `assets/store/play-feature-1024x500.png` (PNG 24-bit) | dùng bản mặc định |
| Ảnh điện thoại | `assets/store/play-phone-vi-{1-tong-quan,2-giao-dich,3-bao-cao}.png` (1080x1920) | dùng bản mặc định |
| Khai thành phần do AI tạo | Không gắn nhãn | |

Biểu tượng + ảnh đầu trang sinh bằng `npm --prefix apps/site run brand` (dây chuyền thương hiệu, `--check` trên CI).
Ảnh điện thoại: chụp bản web thật `qulythuchi.tsudev.com/app/` ở 360x640 @3x, chế độ khách, dữ liệu HƯ CẤU nhập tay
(9 giao dịch), không tài khoản/email. Khi có bản Android (P10) ⇒ thay bằng ảnh chụp máy thật, thêm ≥ 4 ảnh để đủ điều
kiện quảng bá, bản en.

## Bước 4 - Kiếm tiền ⛔ DỪNG (cần 👤)

Play từ chối tạo sản phẩm khi:

1. **Chưa có hồ sơ thanh toán** (Thiết lập tính năng kiếm tiền: "Để bắt đầu, hãy thiết lập hồ sơ thanh toán") ⇒ 👤.
2. **Chưa có bản tải lên có quyền BILLING** ("Để thêm các sản phẩm tính phí một lần, bạn cần thêm quyền THANH TOÁN vào
   tệp APK") ⇒ cần AAB ký bằng khoá tải lên (👤 khoá ký Android, P10), tải vào kênh Thử nghiệm nội bộ.

Khi xong 1-2, phiên sau tạo đúng: thuê bao `tsudev_pro` - một gói cơ sở **trả trước** `nam` (P1Y, 490.000 ₫), KHÔNG
tạo `thang`; sản phẩm một lần `ung_ho_20k`, `ung_ho_50k`, `ung_ho_100k`, `ung_ho_200k` (20/50/100/200 nghìn ₫) - khớp
`apps/app/lib/pro/purchases.dart`. RTDN: chờ tsudev A6.

## Bước 4a - Thử nghiệm nội bộ (23/11/2026, phiên `qulythuchi-1f`)

- AAB `qulythuchi_26.11.2304-beta.1_android-universal.aab` (artifact `play-aab` của Release `v26.11.2304-beta.1`, khoá
  upload `41:86:5C:BF:...:64:84`) - 👤 tải lên tay vì Playwright qua CDP không chuyển tệp > 50 MB. Play nhận: mã phiên
  bản 26112304, API 24+, SDK mục tiêu 36, 3 ABI; cài mới 24 MB.
- Tên bản `26.11.2304-beta.1`; ghi chú `<vi>`/`<en-US>` (Play dùng mã `vi`, KHÔNG `vi-VN`). ĐÃ LƯU NHÁP, đang ở trang
  "Xem trước và xác nhận": 0 lỗi, 1 cảnh báo "chưa chỉ định người thử nghiệm". CHƯA bấm "Lưu và xuất bản".
- 23/11/2026 21:03: 👤 xác nhận bằng lời trong phiên ⇒ agent chọn danh sách sẵn có **"TsuDev Compass noi bo"** (6 người,
  dùng chung với app-la-ban) và bấm "Lưu và xuất bản" (`tsb --allow "Lưu và xuất bản"`). Kênh **Đang hoạt động**, bản
  `26.11.2304-beta.1` "Đã phát hành cho những người thử nghiệm nội bộ". Link tham gia:
  <https://play.google.com/apps/internaltest/4700541829715107418>. Tên tạm trên Play: `com.tsudev.qulythuchi
  (unreviewed)` cho tới khi app được duyệt.

## Bước 4b - Sản phẩm (23/11/2026, phiên `qulythuchi-1f`) - ĐANG HOẠT ĐỘNG

Hồ sơ thanh toán: ĐÃ CÓ ở cấp tài khoản nhà phát triển (trang Gói thuê bao / Sản phẩm một lần không còn chặn) - không
tạo mới. Đã tạo, tất cả **Bản nháp, chưa kích hoạt**:

| Mã | Loại | Chi tiết | Giá VN (Play tự quy đổi 173-178 khu vực khác) |
| --- | --- | --- | --- |
| `tsudev_pro` "TsuDEV Pro" | Thuê bao | Gói cơ sở `nam`: 1 năm, **trả trước**, cho phép gia hạn trên Play | 490.000 ₫ |
| `ung_ho_20k` / `50k` / `100k` / `200k` | Một lần | Lựa chọn mua `mua` (Mua, tương thích ngược), nội dung kỹ thuật số; tên "Ủng hộ TsuDEV 20.000 ₫"..., mô tả = `donateBody` của app | 20.000 / 50.000 / 100.000 / 200.000 ₫ |

Bẫy: nhãn nút ("Tiếp tục", "Lưu dưới dạng bản nháp") và ô tìm quốc gia là Unicode NFD, ô tìm dùng `aria-label` ⇒ tìm
bằng `normalize('NFC')`; KHÔNG bấm theo toạ độ ở thanh dưới (cùng vị trí với "Kích hoạt").

Lợi ích gói `tsudev_pro` (23/11): "Đồng bộ đám mây mã hoá đầu-cuối", "Ví chung, mời người nhà", "Đồng bộ ảnh hoá
đơn", "Dùng cho mọi ứng dụng TsuDEV" (rút từ `proFeat*` của app).

**Tài khoản dịch vụ B2** (23/11/2026): `play-billing-b2@tsudev-com.iam.gserviceaccount.com` (project Google Cloud
`tsudev-com`, 👤 tạo + đặt khoá vào `PLAY_SERVICE_ACCOUNT_JSON` của Render `tsudev-backend`). Agent mời vào Play
Console (Người dùng và quyền), CHỈ app Quly Thu Chi, quyền: xem thông tin app + chất lượng (chỉ đọc, mặc định), **Xem dữ
liệu tài chính**, **Quản lý đơn đặt hàng và gói đăng ký**. Lúc mời, Play Developer API còn trả 401 (quyền chưa lan
truyền) ⇒ B2 503; **24/11/2026 00:44 (sau ~1 giờ 50 phút) ĐẠT**: `services/sync-api/scripts/thu-b2-play.mjs` với
purchase token giả ⇒ `422 purchase_invalid` cho cả `ung_ho_20k` và `tsudev_pro` (Google đã trả lời).

**23/11/2026 (👤 uỷ quyền bằng lời trong phiên):** Thử nghiệm giấy phép (cấp TÀI KHOẢN, áp cho mọi app - đã báo phiên
app-la-ban) = danh sách "TsuDev Compass noi bo"; gói `nam` **Đang hoạt động**; `ung_ho_20k/50k/100k/200k` mỗi gói 1
lựa chọn mua đang hoạt động. Người thử nghiệm mua = giao dịch thử, không trừ tiền.

### Thử mua đầu-cuối trên điện thoại (👤 - phía máy chủ đã sẵn sàng)

1. Điện thoại Android, tài khoản Google nằm trong danh sách "TsuDev Compass noi bo"; mở link tham gia thử nghiệm nội
   bộ (bước 4a) ⇒ cài Quly Thu Chi từ Play.
2. Trong app: đăng nhập tài khoản tsudev ⇒ Thêm ⇒ TsuDEV Pro và Ủng hộ ⇒ "Mua 1 năm". Hộp thoại Play phải ghi "Đơn đặt
   hàng thử nghiệm" ⇒ chọn thẻ thử "Luôn chấp thuận".
3. Mong đợi: app báo Pro còn hạn tới (hôm nay + 1 năm); tsudev.com/pro hiện cùng hạn; Play Console > Đơn đặt hàng có
   đơn thử. Lặp với "Ủng hộ 20.000 ₫" ⇒ huy hiệu Ủng hộ.
4. Thử thẻ "Luôn từ chối" ⇒ app báo không thành công, không cấp Pro.

Trước khi mở bán cho người dùng thật (bản production): (1) ĐÃ XONG kiểm thử giấy phép; (2) `scripts/thu-b2-play.mjs` ĐẠT (hết 503 - nếu còn 503 thì người mua trả tiền nhưng không nhận Pro; Play tự hoàn
tiền sau 3 ngày vì giao dịch không được xác nhận); (3) điều khoản Pro 7.5 hiện trong app.

## Việc 👤 trước khi gửi duyệt

- [ ] Tài khoản tsudev MEMBER riêng cho người duyệt Google, cấp Pro, điền tên đăng nhập/mật khẩu ở "Thông tin đăng nhập".
- [x] Hồ sơ thanh toán Google Payments (đã có ở cấp tài khoản, 23/11/2026).
- [x] Khoá ký Android ⇒ AAB đầu tiên (P10, 23/11/2026).
- [x] Danh sách người thử nghiệm nội bộ + xuất bản (23/11/2026).
- [x] Tạo sản phẩm - bản nháp (bước 4b).
- [ ] Kiểm thử giấy phép + `PLAY_SERVICE_ACCOUNT_JSON` ⇒ kích hoạt ⇒ thử mua đầu-cuối ⇒ thử kín 12 người × 14 ngày.
