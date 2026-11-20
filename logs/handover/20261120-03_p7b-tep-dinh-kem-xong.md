# PHIẾU BÀN GIAO - P7b xong: tệp đính kèm ảnh hóa đơn mã hóa đầu-cuối

- **Mã phiếu**: 20261120-03
- **Từ**: agent-qulythuchi (phiên P7b) - **Đến**: phiên kế tiếp của repo qulythuchi
- **Thời điểm**: 20/11/2026
- **Trạng thái**: MỞ (phiếu 20261120-01 vẫn MỞ cho phần app T7)

## 1. Đã làm

- Thiết kế: ADR-0017 (ĐÃ CHẤP NHẬN), phiếu rà soát `docs/security-reviews/20261120-p7b-tep-dinh-kem.md`, THREAT_MODEL T29.
- Lõi (`packages/core/lib/src/attachments/`): `Attachment` (bản ghi loại `attachment`: `txnId`, khóa tệp `key`, `mime`,
  `size`, `w`, `h`, `fmt`=1; id bản ghi = id tệp), `AttachmentCipher` (phong bì v1, ngữ cảnh
  `attf|ví hoặc acct|giao dịch|tệp`, đệm 64 KiB), `ImageSanitizer` (gói `image` 4.13.1; luôn mã hóa lại JPEG, bỏ
  EXIF/GPS/ICC/chú thích, xoay theo Orientation). Vector `attachment-file` trong `conformance/envelope-v1.json`.
- Máy chủ: migration `0005_wallet_files.sql`; `src/files/routes.ts` thêm `PUT|GET|DELETE /api/v1/wallets/:wid/files/:id`
  (R2 `w/<ví>/<id>`), `fileBytesUsed` (hạn mức 1 GiB gồm tệp ví mình làm chủ), `deleteOwnedWalletFiles` (gọi ở xóa tài
  khoản + dọn Pro hết hạn). `/files/:id?wallet_id=<ví chung>` ⇒ 409 `shared_wallet`.
- App: `RecordStore` schema v3 (`blobs`: `state` chờ/đã đồng bộ/chờ xóa, `remote` không gian máy chủ);
  `LedgerRepository` (gắn/mở/xóa ảnh, xóa giao dịch xóa ảnh, đổi ví mã hóa lại ảnh, `pruneAttachmentCache`);
  `lib/attachments/` (`FileSync`, `AttachmentPicker`, `AttachmentsSection` + trang xem); `SyncState.filesPending/filesBlocked`
  hiện ở "Tài khoản & đồng bộ".
- Kết quả: PR #32 gộp `aa7fff2`, CI xanh cả iOS/macOS (ảnh chụp đã xem). Production: Worker `f4291be8`, migration 0005
  đã áp D1 remote; `/`, `/app/`, health 200; đường tệp 401 khi chưa đăng nhập.

## 2. Việc kế tiếp / lưu ý

1. Trường `Txn.attachmentIds` (có từ P3) KHÔNG dùng (ADR-0017 mục 9) - liên kết theo `txnId` trong bản ghi đính kèm.
2. Đổi giao dịch sang ví khác khi ảnh chưa tải về máy ⇒ báo `attachmentsNotLocal` (người dùng mở ảnh trước). Có thể làm
   tự tải về trước khi đổi ví nếu người dùng phàn nàn.
3. Ảnh chỉ JPEG/PNG/WebP/GIF/BMP/TIFF; HEIC trên iOS do `image_picker` đổi sang JPEG (chưa thử trên máy iPhone thật).
4. App T7 (Pro) vẫn chờ `tsudev-org/tsudev-ui-flutter` (20/11 CHƯA có). Khi làm: 402 `reason` của tệp ví chung là
   `owner_no_pro` - `FileSync` hiện coi mọi 402 `pro_required` là `blocked` (giữ ảnh cục bộ), màn Pro cần phân biệt.
5. Việc khác trong STATE: sao kê PDF, OCR desktop, widget iOS; P10.

## 2b. Việc cần chủ dự án (👤)

- [ ] Nghiệm thu trên production: điện thoại Android (hoặc `/app/`) gắn ảnh hóa đơn vào một giao dịch ⇒ đồng bộ ⇒ mở trên
  máy thứ hai/`/app/` thấy ảnh; trong ví chung, người cùng ví xem được, người xem không có nút thêm/xóa.
- [ ] (còn từ trước) nghiệm thu ví chung hai tài khoản; bật `PRO_ENFORCE=on` khi app T7 xong.

## 3. File liên quan / đang khóa

| Đường dẫn | Lý do | Còn khóa? |
| --- | --- | --- |
| (không) | | Không |

## 4. Rủi ro đã biết

- Máy chủ thấy số ảnh, cỡ đệm (bội 64 KiB), thời điểm, người tải lên ví chung.
- Giải mã ảnh bằng Dart thuần chậm trên máy yếu (isolate trên máy gốc; web chạy luồng chính, vài giây với ảnh lớn).
- Người bị thu hồi khỏi ví chung giữ ảnh đã tải trước đó (bản chất E2EE).

## 6b. PROMPT CHUẨN CHO PHIÊN SAU

Như phiếu 20261119-04 mục 6b, thay phiếu đọc ở bước 1 bằng `logs/handover/20261120-01_t7-may-chu-xong.md` và phiếu này.
Làm app T7 ⇒ trước tiên kiểm `gh repo view tsudev-org/tsudev-ui-flutter` (PRO-C2); chưa có ⇒ KHÔNG viết mã Pro trong app.
Đụng ảnh đính kèm ⇒ đọc ADR-0017; đổi ngữ cảnh/định dạng ⇒ `attf2` + ADR mới + sinh lại `conformance/` CÙNG PR.
Đụng `apps/app` ⇒ chờ job Apple của PR xanh, xem ảnh chụp trong artifact trước khi gộp. Test widget có form dài ⇒
`tapVisible` (cuộn rồi bấm), không `tester.tap` thẳng nút ở đáy.

## 7. Kết quả xử lý (agent nhận điền sau khi thực hiện)

-
