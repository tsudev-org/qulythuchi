# ADR-0015: P9 Ví chung gia đình - không gian bản ghi theo ví, mã mời có bí mật cặp, xoay khóa khi thu hồi

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0002/0004/0007/0010/0011, không thay thế)
- **Ngày**: 19/11/2026
- **Người quyết định**: agent-qulythuchi (theo `docs/PLAN.md` hàng P9; chủ dự án chốt "ví chung ở phase sau" 17/11/2026)
- **Liên quan**: `packages/core/lib/src/sharing/wallet_sharing.dart`, `conformance/envelope-v1.json` (mục `sharing`),
  `services/sync-api/{migrations/0003_shared_wallets.sql,src/wallets/routes.ts}`,
  `apps/app/lib/{sync/sync_engine.dart,sync/shared_wallets.dart,ui/wallets/shared_wallet_page.dart,ui/wallets/join_wallet_page.dart}`,
  `docs/security-reviews/20261119-p9-vi-chung.md`

## 1. Bối cảnh
Gia đình cần cùng ghi một ví (quỹ chung, chi tiêu nhà) với quyền khác nhau. Mọi thứ phải giữ E2EE: máy chủ không đọc
được dữ liệu, không tự thêm được người vào ví, không giữ được khóa. ADR-0010 mục 1 chốt "không gian bản ghi = tài khoản"
nên bản ghi của người A không thể nằm trong không gian của người B - cần không gian mới. Lõi đã có trao khóa X-Wing
(ADR-0007 mục 1) nhưng khối đó KHÔNG xác thực người gửi: máy chủ biết khóa công khai của người nhận nên tự tạo được
khối chứa khóa ví của nó, và có thể thay khóa công khai của người nhận bằng khóa của nó khi chủ ví hỏi.

## 2. Quyết định

1. **Không gian bản ghi theo ví** cho ví đã chia sẻ: bảng `wallet_records(wallet_id, id)`, `rev` là bộ đếm của ví
   (`shared_wallets.rev`), tăng trong cùng D1 batch như ADR-0010 mục 2. "Chia sẻ ví" CHUYỂN bản ghi của ví từ
   `records` của chủ ví sang không gian ví trong một giao tác (đánh rev ví theo thứ tự rev cũ) - không mã hóa lại, khóa
   ví hiện tại thành **phiên bản 1**. Đẩy bản ghi của ví chung vào không gian tài khoản bị từ chối (`shared_wallet`).
   Ví riêng giữ nguyên như cũ. Thiết bị biết ví thành ví chung ⇒ đặt rev cục bộ của ví về 0 (rev hai không gian không
   so được) để lượt kéo đầu hợp nhất lại.
2. **Mã mời = id (UUID v4, máy chủ biết) + bí mật 32 byte (máy chủ KHÔNG biết)**, gửi qua kênh ngoài (tin nhắn riêng,
   QR gặp mặt; liên kết `…/app/#/moi/<id>.<bí mật>` - bí mật sau `#` không tới máy chủ). Bí mật là **bí mật cặp** giữa
   chủ ví và thành viên:
   - **Bằng chứng nhận lời mời** = BLAKE2b-256(khóa = bí mật, `QTINV1|ví|lời mời|` ‖ khóa công khai X-Wing người nhận).
     Máy chủ lấy khóa công khai từ gói khóa đã đăng ký của người nhận (không nhận từ thân yêu cầu) và chuyển nguyên
     bằng chứng; **chủ ví kiểm trên thiết bị** (`sodium_memcmp`) trước khi chia khóa. Sai ⇒ hủy lời mời, báo chủ ví.
     Máy chủ thay khóa công khai của mình vào thì bằng chứng sai.
   - **Khối chia sẻ khóa** `'Q' 'S' 01 ‖ bản mã X-Wing ‖ phong bì v1` với KEK = BLAKE2b-256(khóa = bí mật cặp,
     `QTSHARE2` ‖ bí mật chung X-Wing ‖ bản mã X-Wing) - cùng ý với chế độ PSK của HPKE. Mở cần CẢ khóa riêng danh tính
     của người nhận LẪN bí mật cặp: máy chủ không có bí mật cặp nên không giả được khóa ví gửi cho thành viên; kẻ chỉ
     lộ mã mời (đọc trộm tin nhắn) không có khóa riêng danh tính. Phong bì ngữ cảnh `swk|ví|phiên bản` (phiên bản khóa
     nằm trong AAD). Chỉ ghép hàm libsodium, không nguyên thủy mới; vector đối chiếu phần đối xứng kiểm bằng libsodium
     hệ thống (`conformance/verify_libsodium.py`); X-Wing kiểm bằng test vòng của lõi (libsodium 1.0.18 chưa có X-Wing).
   - Bí mật cặp lưu thành bản ghi E2EE cấp tài khoản loại `wallet_share` ⇒ mọi thiết bị của chủ ví hoàn tất được lời
     mời/xoay khóa; mọi thiết bị của thành viên mở được khóa. Lời mời được LƯU bí mật trước khi báo máy chủ.
   - Mã an toàn 12 chữ số (BLAKE2b của hai khóa công khai) hiện cạnh từng thành viên để so qua kênh ngoài - phòng kẻ
     lấy được mã mời nhận lời mời trước người thật (chủ ví thấy tên/email tài khoản đã nhận và thu hồi được).
