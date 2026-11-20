# PHIẾU RÀ SOÁT BẢO MẬT - STD43: nút đăng nhập dựng từ danh sách nhà cung cấp của IdP

- **PR / nhánh**: `chore/standards-v4.3.0`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (ủy quyền cho agent)
- **Ngày**: 21/11/2026
- **Căn cứ**: `.standards/docs/AUTH_AND_ACCOUNT.md` mục 3.2 + 15 (v4.3.0), phiếu `logs/handover/20261121-STD43_*`,
  ADR-0003 (đăng nhập qua máy chủ)

## 1. Thay đổi này đụng vào đâu

- [x] Xác thực (danh sách trắng `idp_hint` thêm `apple`; nút đăng nhập dựng theo IdP)
- [ ] Phân quyền - [ ] Tải tệp - [ ] Truy vấn CSDL - [ ] Hiển thị HTML
- [x] Gọi ra dịch vụ ngoài: `GET {gốc OIDC_ISSUER}/api/v1/auth/providers` (URL cố định theo cấu hình)
- [ ] Xử lý dữ liệu D3 - không đụng phong bì/khoá E2EE, không dữ liệu người dùng

## 2. Thiết kế

- Máy chủ `GET /api/v1/auth/providers` (công khai) hỏi IdP, chỉ giữ id trong danh sách trắng `google|apple|github`
  theo thứ tự quy ước, trả `{providers:[{id,name}], source}`; tên hiển thị lấy từ bảng của ta (không phản chiếu chuỗi
  của IdP). Đệm 5 phút; lỗi ⇒ giữ bản tốt cũ (hỏi lại sau 1 phút) hoặc dự phòng Google + GitHub - KHÔNG BAO GIỜ Apple.
- App gọi máy chủ của ta (đã ghim CA) chứ không gọi thẳng tsudev.com ⇒ không mở thêm tên miền ngoài ghim TLS/CSP.
- `provider` lạ vẫn bị chặn: app `/auth/app/start` 400, web bỏ qua; `apple` được nhận nhưng IdP chưa bật Apple thì bỏ
  qua gợi ý và hiện đủ lối (không có đường nào cấp phiên mà không qua IdP).

## 3. Ca tấn công đã cân nhắc

1. **IdP (hoặc kẻ chen giữa) trả lối lạ / tên chứa mã** - bị lọc theo danh sách trắng, tên không dùng.
   Test: `auth.test.ts` "lấy từ IdP, giữ thứ tự…, bỏ lối lạ".
2. **Dội đường công khai để làm máy chủ dội IdP** - đệm 5 phút theo isolate, lỗi chỉ hỏi lại sau 1 phút; trình duyệt/CDN
   đệm `max-age=300`.
3. **IdP lỗi ⇒ nút chết Apple** - dự phòng không chứa Apple (test máy chủ + app).
4. **SSRF** - URL dựng từ `OIDC_ISSUER` (biến cấu hình), không từ yêu cầu; hết giờ 10 giây như discovery.

## 4. Kết luận

Không đổi phiên, token, PKCE, `state`/`nonce`. Rủi ro còn lại: không đáng kể. Chưa bật Apple ở IdP nên bẫy `form_post`
mục 3.2 thuộc phía tsudev.com (RP vẫn nhận mã qua `GET /auth/callback` như cũ).
