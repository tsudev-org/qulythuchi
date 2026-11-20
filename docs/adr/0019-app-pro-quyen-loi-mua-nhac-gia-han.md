# ADR-0019: App T7 - quyền lợi TsuDEV Pro trong app, mua theo kênh, 402 theo lý do, nhắc gia hạn 7.6

- **Trạng thái**: ĐÃ CHẤP NHẬN (20/11/2026)
- **Ngày**: 20/11/2026
- **Người quyết định**: agent-qulythuchi (cách làm trong phạm vi ADR-0016/0018 + PRODUCT_POLICY v1.2.0)
- **Liên quan**: ADR-0016 (giữ nguyên trừ phần đã ghi ở ADR-0018), ADR-0018 (phần app); `.standards/docs/PRODUCT_POLICY.md`
  mục 3.3, 4, 7.2-7.6, 8; `tsudev-org/tsudev-ui-flutter` **v0.2.0** (commit `dc71dae`); phiếu
  `logs/handover/20261120-PRO2_*` mục 2.1-2.2; phiếu rà soát `docs/security-reviews/20261120-t7-app-pro.md`
- **Bổ sung** (không thay) ADR-0016 mục 2 điểm 2, 4, 7 bằng chi tiết hiện thực ở app; thêm một đường máy chủ (mục 4).

## 1. Bối cảnh

Máy chủ đã gate Pro (ADR-0016 mục 4) và xoá có xác minh (ADR-0018); `GET /api/v1/me/entitlements` chuyển JWS tsudev.com ký
xuống app. App chưa có: lớp quyền lợi, màn Pro/Ủng hộ, huy hiệu, xử lý `402 reason`, nhắc gia hạn 7.6. Gói chung
`tsudev_ui` v0.2.0 đã có `EntitlementsRepository`, `TsuBadge`, `ProNotice*`, `ProRenewal*`.

## 2. Quyết định

1. **Nguồn quyền lợi**: app KHÔNG gọi thẳng `tsudev.com/api/me/entitlements` (app không giữ access token tsudev). App lấy
   `jws` từ `GET /api/v1/me/entitlements` của máy chủ sản phẩm, đưa vào `EntitlementsRepository(fetchJws: ...)` của
   `tsudev_ui`, kiểm bằng `EntitlementVerifier(clientId: 'qulythuchi', DiscoveryJwks)` (`aud` = client RP; JWKS công khai
   có CORS `*` nên bản web cũng kiểm được), đệm ≤ 7 ngày trong `shared_preferences`. Các trường không ký (`enforce`,
   `status`, `can_sync`, `server_data_until`) chỉ để chọn lời nhắn/ẩn hiện nút, KHÔNG cấp quyền gì (N4). Không dùng
   `jwsForServer`/`sendWithServerJws`/DPoP: máy chủ không nhận JWS từ app (ADR-0018 mục 2.8).
2. **Mã cài đặt**: `InstallationId.getOrCreate` (128 bit, lưu cùng cài đặt) gửi kèm `X-Tsu-Installation` +
   `X-Tsu-Platform` ở MỌI lượt gọi máy chủ (`ApiClient.defaultHeaders`). Đăng xuất không xoá mã (đếm thiết bị theo cài đặt).
3. **Kênh phát hành** `--dart-define=TSU_CHANNEL=play|appstore|direct`. Không đặt ⇒ Android = `play`, iOS = `appstore`,
   web/desktop = `direct` (quên cờ thì bản cửa hàng vẫn không có liên kết web). APK ngoài Play `MUST` build với
   `TSU_CHANNEL=direct`. `play`/`appstore` không bao giờ mở `tsudev.com/pro` hay `tsudev.com/ung-ho` (test).