3. **Quyền**: `owner` (một người, không đổi trong P9), `editor`, `viewer`. Máy chủ chặn: người xem không đẩy được
   (`read_only`); người ghi không ghi bản ghi loại `wallet` (thông tin ví) (`forbidden`); chỉ chủ ví mời/đổi quyền/xoay
   khóa; người ngoài nhận 404 như ví không tồn tại. App chặn sớm trong `LedgerRepository._persist` (`readOnly`,
   `ownerOnly`) và ẩn ví chỉ xem khỏi bộ chọn ví khi ghi. Giới hạn: 20 ví chung/chủ, 20 thành viên/ví, 50 ví tham gia/
   người, 20 lời mời mở/ví, lời mời sống 7 ngày, 50 MiB bản ghi/ví.
4. **Khóa theo phiên bản**: máy chủ giữ khóa đã bọc cho từng (thành viên, phiên bản) - chủ ví: phong bì bọc bằng khóa
   chủ của chính mình; thành viên: khối `QS`. Mỗi bản ghi ví mang `key_ver`; đẩy bằng phiên bản khác phiên bản hiện tại
   ⇒ `stale_key` (409). Trên máy, mọi bản ghi của một ví niêm phong bằng MỘT phiên bản (`local_ver`); khóa mới về ⇒ mã
   hóa lại cả ví trong một giao tác. Bản ghi kéo về mang phiên bản cũ ⇒ niêm phong lại khi lưu.
5. **Thu hồi = xoay khóa** trong một giao tác máy chủ: xóa thành viên + mọi khối khóa của họ, ghi khóa phiên bản mới
   cho ĐÚNG tập thành viên còn lại (thiếu/thừa ⇒ `members_changed`), nâng `key_ver`. Khóa mới chỉ được cài trên thiết bị
   chủ ví SAU khi máy chủ nhận (hai thiết bị chủ ví xoay cùng lúc ⇒ một lượt thắng, lượt kia vấp khóa chính). Chủ ví mã hóa
   lại mọi bản ghi của ví và đẩy lên bằng phiên bản mới; bản ghi lọt bằng phiên bản cũ (đua với lượt xoay) được chủ ví
   niêm phong lại khi kéo về (tự lành). Thành viên tự rời ⇒ mất quyền ngay, máy chủ đặt `needs_rotation`, thiết bị chủ
   ví xoay khóa ở lượt đồng bộ sau. Thiết bị của người bị thu hồi/rời xóa dữ liệu ví khỏi máy ở lượt đồng bộ sau.
6. **Danh mục trong ví chung**: danh mục vẫn là bản ghi cấp tài khoản (của riêng mỗi người). Mỗi thiết bị có quyền ghi
   đăng bản ghi `wallet_cats` (trong không gian ví, E2EE) liệt kê danh mục mình dùng trong ví đó (tên, loại, biểu tượng,
   cha) để người khác hiện đúng tên. Chỉ để hiển thị, không vào màn quản lý danh mục.
7. **Xóa tài khoản / xuất dữ liệu**: xóa hẳn tài khoản chủ ví ⇒ xóa ví chung cùng bản ghi/thành viên/lời mời; tài khoản
   thành viên ⇒ rời các ví, báo chủ ví xoay khóa. Xuất dữ liệu máy chủ gồm khối khóa của mình + bản mã các ví mình là
   thành viên (vẫn chỉ là bản mã).

## 3. Hệ quả
- Máy chủ thấy thêm siêu dữ liệu: ai cùng ví với ai, quyền, ai ghi bản ghi nào lần cuối (`author_id`), số phiên bản
  khóa. Tên/email (D2) của thành viên hiện cho người cùng ví. Chấp nhận - cần để phân quyền; ghi ở THREAT_MODEL.
- Người bị thu hồi vẫn giữ dữ liệu ĐÃ tải về trước khi bị thu hồi (bản chất mọi hệ E2EE); xoay khóa bảo vệ dữ liệu mới
  và bản mã trên máy chủ.
- Bia mộ trong không gian ví chưa được dọn (P9 không có con trỏ kéo theo thiết bị cho ví) - dọn ở phase sau khi đo thấy
  cần. Chủ ví chưa chuyển quyền chủ cho người khác được; "ngừng chia sẻ" = thu hồi mọi thành viên.
- Bản app cũ (trước P9) của chủ ví đẩy bản ghi của ví đã chia sẻ vào không gian tài khoản ⇒ bị từ chối, nằm dirty tới
  khi cập nhật app.
- `KeyHierarchy.shareWalletKey` (khối X-Wing không xác thực, P1) KHÔNG dùng cho ví chung; giữ lại cho tương thích test.
