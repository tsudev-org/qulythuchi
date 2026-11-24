# PHIẾU BÀN GIAO 20261124-01 - Việc cho phiên sau (sau phiên `qulythuchi-1f`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-1f`), 24/11/2026
- **Trạng thái**: MỞ. Thay phần "Còn lại" của phiếu `20261123-01` và `20261123-02` (hai phiếu đó giữ làm lịch sử).
- **Đọc kèm**: `logs/STATE.md`, `docs/RELEASE.md`, `docs/store/google-play.md` (bước 4a-4b), `docs/store/antivirus.md`,
  ADR-0020.

## 0. Hiện trạng tóm tắt (24/11/2026)

- Production `deploy-2026.11.24.1`: website, web app `/app/` (có nhập sao kê PDF), máy chủ đồng bộ.
- GitHub Releases: `v26.11.2304-beta.1` (công bố; Android APK + desktop), `v26.11.2401-beta.1` (có sao kê PDF) **NHÁP**
  vì AhnLab-V3 gắn cờ Windows zip - thư báo nhầm ĐÃ GỬI 24/11 (Resend id `01a20bcb-b2f6-7ce9-ae0a-d9421aec48a7`).
- Google Play: Thử nghiệm nội bộ `26.11.2304-beta.1` đã xuất bản (danh sách "TsuDev Compass noi bo"); `tsudev_pro`/`nam`
  + `ung_ho_20k/50k/100k/200k` ĐANG HOẠT ĐỘNG; Thử nghiệm giấy phép bật; kênh B2 tsudev.com ĐẠT (`thu-b2-play.mjs`).
- Chưa có nghiệm thu thật của 👤 cho P9, P7b, mua Pro.

## 1. Việc agent tự làm (theo thứ tự)

1. **AhnLab / Release nháp** - đầu phiên, kiểm VirusTotal API v3 (khoá `~/.config/tsudev/virustotal.env`, KHÔNG in
   khoá) cho `965ecbaf…06fd2` (zip) và `pdfrx_pdfium_gate.dll` (băm trong `docs/store/antivirus.md`). Có thể gọi
   `POST /api/v3/files/<sha256>/analyse` để quét lại trước khi đọc.
   - AhnLab hết cờ (0 engine trên zip) ⇒ `gh release edit v26.11.2401-beta.1 --draft=false -R tsudev-org/qulythuchi`,
     ghi dòng kết quả vào bảng `docs/store/antivirus.md`, cập nhật trang Tải về nếu cần.
   - Còn cờ quá 7 ngày kể từ 24/11 ⇒ đánh giá bỏ `pdfrx_pdfium_gate.dll` khỏi gói Windows (chỉ cần khi dùng
     `desktop_multi_window`): đọc mã `pdfium_dart` xem DLL có được nạp khi không bật gate không, dựng thử trên runner
     Windows + chạy test nhập PDF trên Windows TRƯỚC khi đổi. Không tự gửi thư Cynet (mục 2) khi 👤 chưa uỷ quyền.
2. **AGENTS.md B.2/B.5 + akb**: không đổi gì; nhớ Linux dev cần clang cho `flutter test` (build hook PDFium).
3. **P7 còn lại - OCR desktop (Windows/macOS/Linux)**: hiện chỉ Android/iOS có OCR hoá đơn (ML Kit). Viết ADR mới
   (ADR-0021) chọn phương án trước khi code - cân nhắc: Tesseract (Apache-2.0, cần gói `vie` traineddata ~ vài MB, bản
   native mỗi nền tảng, chuỗi cung ứng ghim băm như PDFium), OCR có sẵn của hệ điều hành (Windows.Media.Ocr, macOS Vision
   - không có trên Linux), hay để desktop dùng "nhập từ ảnh" không OCR. Yêu cầu: chạy trên máy, không gửi ảnh đi (D3),
   phiếu rà soát + mục THREAT_MODEL, test, ảnh chụp kiểm chứng.
4. **P7 còn lại - widget/lối tắt iOS** (Ghi nhanh như widget Android): WidgetKit extension + App Intents/Quick Actions,
   CI Apple (`apple.yml`) phải dựng được; KHÔNG hiển thị số dư/dữ liệu D3 trên widget khi máy khoá (giống widget
   Android). ADR hoặc mục bổ sung ADR-0012 + phiếu rà soát.