4. **Mua trong app (bản Play)**: `in_app_purchase` + `in_app_purchase_android`. Pro = thuê bao `tsudev_pro`, CHỈ gói cơ
   sở trả trước `nam` (bỏ qua gói/ưu đãi khác); Ủng hộ = tiêu hao `ung_ho_20k/50k/100k/200k`, không tự tiêu thụ.
   `applicationUserName` = `obfuscatedAccountId` = base64url(SHA-256(`tsudev-pro|` + `sub`)), `sub` lấy từ JWS ĐÃ KIỂM
   (không có JWS ⇒ không mở luồng mua, mời đăng nhập). Biên nhận ⇒ **đường mới** `POST /api/v1/me/purchases/play`
   (`{product_id, purchase_token}`, kiểm danh sách mã + hình dạng token, 20 lượt/giờ) ⇒ máy chủ chuyển tới
   `POST <ENTITLEMENTS_URL>/play` của tsudev.com bằng client assertion (`aud` = đúng URL đó), thân `{client_id, sub,
   packageName, productId, purchaseToken}`. tsudev.com 200 ⇒ máy chủ làm mới đệm quyền lợi ⇒ app mới
   `completePurchase`/`consumePurchase`. 400/409/422 ⇒ `purchase_invalid` (không hoàn tất ⇒ Play tự hoàn tiền);
   còn lại ⇒ `503 purchase_unavailable` (giữ, Play giao lại ở lần mở sau). Mã mua không vào log/D1.
   Bản App Store: chưa có IAP (2027) ⇒ không nút mua, không liên kết web. Bản `direct`: mở trang tsudev.com + nút
   "Tôi đã thanh toán - kiểm tra lại" (`?refresh=1`).
5. **402 theo `reason`** (`ProBlock`): `no_pro` ⇒ dòng "cần TsuDEV Pro" + "Xem gói Pro"; `reauth` ⇒ "Đăng nhập lại"
   (không mời mua); `owner_no_pro` ⇒ chỉ báo (thành viên không cần Pro). Lượt đồng bộ KHÔNG lỗi: bản ghi/ảnh giữ chờ trên
   máy, vẫn kéo + ví chung khác vẫn chạy, không thử đẩy lại trong lượt. `can_sync = false` ⇒ app không gọi đẩy/tải lên.
6. **Màn Pro** (`/more/pro`): một lựa chọn "1 năm"; giá Play theo cửa hàng, web 490.000 ₫ (số nguyên đồng); điều khoản
   7.5 nguyên văn (chuỗi `proTerms` vi/en, test so với `.standards`) đứng TRƯỚC nút mua; Ủng hộ theo kênh (mục 3).
7. **Nhắc** ở màn chính (`ProPromptHost`), sau mỗi lần làm mới quyền lợi (mở khoá, quay lại app, đăng nhập), tối đa một
   hộp thoại mỗi lượt, không chen khi đang nhập liệu: (a) `maybeShowProRenewal` của `tsudev_ui` - MỘT
   `ProRenewalController` cho cả tiến trình nối `AppLifecycleListener`, `hasCloudSync: true`; "Gia hạn" theo kênh
   (Play ⇒ IAP `nam`, App Store ⇒ màn Pro, ngoài cửa hàng ⇒ `proWebUrl('qulythuchi')`); (b) báo trước xoá bản sao đám
   mây ở mốc 30 và 7 ngày trước `server_data_until` (PRODUCT_POLICY 7.2, khoá `qlt.pro_purge.notified`); (c)
   `maybeShowProNotice` (7.3).
8. **Huy hiệu**: `TsuNameWithBadge` ở Tài khoản (badge của JWS) và danh sách thành viên ví chung. Máy chủ trả `badge`
   của từng thành viên từ đệm quyền lợi CÒN HẠN (giá trị sau `badge_display`), Pro đã qua `pro_until` ⇒ tắt phần Pro;
   không có đệm ⇒ `none`.

## 3. Hệ quả

- (+) Không tự viết lại thành phần dùng chung; chữ 7.3/7.6 nguyên văn đến từ `tsudev_ui` (đã test so `.standards`).
- (+) Bản Play/App Store an toàn mặc định; mua chỉ hoàn tất khi tsudev.com xác minh.
- (-) Kênh `/api/rp/entitlements/play` của tsudev.com CHƯA có (20/11/2026 trả 405, bước B2 tsudev) ⇒ mua Play trả
  `purchase_unavailable` tới khi tsudev xong B2; hình dạng thân yêu cầu chờ tsudev xác nhận (phiếu cho tsudev).
- (-) Nạp thêm gói trả trước khi còn hạn (gia hạn sớm trên Play) cần thử trên máy thật khi có sản phẩm Play (P10).
- Lõi `packages/core` không đổi.

## 4. Kiểm chứng

`apps/app/test/t7_pro_test.dart` (7.5 nguyên văn vi/en; 6 ca 7.6; Play "Gia hạn" ⇒ IAP không ra web; 7.3; mốc 30/7;
kênh mặc định; `obfuscatedAccountId`; 402 `no_pro`/`reauth`/`owner_no_pro`; `can_sync=false` không đẩy; mã cài đặt) +
`services/sync-api/test/pro.test.ts` khối "biên nhận Google Play" và "Huy hiệu thành viên ví chung".
