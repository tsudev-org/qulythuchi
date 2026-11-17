# PHIẾU RÀ SOÁT BẢO MẬT - P6 Đồng bộ trong app

- **PR / nhánh**: `feat/p6-dong-bo-app`
- **Người thực hiện**: agent-qulythuchi - **Người rà soát**: chủ dự án (ủy quyền cho agent, xem mục 7)
- **Ngày**: 18/11/2026

## 1. Thay đổi này đụng vào đâu

- [x] Xác thực hoặc quản lý phiên (đăng nhập trình duyệt hệ thống + PKCE, lưu/xoay vòng refresh token, đăng xuất)
- [x] Phân quyền hoặc kiểm tra quyền sở hữu đối tượng (thu hồi thiết bị, ràng buộc CSDL với một tài khoản tsudev)
- [ ] Tải tệp lên hoặc phục vụ tệp (tệp đính kèm chưa nối - P7)
- [x] Truy vấn cơ sở dữ liệu có dữ liệu do người dùng nhập (SQLite cục bộ, tham số hóa)
- [ ] Hiển thị nội dung HTML (chỉ trang "đã đăng nhập" tĩnh của cổng vòng lặp, không chèn dữ liệu)
- [x] Gọi ra dịch vụ ngoài (chỉ `https://qulythuchi.tsudev.com`, ghim CA)
- [x] Xử lý dữ liệu bí mật (D3): gói khóa, khóa ví, hợp nhất bản ghi đã giải mã trong bộ nhớ

## 2. Phân loại dữ liệu

| Dữ liệu chạm tới | Mức | Mã hóa khi truyền | Mã hóa khi lưu | Thời hạn lưu |
| --- | --- | --- | --- | --- |
| Bản ghi, khóa ví, gói khóa gửi/nhận | D3 | TLS (CA ghim) + E2EE | sqlite3mc trên máy; bản mã trên máy chủ | Như P2/P5 |
| Refresh token | D3 (xác thực) | TLS | Kho bí mật HĐH (Keystore/Keychain/libsecret/DPAPI) | Tới khi đăng xuất/xoay |
| Access token | D3 (xác thực) | TLS | Chỉ trong bộ nhớ | 15 phút |
| Hồ sơ tsudev (id, tên, email) | D2 | TLS | `meta` trong CSDL mã hóa (web: IndexedDB) | Tới khi đăng xuất |
| Con trỏ, rev lớn nhất, vân tay danh tính | D1 | - | `meta` | Tới khi đăng xuất |

## 3. Đối chiếu OWASP (MASVS cho app)

| Rủi ro | Có liên quan | Biện pháp đã áp dụng |
| --- | --- | --- |
| A01 Kiểm soát truy cập | Có | Máy chủ lọc theo phiên (P5); app không tin id từ máy chủ để chọn khóa: danh tính bản ghi nằm trong AAD |
| A02 Mật mã | Có | Không thuật toán mới; chỉ libsodium + SHA-256 cho PKCE; `Random.secure`; ghim CA |
| A04 Thiết kế | Có | Không trộn hai khóa chủ; gói khóa máy chủ chỉ nhận khi mở được bằng khóa chủ; rollback ⇒ dừng |
| A05 Cấu hình sai | Có | `badCertificateCallback` luôn false; Android chỉ thêm `INTERNET` + intent scheme riêng; macOS thêm network.client/server (vòng lặp) |
| A07 Xác thực | Có | Trình duyệt hệ thống, PKCE S256, `state` kiểm chặt, mã một lần đổi ngay; refresh lưu kho bí mật, lưu trước khi dùng access mới |
| A08 Toàn vẹn | Có | Bản ghi hỏng/tráo bị bỏ, không ghi đè; rev phải tăng chặt; vân tay danh tính ghim |
| A09 Ghi log | Có | Không `print`/`debugPrint` mới; lỗi hiển thị theo mã, không in thông điệp/nội dung |
| A10 SSRF | Không | Gốc máy chủ cố định trong mã |

## 4. Ca tấn công đã cân nhắc

1. **Ca**: máy chủ độc gửi gói khóa của kẻ tấn công để người dùng mã hóa dữ liệu mới bằng khóa của nó (T4). - **Chặn ở**:
   `Vault.remoteBundleMatches` + vân tay ghim. - **Test**: `sync_test.dart` "máy chủ tráo gói khóa sau khi đã ghim".
2. **Ca**: máy chủ tráo `mkPw` bằng rác để khóa người dùng ngoài. - **Chặn ở**: gói máy chủ chỉ cất làm `bundleRemote`,
   gói cục bộ vẫn mở được; nhận gói mới chỉ khi nó mở ra đúng danh tính. - **Test**: "đổi mật khẩu ở máy A".
