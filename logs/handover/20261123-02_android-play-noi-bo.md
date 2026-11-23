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
   Còn: 👤 kiểm thử giấy phép + `PLAY_SERVICE_ACCOUNT_JSON` ⇒ kích hoạt ⇒ thử mua đầu-cuối (phiếu tsudev QT5 mục 4).
3. Kênh gói, bản chính thức, việc dời từ P7 - như phiếu `20261123-01` mục 3.2-3.4.
