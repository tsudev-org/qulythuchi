# PHIẾU RÀ SOÁT BẢO MẬT - T7 máy chủ: gate TsuDEV Pro (quyền lợi do tsudev.com ký)

- **PR / nhánh**: `feat/t7-may-chu-pro`
- **Người thực hiện**: agent-qulythuchi (phiên qulythuchi-28) - **Người rà soát**: chủ dự án (ủy quyền cho agent, xem mục 6)
- **Ngày**: 20/11/2026
- **Quyết định thiết kế**: `docs/adr/0016-pro-ung-ho-dong-bo-la-pro.md`; hợp đồng chung `.standards/docs/PRODUCT_POLICY.md`
  mục 7.4 (v3.9.1); tsudev `docs/adr/0002-may-chu-quyen-loi.md` "Bổ sung PRO1"

## 1. Thay đổi này đụng vào đâu

- [x] Xác thực hoặc quản lý phiên (client assertion `private_key_jwt` máy chủ ↔ tsudev.com; đăng nhập lại xoá đệm)
- [x] Phân quyền hoặc kiểm tra quyền sở hữu đối tượng (gate 402 theo quyền lợi; ví chung theo Pro của chủ ví)
- [x] Tải tệp lên hoặc phục vụ tệp (`PUT /files` cần Pro)
- [x] Truy vấn cơ sở dữ liệu có dữ liệu do người dùng nhập (D1 migration 0004 - tham số hoá)
- [ ] Hiển thị nội dung HTML
- [x] Gọi ra dịch vụ ngoài (`GET https://tsudev.com/api/rp/entitlements/{sub}` - URL cố định theo cấu hình)
- [ ] Xử lý dữ liệu bí mật (D3) - quyền lợi không phải dữ liệu tài chính; không đụng phong bì/khoá E2EE

## 2. Phân loại dữ liệu

| Dữ liệu chạm tới | Mức | Mã hóa khi truyền | Mã hóa khi lưu | Thời hạn lưu |
| --- | --- | --- | --- | --- |
| JWS quyền lợi (`pro_until`, `badge`, `devices_30d`) | D1 | TLS | D1 (bản gốc đã ký) | Đệm ≤ 24 giờ, ghi đè mỗi lần hỏi lại |
| Mã cài đặt `X-Tsu-Installation` | D1 | TLS | Chỉ SHA-256 trong `installations_seen` | Tới khi xoá tài khoản |
| Khoá riêng RP (`RP_PRIVATE_JWK`) | Bí mật hệ thống | - | Secret Cloudflare; bản ở máy chủ dự án `~/.config/tsudev/` (600) | Tới khi xoay khoá |
| `oidc_sub` gửi sang tsudev.com | D1 | TLS | Đã có từ P5 | - |

## 3. Đối chiếu OWASP (ASVS máy chủ)

| Rủi ro | Có liên quan | Biện pháp đã áp dụng |
| --- | --- | --- |
| A01 Kiểm soát truy cập | Có | Gate ở MÁY CHỦ cho mọi đường ghi tốn dung lượng (đẩy, tệp, tạo/mời ví chung, email); app không cấp quyền được; ví chung kiểm Pro của chủ ví lấy từ D1, không từ yêu cầu |
| A02 Mật mã | Có | jose: chỉ ES256, kiểm `iss`/`aud`/`exp`/`iat`/`sub`/`typ = tsu-ent+jwt`, `exp - iat` ≤ 7 ngày; JWKS từ discovery, `kid` lạ tải lại ≤ 1 lần/phút; assertion ES256, `exp` 120 giây, `jti` ngẫu nhiên 192 bit |
| A04 Thiết kế | Có | Lỗi tsudev.com ⇒ 503 (không 402, không cấp quyền); đệm cũ quá 24 giờ không dùng; cờ `PRO_ENFORCE` bật có chủ đích |
| A05 Cấu hình sai | Có | CORS chỉ thêm 2 header `X-Tsu-*`; khoá riêng chỉ ở secret; `wrangler.jsonc` không chứa bí mật |
| A07 Xác thực | Có | Grant OIDC hết hạn ⇒ `404 unknown_subject` ⇒ 402 `reason=reauth`; đăng nhập lại đặt `fetched_at = 0` |
| A08 Toàn vẹn | Có | Chỉ tin JWS đã kiểm chữ ký; thân trả về giới hạn 4096 ký tự; claim sai kiểu ⇒ từ chối |
| A09 Ghi log | Có | Lỗi chỉ ghi tên lớp; nhật ký kiểm toán `pro_data_purged` chỉ id tài khoản |
| A10 SSRF | Có | URL đích cố định (`ENTITLEMENTS_URL`), `sub` qua `encodeURIComponent`, hết giờ 10 giây |

