# ADR-0011: Đồng bộ trong app P6 - đăng nhập, nhận tài khoản, hợp nhất, ghim CA

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0002/0003/0004/0010, không thay thế)
- **Ngày**: 18/11/2026
- **Người quyết định**: agent-qulythuchi
- **Liên quan**: `apps/app/lib/sync/**`, `apps/app/lib/state/sync_controller.dart`, `apps/app/lib/ui/account/**`,
  `docs/security-reviews/20261118-p6-dong-bo-app.md`

## 1. Bối cảnh
P5 đã đưa máy chủ `https://qulythuchi.tsudev.com` lên production. P6 nối app vào: đăng nhập, đưa tài khoản mã hóa lên
máy chủ hoặc nhận về thiết bị mới, đồng bộ nền, quản lý thiết bị, ghim chứng chỉ.

## 2. Quyết định
1. **Đăng nhập** bằng trình duyệt hệ thống (`url_launcher`, không WebView). Android/iOS nhận mã qua
   `com.tsudev.qulythuchi:/auth/callback` (`app_links`, intent filter / `CFBundleURLTypes`); Windows/macOS/Linux qua
   `http://127.0.0.1:<cổng do HĐH cấp>/callback` (`HttpServer` chỉ nghe 127.0.0.1, đóng sau lượt hợp lệ đầu hoặc 5 phút).
   `state` 24 B + PKCE S256 verifier 48 B từ `Random.secure`. Web: `/auth/web/start?return_to=/app/` + cookie.
2. **Token**: refresh lưu trong kho bí mật của thiết bị (`qt.sync.refresh`), access chỉ trong bộ nhớ. Refresh mới được
   LƯU trước khi dùng access mới; một lượt làm mới tại một thời điểm; `invalid_grant`/`device_revoked` ⇒ xóa token,
   về trạng thái đăng xuất, dữ liệu trên máy giữ nguyên.
3. **Thiết lập E2EE trên tài khoản** (`SyncEngine.syncKeys`):
   - Máy chủ chưa có gói khóa ⇒ `PUT /keys/account {if_absent: true}`; 409 ⇒ đọc lại và so như dưới.
   - Có gói khóa ⇒ "cùng tài khoản" khi khóa công khai (X-Wing, X25519) trùng gói cục bộ **và** phần bí mật của gói máy
     chủ mở được bằng khóa chủ đang mở (AEAD). Khác ⇒ chặn (`differentAccount`), KHÔNG trộn dữ liệu (như ADR-0009).
   - Vân tay danh tính (BLAKE2b của hai khóa công khai) ghim sau lần đầu; đổi ⇒ `identityChanged` (THREAT_MODEL T4).
   - Đổi mật khẩu/24 từ cục bộ ⇒ cờ `bundleDirty` ⇒ đẩy đè. Gói máy chủ cùng danh tính nhưng khác bản bọc (đổi mật
     khẩu ở máy khác) ⇒ cất `bundleRemote`, chỉ nhận khi mở khóa: mật khẩu mới mở được nó VÀ nó mở ra đúng danh tính.
   - Khóa dữ liệu cấp tài khoản lưu ở bảng khóa ví máy chủ với id dành riêng `00000000-0000-4000-8000-000000000000`
     (phong bì vẫn ngữ cảnh `wk|account`, không thể nhầm với ví thật).
   - Thiết bị mới: đăng nhập ⇒ `GET /keys` ⇒ mật khẩu hoặc 24 từ mở gói ⇒ kiểm danh tính + khóa tài khoản ⇒ mới ghi
     vào CSDL (sai ⇒ không để lại tài khoản dở) ⇒ đồng bộ.
4. **Kéo trước, đẩy sau** (ADR-0010 mục 3): mỗi trang kéo áp trong MỘT giao tác SQLite không có `await` xen giữa, lưu
   con trỏ cùng giao tác, rồi nạp lại repository - sửa đổi của người dùng không chen vào được. Bản ghi kéo về: mở
   được ⇒ hợp nhất theo trường với bản cục bộ; kết quả khác bản máy chủ ⇒ lưu bản hợp nhất, đánh dirty để đẩy lại;
   không mở được (hỏng/tráo) ⇒ bỏ, không ghi đè; chưa có khóa ví ⇒ giữ bản mã. Đẩy lô ≤ 200, `applied`/`unchanged`
   chỉ xóa dirty khi bản niêm phong chưa đổi trong lúc gửi; `rejected` giữ dirty, báo đếm. Cờ `deleted` lấy từ bia mộ.
