# ADR-0017: P7b Tệp đính kèm ảnh hóa đơn mã hóa đầu-cuối - khóa tệp riêng, ngữ cảnh `attf`, làm sạch ảnh trước khi mã hóa

- **Trạng thái**: ĐÃ CHẤP NHẬN (bổ sung ADR-0002/0007/0010/0015/0016, không thay thế)
- **Ngày**: 20/11/2026
- **Người quyết định**: agent-qulythuchi (việc dời từ P7 trong `logs/STATE.md`; gate Pro theo ADR-0016)
- **Liên quan**: `packages/core/lib/src/attachments/*`, `conformance/envelope-v1.json` (mục `attachment-file`),
  `services/sync-api/{migrations/0005_wallet_files.sql,src/files/routes.ts}`, `apps/app/lib/attachments/*`,
  `docs/security-reviews/20261120-p7b-tep-dinh-kem.md`

## 1. Bối cảnh

Người dùng muốn chụp/chọn ảnh hóa đơn gắn vào giao dịch, đồng bộ sang thiết bị khác và cho người cùng ví chung xem.
Ảnh hóa đơn là D3 (số tiền, nơi mua, đôi khi số thẻ, tên, địa chỉ) và ảnh điện thoại mang EXIF (GPS, thời điểm, máy).
Máy chủ P5 đã có `PUT/GET/DELETE /api/v1/files/:id` (R2, phong bì v1, hạn mức) nhưng chỉ theo tài khoản: thành viên ví
chung không đọc được ảnh do người khác tải lên. ADR-0007 mục 5 có sẵn ngữ cảnh `att|ví|id` (khối đệm 4096) chưa ai dùng.

## 2. Quyết định

1. **Bản ghi đính kèm** loại `attachment` (đồng bộ như mọi bản ghi, cùng ví với giao dịch): `txnId`, `key` (khóa tệp
   FK, base64 32 B), `mime` (`image/jpeg`), `size` (byte bản rõ), `w`, `h`, `fmt` (= 1). id bản ghi = id tệp (UUID v4).
   Bản ghi được niêm phong bằng khóa ví ⇒ **FK được bọc bởi khóa ví** qua phong bì bản ghi (AAD `rec|ví|attachment|id`).
   Xoay khóa ví chung (ADR-0015) mã hóa lại bản ghi ⇒ FK được bọc lại tự động, KHÔNG phải mã hóa lại ảnh.
2. **Khóa tệp riêng mỗi tệp**: FK = 32 B ngẫu nhiên (`randombytes`), không bao giờ dùng lại. Lộ một FK chỉ lộ một ảnh.
3. **Phong bì tệp**: giữ byte phong bì v1 (`'Q' 'T' 01 01 ‖ nonce 24 ‖ XChaCha20-Poly1305(sodium_pad(...))`) - máy chủ
   vẫn kiểm được đầu `QT 01 01`. Ngữ cảnh MỚI có phiên bản `attf` (thay `att` cũ, chưa từng dùng nên không cần đọc lại):
   `attf|<ví hoặc acct>|<id giao dịch>|<id tệp>`, **khối đệm 64 KiB** (4096 lộ cỡ ảnh quá mịn). AAD gắn ví + giao dịch +
   tệp ⇒ máy chủ không tráo được ảnh giữa giao dịch/ví (đã có FK riêng, đây là lớp thứ hai). Bản rõ = đúng byte JPEG;
   mọi siêu dữ liệu nằm trong bản ghi đính kèm đã mã hóa. Đổi định dạng ⇒ ngữ cảnh `attf2` + ADR mới + sinh lại vector.
