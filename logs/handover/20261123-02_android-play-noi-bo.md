# PHIẾU BÀN GIAO 20261123-02 - Android release đầu tiên, Play Thử nghiệm nội bộ ở bản nháp

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-1f`), 23/11/2026
- **Trạng thái**: MỞ. Thay mục 3.1 của phiếu `20261123-01` (các mục khác của phiếu đó vẫn còn hiệu lực).

## 1. Đã xong

- Khoá Android (👤 `scripts/android-keys.sh`, giữ ở `~/khoa-ky/qulythuchi`): vân tay trong `docs/RELEASE.md` mục 4;
  `release.yml` từ chối APK lệch vân tay. Environment `release` CHƯA bật Required reviewers (👤 quyết).
- `v26.11.2304-beta.1`: APK + desktop, 0/73 VirusTotal. CI có job Android (bắt compileSdk/R8 ở PR).
- Play: bản nháp Thử nghiệm nội bộ `26.11.2304-beta.1` (`docs/store/google-play.md` bước 4a).

## 2. Bẫy

- Playwright qua CDP (`tsb`) không chuyển tệp > 50 MB ⇒ AAB (≈ 106 MB) do 👤 bấm "Tải lên" tay.
- Ghi chú phát hành Play: mã ngôn ngữ `vi` (không `vi-VN`), `en-US`.
- Gradle daemon dùng chung giữa các phiên: đừng `--stop` khi phiên khác đang dựng; WSL 11 GB dễ cạn RAM khi nhiều
  phiên dựng Flutter cùng lúc.

## 3. Còn lại

1. XONG 23/11 21:03: xuất bản Thử nghiệm nội bộ cho danh sách "TsuDev Compass noi bo"; link
   https://play.google.com/apps/internaltest/4700541829715107418. 👤 cài thử trên máy thật, báo lỗi nếu có.
2. XONG 23/11: hồ sơ thanh toán đã có sẵn; agent tạo `tsudev_pro`/`nam` + `ung_ho_*` ở BẢN NHÁP (google-play.md bước 4b).
   23/11: `PLAY_SERVICE_ACCOUNT_JSON` đã có trên Render (`play-billing-b2@tsudev-com`, 👤 đặt), agent mời tài khoản
   vào Play Console (chỉ Quly Thu Chi, xem dữ liệu tài chính + quản lý đơn). Google còn trả 401 ⇒ B2 503. Phiên sau:
   chạy `services/sync-api/scripts/thu-b2-play.mjs` (xem đầu tệp). 24/11: ĐẠT, kiểm thử giấy phép + kích hoạt XONG.
   Còn: 👤 mua thử trên điện thoại (google-play.md bước 4b), rồi ghi kết quả vào phiếu tsudev QT5 mục 4 qua phiên
   tsudev (không sửa hộ). Quá 48 giờ vẫn 401 ⇒ kiểm lại lời mời ở
   Người dùng và quyền + Google Play Android Developer API đã bật trong `tsudev-com`.
3. Kênh gói: `packaging/package.json` đã có (PR #64), bật khi có bản chính thức (`docs/RELEASE.md` mục 6).
4. Việc dời từ P7: sao kê PDF XONG 24/11 (ADR-0020, PR #68, `deploy-2026.11.24.1`; bản app cài đặt có tính năng này
   từ thẻ phát hành KẾ TIẾP). Còn OCR desktop (Tesseract), widget/lối tắt iOS.
