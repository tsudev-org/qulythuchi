# ADR-0018: TsuDEV Pro kỳ 1 năm không tự gia hạn - xoá bản mã vì hết Pro CÓ XÁC MINH qua kênh trạng thái

- **Trạng thái**: ĐÃ CHẤP NHẬN (20/11/2026) - phần máy chủ. Phần app (nhắc gia hạn 7 ngày, báo hết kỳ, màn mua chỉ gói
  1 năm) làm cùng app T7 khi có `tsudev_ui` v0.2.0.
- **Ngày**: 20/11/2026
- **Người quyết định**: chủ dự án (Pro 1 năm, không tự gia hạn, 20/11/2026); agent-qulythuchi (cách làm)
- **Liên quan**: `.standards/docs/PRODUCT_POLICY.md` v1.2.0 (bộ quy ước v4.0.0) mục 3.3, 7.2, 7.4, 7.6; phiếu
  `logs/handover/20261120-PRO2_pro-ky-1-nam-nhac-gia-han-xoa-co-xac-minh.md`; mã tham chiếu `tsudev-org/tsusync` v0.2.0
  `worker/src/rp.ts`, `worker/src/maintenance.ts` (`verifyExpired`)
- **Thay thế một phần**: ADR-0016 - mục 2 điểm 4 (gói `thang`/`nam` tự gia hạn ⇒ chỉ còn gói trả trước `nam`) và mục 4
  gạch "Dọn" (cách hỏi lại tsudev.com trước khi xoá). Phần còn lại của ADR-0016 giữ nguyên.

## 1. Bối cảnh

Bộ quy ước v4.0.0 đổi TsuDEV Pro thành **một kỳ 1 năm, không tự gia hạn ở mọi kênh**. Hết kỳ ⇒ trạng thái miễn phí:
máy chủ chặn đẩy mới (`402`), vẫn cho kéo + xuất 90 ngày, rồi xoá bản mã trên máy chủ.

Lỗi cần chặn: ADR-0016 mục 4 xoá khi `pro_until` đã đệm quá 90 ngày, hỏi lại bằng kênh RP `GET /api/rp/entitlements/{sub}`.
Kênh này trả `404 unknown_subject` khi grant OIDC của người dùng với client `qulythuchi` quá 30 ngày. Người **gia hạn
trên web mà không mở app suốt 90 ngày** thì máy chủ chỉ biết `pro_until` cũ, kênh RP không trả lời được, và luật cũ
"`unknown_subject` + không đăng nhập quá 90 ngày ⇒ xoá" xoá nhầm dữ liệu D3 của người đang trả tiền.

PRODUCT_POLICY 7.4 thêm **kênh trạng thái** `POST https://tsudev.com/api/rp/entitlements/status`, trả trạng thái cho mọi
`sub` đã từng cấp quyền cho client, KHÔNG phụ thuộc grant 30 ngày, và đặt `MUST`: hỏi kênh này ngay trước mọi lần xoá.

## 2. Quyết định

1. **Đường xoá vì hết Pro duy nhất** của máy chủ là `purgeLapsedPro` (`src/maintenance.ts`, chạy kèm ~1% yêu cầu `/api`
   khi `PRO_ENFORCE=on`). Xoá theo yêu cầu người dùng (`purgeDeletedAccounts`, ân hạn 30 ngày) không phải xoá vì hết Pro
   nên không đi qua kênh trạng thái. Mọi đường xoá vì hết Pro thêm sau này `MUST` đi qua cùng hàm xác minh.
2. **`pro_until` đệm chỉ dùng để CHỌN ứng viên** (đệm thiếu hoặc `pro_until` + 90 ngày đã qua, còn dữ liệu trên máy
   chủ, chưa hỏi trong 24 giờ; tối đa 3 tài khoản mỗi lượt). Ngay sau đó, trong cùng lượt, gửi MỘT yêu cầu tới kênh
   trạng thái cho đúng các ứng viên đó (≤ 100 `sub`), rồi mới xoá:

   | Kênh trạng thái trả | Xử lý |
   | --- | --- |
   | `ok`, `pro_until` + 90 ngày còn ở tương lai | **Đã gia hạn**: cập nhật `entitlements.pro_until` (`MAX`), GIỮ dữ liệu |
   | `ok`, `pro_until` + 90 ngày đã qua (kể cả `0`) | Xoá; nhật ký `pro_data_purged` `detail = verified:ok` |
   | `deleted` | Xoá; `detail = verified:deleted` |
   | `unknown_subject`, thiếu mục, lỗi mạng, hết giờ 10 giây, HTTP ≠ 200, khung sai | **Hoãn**: ghi mốc, hỏi lại sau ≥ 24 giờ |
   | Chưa cấu hình (`ENTITLEMENTS_STATUS_URL` hoặc `RP_PRIVATE_JWK` thiếu) | Hoãn, không gọi đi |