## 4. Ca tấn công đã cân nhắc

1. **Ca**: app sửa đổi tự báo "có Pro" để đồng bộ miễn phí. - **Chặn ở**: máy chủ không đọc cờ nào từ app; quyền lợi
   chỉ từ JWS tsudev.com. - **Test**: `pro.test.ts` "chưa có Pro: … ⇒ 402".
2. **Ca**: giả mạo JWS (khoá lạ, JWS cấp cho app khác, JWT thường, JWS của người khác). - **Chặn ở**: kiểm chữ ký +
   `aud` + `typ` + `sub`; sai ⇒ 503 và KHÔNG đệm. - **Test**: `pro.test.ts` "JWS sai khoá / sai aud / sai typ / sai sub".
3. **Ca**: làm tsudev.com chậm/sập để ép máy chủ mở cổng. - **Chặn ở**: hỏng kênh ⇒ chỉ dùng đệm còn ≤ 24 giờ, không
   thì 503. - **Test**: `pro.test.ts` "tsudev.com sập".
4. **Ca**: thành viên ví chung miễn phí dùng ví chung làm kho đồng bộ riêng khi chủ ví đã hết Pro. - **Chặn ở**: đẩy vào
   ví kiểm Pro của `owner_id` ⇒ 402 `owner_no_pro`. - **Test**: `pro.test.ts` "ví chung chạy bằng Pro của chủ ví".
5. **Ca**: lạm dụng đường không gate (`PUT /keys/*`) làm kho dữ liệu. - **Chặn ở**: giữ mở có chủ đích (cần để tham gia
   ví chung miễn phí) nhưng giới hạn 32 KiB / 512 KiB và kiểm khung khoá bọc như P5. Rủi ro còn lại nhỏ.
6. **Ca**: dồn mã cài đặt giả để làm máy chủ gọi tsudev.com liên tục. - **Chặn ở**: mã sai định dạng bỏ qua; mỗi mã
   báo ≤ 1 lần/24 giờ; đường ghi đã có giới hạn tần suất theo tài khoản; `?refresh=1` ≤ 10 lần/giờ. - **Test**:
   `pro.test.ts` "có Pro: … đệm 24 giờ".
7. **Ca**: liệt kê thiết bị / theo dõi người dùng qua mã cài đặt. - **Chặn ở**: chỉ lưu SHA-256, không trả ra API;
   `devices_30d` là số đếm. Mã cài đặt là ngẫu nhiên 128 bit do app sinh (không IMEI/MAC).
8. **Ca**: lộ khoá riêng RP. - **Hậu quả**: kẻ có khoá đọc được quyền lợi (không phải dữ liệu tài chính) của người đã
   cấp quyền cho client `qulythuchi`. - **Giảm thiểu**: khoá chỉ ở secret Cloudflare + tệp 600 ngoài repo; xoay bằng
   `scripts/rp-key.mjs` + OWNER cập nhật `rpPublicJwk`.
9. **Ca**: xoá nhầm dữ liệu người vừa gia hạn. - **Chặn ở**: trước khi xoá luôn hỏi lại tsudev.com nếu đệm > 1 ngày;
   hỏi lỗi ⇒ bỏ qua; `unknown_subject` chỉ xoá khi người dùng không đăng nhập quá 90 ngày. - **Test**: `pro.test.ts`
   "dọn bản mã".

## 5. Kiểm thử

- `services/sync-api`: 68 test (9 mới trong `test/pro.test.ts`), typecheck + ESLint sạch.
- Chưa kiểm với tsudev.com thật: khoá RP chưa đăng ký (việc 👤). Production giữ `PRO_ENFORCE=off` tới khi có.

## 6. Kết luận

Đạt để gộp với `PRO_ENFORCE=off`. Điều kiện bật `on`: (1) OWNER đăng ký khoá công khai RP ở tsudev; (2) đặt secret
`RP_PRIVATE_JWK`; (3) chủ dự án đồng ý xoá dữ liệu thử nghiệm; (4) thử `GET /api/v1/me/entitlements` trả `status: ok`
với một tài khoản thật. Phần app (lớp `Entitlements`, màn Pro/Ủng hộ, thông báo 30 ngày, xử lý `reason=reauth`) có
phiếu rà soát riêng khi làm.