5. **Sau mỗi tính năng có trong app cài đặt**: cắt thẻ beta mới (`vYY.M.DDNN-beta.N`), theo dõi job VirusTotal; có cờ
   ⇒ quy trình như mục 1 (thư soạn ở `docs/store/antivirus.md`; gửi qua Resend từ `security@tsudev.com` CHỈ khi 👤 uỷ
   quyền cho lần đó).

## 2. Việc chờ 👤 - và agent làm gì khi 👤 báo kết quả

| Việc 👤 | Hướng dẫn | Khi 👤 báo ĐẠT | Khi 👤 báo LỖI |
| --- | --- | --- | --- |
| Mua thử Pro + Ủng hộ trên điện thoại (tài khoản trong "TsuDev Compass noi bo") | `docs/store/google-play.md` bước 4b "Thử mua đầu-cuối" | Ghi kết quả vào google-play.md + STATE; nhắn phiên tsudev ghi phiếu QT5 mục 4 (KHÔNG sửa hộ repo tsudev) | Đọc log Render `[play]`/`[rp]` (API Render, `~/.config/tsudev/render.env`), log Worker (`wrangler tail`), sửa, test, deploy |
| Nghiệm thu P9 ví chung (2 tài khoản tsudev thật, 2 thiết bị) | `logs/handover/20261119-03_p9-xong.md` mục 2b | Đánh dấu P9 nghiệm thu trong STATE | Tái hiện bằng test (`apps/app/test/p9_*`, `services/sync-api/test`), sửa, phiếu rà soát nếu đụng khoá/chia sẻ |
| Nghiệm thu P7b ảnh hoá đơn (chụp trên điện thoại, mở ở máy 2 / `/app/`) | `logs/handover/20261120-03_p7b-tep-dinh-kem-xong.md` mục 2b | Đánh dấu P7b nghiệm thu | Như trên (`p7b_*` test) |
| (Tuỳ chọn) Gửi thư Cynet | `docs/store/antivirus.md` mục 2 | - | - |
| Bật `PRO_ENFORCE=on` + đồng ý xoá dữ liệu thử nghiệm D1/R2 | ADR-0016/0018 | Đặt biến Worker, deploy, kiểm 402 khi không Pro | - |

Agent KHÔNG tự đăng nhập tài khoản Google/tsudev của 👤, không gõ/đọc mật khẩu, không dùng thiết bị giả lập với tài
khoản thật để "nghiệm thu thay".

## 3. Khi 👤 nghiệm thu xong P9 + P7b + mua Pro

1. Cắt bản chính thức `vYY.M.DDNN` (không `-beta`) - `docs/RELEASE.md` mục 1.
2. Bật kênh gói - `docs/RELEASE.md` mục 6: chuyển `planned` ⇒ `channels` trong `packaging/package.json`, PR vào
   `tsudev-org/scoop-bucket`, `tsudev-org/homebrew-tap`, `tsudev-org/linux-packages` theo AGENTS.md từng repo (nếu repo
   đó có phiên khác đang làm ⇒ viết phiếu + nhắn, không sửa hộ).
3. Play: tải AAB của bản chính thức (artifact `play-aab`, 👤 tải tay vì > 50 MB) ⇒ Thử nghiệm kín 12 người × 14 ngày
   (yêu cầu tài khoản Play cá nhân mới) ⇒ hồ sơ "Việc 👤 trước khi gửi duyệt" trong google-play.md.
4. Trang Tải về: đổi "Bản thử nghiệm" ⇒ "Dùng được ngay" cho nền tảng đã có bản chính thức.

## 4. Bẫy cần nhớ (chi tiết ở AKB qulythuchi)

- Play Console qua `~/projects/logs/tools/browser/tsb.sh` (hồ sơ `play`): nhãn NFD ⇒ so `normalize('NFC')`; KHÔNG bấm
  toạ độ ở thanh dưới (trùng vị trí "Kích hoạt"); nút phát hành/mời/kích hoạt chỉ mở bằng `--allow "<nhãn>"` sau khi 👤
  xác nhận bằng lời; Playwright không chuyển tệp > 50 MB.
- Sau khi mời tài khoản dịch vụ vào Play Console, Play Developer API trả 401 khoảng 2 giờ.
- Thử nghiệm giấy phép là cài đặt cấp TÀI KHOẢN (ảnh hưởng app La bàn) ⇒ báo phiên app-la-ban.
- Release workflow: thẻ đã đẩy không xoá/đổi tên; Windows cần `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`;
  compileSdk 37 + `proguard-rules.pro` cho ML Kit.