4. **Làm sạch ảnh TRƯỚC khi mã hóa** (lõi, Dart thuần, gói `image`): nhận ≤ 25 MiB và ≤ 50 triệu điểm ảnh, giải mã
   (JPEG/PNG/WebP/GIF/BMP/TIFF), xoay theo EXIF Orientation rồi **bỏ toàn bộ EXIF/GPS/XMP/ICC/chú thích**, thu cạnh dài
   ≤ 2000 px, mã hóa LẠI thành JPEG chất lượng 82 (giảm dần tới 60 rồi thu 1600/1200 px tới khi ≤ 2 MiB). Luôn mã hóa
   lại (không bao giờ gửi byte gốc) ⇒ không siêu dữ liệu nào lọt. HEIC: app nhờ `image_picker` đổi sang JPEG trước.
   Tên tệp gốc KHÔNG được lưu ở đâu cả (kể cả bản ghi mã hóa).
5. **Giới hạn**: tối đa 5 ảnh mỗi giao dịch; bản mã ≤ 10 MB (máy chủ, giữ như P5); hạn mức tệp 1 GiB mỗi tài khoản Pro,
   tính cả tệp trong các ví chung mình làm chủ.
6. **Máy chủ - tệp của ví chung** (migration MỚI `0005_wallet_files.sql`): bảng `wallet_files(wallet_id, id, size,
   uploader_id, created_at)`, R2 `w/<wallet_id>/<id>`; `PUT|GET|DELETE /api/v1/wallets/:wid/files/:id`. Ghi/xóa: chủ hoặc
   người ghi, theo Pro của CHỦ ví (402 `owner_no_pro`); đọc: mọi thành viên; không phải thành viên ⇒ 404. Tệp cá nhân giữ
   `/api/v1/files/:id`, nhưng từ chối `wallet_id` là ví chung (409 `shared_wallet`, như `/sync/push`). Xóa ví/tài khoản/
   dọn Pro hết hạn ⇒ xóa luôn đối tượng R2 `w/<ví>/` của ví mình làm chủ.
7. **App**: ảnh đã niêm phong lưu cục bộ trong CSDL (bảng `blobs`, schema v3 - cùng một đường cho cả web) ⇒ ở máy cũng
   chỉ có bản mã (FK nằm trong bản ghi đã mã hóa). Đồng bộ: sau khi đẩy bản ghi, tải lên các tệp `pending`; 402
   `pro_required` ⇒ GIỮ ảnh cục bộ ở trạng thái chờ, không xóa, thử lại lượt sau; tải về khi mở xem rồi đệm cục bộ. Xóa
   ảnh/giao dịch ⇒ bia mộ bản ghi + hàng đợi `DELETE` tệp. Người xem ví chung chỉ xem được.

8. **Đổi ví của giao dịch** (bản ghi mới, id mới - ADR-0004): app mã hóa lại từng ảnh sang ví/giao dịch mới (khóa tệp
   mới) và xóa ảnh cũ trong cùng giao tác; ảnh chưa tải về máy ⇒ từ chối đổi ví (`attachmentsNotLocal`).
9. Trường `attachmentIds` của `Txn` (có từ P3, chưa dùng) KHÔNG được dùng: danh sách trong một trường sẽ mất ảnh khi hai
   thiết bị cùng thêm (ghi sau thắng theo trường). Liên kết đi theo `txnId` trong từng bản ghi đính kèm.

## 3. Hệ quả

- Máy chủ thấy thêm: số tệp, cỡ đã đệm (bội 64 KiB), thời điểm, ví nào, ai tải lên. Không thấy ảnh, loại ảnh, giao
  dịch nào, tên tệp.
- Thành viên bị thu hồi đã từng tải ảnh về vẫn giữ bản đã xem (như bản ghi - ADR-0015 mục 3); máy chủ trả 404 cho lượt
  tải mới.
- Ảnh trên máy bị nén lại (không giữ bản gốc độ phân giải cao) - đủ đọc hóa đơn, tiết kiệm hạn mức.

## 4. Phương án đã loại

- URL ký trước R2: cần cấp khóa S3, không kiểm quyền ở từng lượt (ADR-0010 mục 4).
- Mã hóa ảnh thẳng bằng khóa ví: xoay khóa ví phải tải về + mã hóa lại mọi ảnh.
- Giữ EXIF rồi xóa từng thẻ: dễ sót (XMP, MakerNote, ảnh thu nhỏ nhúng); mã hóa lại toàn ảnh chắc chắn hơn.