3. **Ca**: thiết bị đã có dữ liệu cục bộ (khóa chủ khác) đăng nhập tài khoản đã có dữ liệu ⇒ trộn hoặc mất dữ liệu. -
   **Chặn ở**: `differentAccount`, không đẩy bản ghi nào. - **Test**: "máy có tài khoản cục bộ KHÁC khóa chủ".
4. **Ca**: máy chủ quay lui CSDL/trả bản cũ (T2). - **Chặn ở**: kiểm rev tăng chặt, rev cấp mới > rev đã thấy; HLC. -
   **Test**: "máy chủ quay lui rev".
5. **Ca**: bản ghi bị sửa byte/tráo ví trên máy chủ. - **Chặn ở**: AEAD + AAD, bỏ qua không ghi đè. - **Test**: "bản ghi
   bị tráo ví/hỏng".
6. **Ca**: MITM bằng CA hợp lệ khác (proxy công ty, CA bị ép cấp) (T6). - **Chặn ở**: SecurityContext chỉ tin CA ghim. -
   **Kiểm**: `tool/sync_smoke.dart health` với production đạt; test đối chiếu vân tay PEM.
7. **Ca**: app độc trên máy nghe cổng vòng lặp/chặn scheme để lấy mã. - **Chặn ở**: mã một lần 60 s ràng buộc PKCE
   verifier chỉ app này có; `state` sai ⇒ 404 và bỏ qua. - **Test**: `loopback_login_test.dart`.
8. **Ca**: refresh token bị sao chép. - **Chặn ở**: xoay vòng; máy chủ thu hồi khi dùng lại, app về đăng xuất. - **Test**:
   "token: access hết hạn ⇒ refresh xoay vòng; refresh bị dùng lại ⇒ thu hồi".
9. **Ca**: mất điện thoại (T7). - **Chặn ở**: thu hồi thiết bị từ máy khác (màn Tài khoản) ⇒ 401 ⇒ xóa token. - **Test**:
   "thiết bị bị thu hồi từ máy khác".
10. **Ca**: người dùng sửa dữ liệu trong lúc đang đồng bộ ⇒ ghi đè mất sửa đổi. - **Chặn ở**: áp trang kéo trong giao tác
    đồng bộ + nạp lại repository; xóa dirty chỉ khi bản niêm phong không đổi. - **Test**: "sửa đồng thời hai trường".
11. **Ca**: đăng nhập nhầm tài khoản tsudev khác ⇒ đẩy dữ liệu sang tài khoản người khác. - **Chặn ở**: ràng buộc id
    người dùng. - **Test**: "máy đã gắn tài khoản tsudev u1 không đăng nhập được u2".

## 5. Kiểm tra bắt buộc

- [x] Đầu vào từ máy chủ kiểm kiểu/thứ tự (rev, con trỏ, khung JSON); lỗi ⇒ mã chung.
- [x] Không secret trong mã/log/test (token trong test là chuỗi giả của máy chủ giả).
- [x] Phụ thuộc mới (SECURITY_BASELINE mục 5): `http` 1.6.0, `crypto` 3.0.8 (nhóm Dart, đã có gián tiếp qua lõi),
  `url_launcher` 6.3.3 (nhóm Flutter), `app_links` 7.2.2 (Apache-2.0, bảo trì đều, thay cho tự viết kênh nền tảng).
  Không thêm WebView. Ghi `NOTICE`.
- [x] 17 test đồng bộ (máy chủ giả mô phỏng hợp đồng P5), 2 test vòng lặp, 2 test giao diện; toàn bộ app test đạt.
- [x] Production: TLS ghim CA + `/api/v1/health` đạt bằng mã thật của app (`tool/sync_smoke.dart health`).

## 6. Rủi ro còn lại

- Ghim gốc tin cậy (không ghim lá/trung gian): CA trong danh sách bị ép cấp chứng chỉ sai vẫn qua. Chấp nhận - E2EE vẫn
  che nội dung; danh sách nhỏ hơn nhiều so với kho CA hệ điều hành.
- Mobile deep link chưa chạy trên máy thật (máy dev không có thiết bị) - nghiệm thu ở P10; desktop vòng lặp đã test.
- Web chưa nghiệm thu đầu-cuối (cookie `__Host-` chỉ chạy ở gốc production) - P8.
- Siêu dữ liệu nhịp đồng bộ lộ cho người vận hành (đã chấp nhận ADR-0002); chưa gộp lô ngẫu nhiên.
- Độ mạnh mật khẩu chưa đo bằng zxcvbn (T5) - P10.

## 7. Kết luận của người rà soát

- [ ] Đạt - được merge
- [x] Đạt có điều kiện - merge được; nghiệm thu đăng nhập thật trên Android ở P10, rà soát độc lập trước P10
- [ ] Không đạt - lý do:

Ký: agent-qulythuchi ký THAY theo ủy quyền của chủ dự án. Không phải rà soát độc lập.