3. **`404 unknown_subject` của kênh RP `GET /{sub}` không bao giờ là lý do xoá**; nó chỉ dẫn tới `402 reason=reauth`
   (mời đăng nhập lại) như ADR-0016. Bỏ luật cũ "`unknown_subject` + không đăng nhập quá 90 ngày ⇒ xoá".
4. **Client assertion** dùng lại khoá `RP_PRIVATE_JWK` và hàm `clientAssertion` của kênh RP, chỉ đổi `aud` = đúng URL
   kênh trạng thái: ES256, `iss` = `sub` = `qulythuchi`, `exp` 120 giây, `jti` ngẫu nhiên một lần. Thân
   `{"client_id": "qulythuchi", "subs": [...]}`.
5. **Mốc hỏi lại**: bảng mới `pro_purge_checks(user_id, checked_at)` (migration `0006`, chỉ thêm mới - `0004` bất biến).
   Tách khỏi `entitlements` vì tài khoản chưa từng có đệm quyền lợi (đẩy lúc gate tắt) cũng là ứng viên. Xoá xong thì
   xoá dòng mốc; tài khoản bị xoá thì FK `ON DELETE CASCADE`.
6. **Cập nhật hạn khi đã gia hạn** chỉ đổi `pro_until`, không đụng `jws`/`fetched_at`: gate 402 vẫn lấy JWS mới theo
   nhịp đệm 24 giờ của ADR-0016. Tài khoản chưa có đệm ⇒ tạo dòng `status = unknown_subject`, `fetched_at = 0` - dòng này
   không bao giờ "còn hạn" nên không cấp Pro, chỉ để không chọn lại tài khoản làm ứng viên.
7. **Cấu hình**: biến `ENTITLEMENTS_STATUS_URL` (`https://tsudev.com/api/rp/entitlements/status` trong `wrangler.jsonc`).
   `PRO_ENFORCE` giữ nguyên ý nghĩa (production `off` ⇒ không dọn gì).
8. **JWS tươi (`iat` ≤ 24 giờ, `401 reason=stale`)**: không áp dụng - máy chủ này KHÔNG nhận JWS quyền lợi từ app; nó tự
   lấy JWS qua kênh RP và chỉ chuyển xuống app trong `GET /api/v1/me/entitlements`. Thêm đường nhận JWS từ app ⇒ `MUST`
   áp luật này.
9. **Hạn mức** 200 MiB bản ghi + 1 GiB tệp (ADR-0016) giữ nguyên. Máy chủ không có mã gói (`thang`/`nam`) nào - đổi gói
   chỉ ở app (Play Billing) và tsudev.com.

## 3. Hệ quả

- (+) Người gia hạn trên web mà không mở app không bị xoá bản mã; hạn đã đệm tự đúng lại sau lần hỏi.
- (+) tsudev.com sập hoặc kênh chưa lên ⇒ không xoá ai (an toàn mặc định); mỗi tài khoản bị hỏi tối đa 1 lần/24 giờ.
- (-) Ngày 20/11/2026 kênh trạng thái CHƯA có trên tsudev.com (`POST` trả `405`) ⇒ khi bật `PRO_ENFORCE=on` mà kênh
  vẫn chưa lên, máy chủ không bao giờ xoá bản mã của người hết Pro (dữ liệu D3 nằm lâu hơn 90 ngày). Chấp nhận: đúng
  `MUST` "kênh chưa lên production ⇒ hoãn, không xoá theo đệm"; kênh do phiên tsudev làm theo phiếu mẹ PRO2.
- (-) Bản mã của tài khoản tsudev đã xoá (`deleted`) chỉ được dọn ở đây (dữ liệu Pro); dòng `users` vẫn còn tới khi có
  cơ chế đồng bộ xoá tài khoản giữa tsudev.com và máy chủ (ngoài phạm vi ADR này).

## 4. Kiểm chứng

`services/sync-api/test/pro.test.ts` khối "xoá có xác minh qua kênh trạng thái" (kênh trạng thái giả trong
`test/helpers.ts`, ghi lại client assertion + thân yêu cầu): hết hạn thật ⇒ xoá; `deleted` ⇒ xoá; gia hạn trên web mà
kênh RP 404 ⇒ không xoá + cập nhật hạn + không gọi kênh RP; còn trong 90 ngày ⇒ giữ; `500`/hết giờ/khung sai/`404`/
`unknown_subject`/thiếu mục ⇒ hoãn và không hỏi lại trong 24 giờ, sau 24 giờ hỏi lại; assertion đúng `iss`/`sub`/`aud`/
`exp`/`jti` một lần; chưa cấu hình ⇒ không gọi, không xoá.