5. **Phát hiện quay lui** (T2, phần làm được ở máy khách): rev kéo về phải tăng chặt và > `since`, con trỏ không lùi;
   rev máy chủ cấp cho lượt đẩy phải > rev lớn nhất đã thấy, sai ⇒ `rollback`, dừng đồng bộ. Không có con trỏ ký vì
   kẻ ký chính là máy chủ; hợp nhất HLC vẫn chặn ghi đè bằng bản cũ.
6. **Ràng buộc tài khoản tsudev**: CSDL nhớ id người dùng máy chủ; đăng nhập tài khoản khác ⇒ `otherUser`. Đăng xuất
   có chủ ý xóa ràng buộc + con trỏ (lần sau đẩy lại toàn bộ, lũy đẳng).
7. **Lịch đồng bộ**: khi mở khóa, 4 giây sau thay đổi cục bộ, mỗi 10 phút khi đang mở, khi quay lại tiền cảnh (> 1
   phút từ lần trước). Gọi chồng ⇒ xếp đúng một lượt sau. Khóa app ⇒ dừng (không có khóa để hợp nhất).
8. **Ghim chứng chỉ** (ADR-0003, T6): `SecurityContext(withTrustedRoots: false)` chỉ tin tập CA gốc dưới đây (ghim gốc
   tin cậy thay cho băm SPKI từng chứng chỉ: Dart không cho đọc chuỗi khi bắt tay thành công; hiệu quả tương đương ghim
   SPKI của CA gốc). `badCertificateCallback` luôn `false`. Lệch ⇒ `tls_pin`, chặn đồng bộ, app ngoại tuyến vẫn chạy.
   Đo ngày 18/11/2026: chuỗi hiện tại `tsudev.com ← WE1 ← GTS Root R4`. Sinh lại: `apps/app/tool/gen_pinned_roots.sh`; test
   đối chiếu vân tay DER từng khối PEM. Web dựa vào trình duyệt.

| CA gốc (dự phòng: GlobalSign R46/E46, SSL.com) | SHA-256 SPKI (base64) |
| --- | --- |
| `ISRG_Root_X1` | `C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=` |
| `ISRG_Root_X2` | `diGVwiVYbubAI3RW4hB9xU8e/CH2GnkuvVFZE8zmgzI=` |
| `GTS_Root_R1` | `hxqRlPTu1bMS/0DITB1SSu0vd4u/8l8TjPgfaAp63Gc=` |
| `GTS_Root_R3` | `QXnt2YHvdHR3tJYmQIr0Paosp6t/nggsEGD4QJZ3Q0g=` |
| `GTS_Root_R4` | `mEflZT5enoR1FuXLgYYGqnVEoZvmf9c2bVBpiOjYQ0c=` |
| `SSL.com_TLS_RSA_Root_CA_2022` | `K89VOmb1cJAN3TK6bf4ezAbJGC1mLcG2Dh97dnwr3VQ=` |
| `SSL.com_TLS_ECC_Root_CA_2022` | `G/ANXI8TwJTdF+AFBM8IiIUPEv0Gf6H5LA/b9guG4yE=` |
| `SSL.com_Root_Certification_Authority_RSA` | `0cRTd+vc1hjNFlHcLgLCHXUeWqn80bNDH/bs9qMTSPo=` |
| `SSL.com_Root_Certification_Authority_ECC` | `oyD01TTXvpfBro3QSZc1vIlcMjrdLTiL/M9mLCPX+Zo=` |
| `GlobalSign_Root_R46` | `rn+WLLnmp9v3uDP7GPqbcaiRdd+UnCMrap73yz3yu/w=` |
| `GlobalSign_Root_E46` | `4EoCLOMvTM8sf2BGKHuCijKpCfXnUUR/g/0scfb9gXM=` |

## 3. Hệ quả
- Cloudflare chuyển sang CA ngoài danh sách ⇒ bản app cũ ngừng đồng bộ tới khi cập nhật. Có 4 họ CA + dự phòng để giảm
  rủi ro; theo dõi thông báo CA của Cloudflare trước P10.
- Bản ghi bị máy chủ từ chối (hạn mức, cỡ) nằm dirty vĩnh viễn và được báo trên màn Tài khoản.
- Web lưu hồ sơ (email, tên - D2) trong IndexedDB không mã hóa cả tệp (như ADR-0001 mục 4); xóa khi đăng xuất.
- Chưa đo độ mạnh mật khẩu (zxcvbn, T5) - dời P10.
