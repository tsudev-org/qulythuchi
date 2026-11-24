# STATE.md - Trạng thái project Quly Thu Chi

> **Phiên kế tiếp (phiếu toàn hệ 20261117-P2):** đọc `~/projects/logs/handover/20261117-P2_ke-hoach-phan-phoi-tin-cay-da-nen-tang.md` hàng 10 (`qulythuchi`) ở mục 3,
> rồi `.standards/docs/DISTRIBUTION_TRUST.md` (chuẩn v3.7.0) và `.standards/docs/VERSIONING.md` mục 2. Khuôn thẻ/tên tệp mới
> chỉ áp cho bản phát hành KẾ TIẾP, đọc mục 2.4 (updater đã cài) trước khi đổi.

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`. Kế hoạch tổng: `docs/PLAN.md`.

## Hàng đợi task (làm từ trên xuống)

> **Phiên kế tiếp:** đọc phiếu `logs/handover/20261124-03_viec-phien-sau.md` (thứ tự việc, việc chờ 👤 và cách xử lý
> khi 👤 báo kết quả, bẫy đã gặp - có bẫy tắt máy đột ngột làm rỗng tệp).

Agent tự làm:
- [ ] **ƯU TIÊN ĐẦU**: nâng Flutter 3.47.8 ⇒ 3.50.1 (Dart 3.14.0) + `sodium` 4.1.5+1 + `pdfrx` 3.1.0, MỘT PR, có phiếu
  rà soát (đụng mật mã) - kế hoạch từng bước: phiếu 20261124-03 mục 5.
- [ ] Ngân sách APK mỗi ABI (AGENTS.md B.4): thử ML Kit OCR + quét mã vạch bản "unbundled" (phiếu 20261124-03 mục 1.2).
- [ ] Đo khởi động desktop (Windows/macOS/Linux) - mục cuối LANGUAGE_SELECTION 5.1 còn thiếu.
- [ ] QR vai XÁC NHẬN (app quét QR ở `/login` của PC): CHỜ QR2b phía tsudev.
- [ ] Sau mỗi tính năng: cắt thẻ beta mới, theo dõi job VirusTotal.

Chờ 👤 (agent xử lý khi 👤 báo kết quả - phiếu 20261124-03 mục 2):
- [ ] 👤 Mua thử Pro + Ủng hộ trên điện thoại (`docs/store/google-play.md` bước 4b); kết quả ⇒ phiên tsudev ghi QT5 mục 4.
- [ ] 👤 Nghiệm thu P9 ví chung bằng HAI tài khoản tsudev thật (`logs/handover/20261119-03_p9-xong.md` mục 2b); thử
  đăng nhập `/app/`; gửi thử một thư tới địa chỉ chuyển tiếp thật.
- [ ] 👤 Nghiệm thu P7b ảnh hoá đơn (`logs/handover/20261120-03_p7b-tep-dinh-kem-xong.md` mục 2b).
- [ ] 👤 Thử Quét hóa đơn trên máy tính với ảnh hóa đơn thật (bản `v26.11.2403-beta.1`, phiếu 20261124-03 mục 2).
- [ ] 👤 Thử "Quét để đăng nhập" trên điện thoại (APK `v26.11.2403-beta.1`) với QR ở tsudev.com (phiếu 20261124-03 mục 2).
- [ ] (Tuỳ chọn) 👤 uỷ quyền gửi thư Cynet (`docs/store/antivirus.md` mục 2).
- [ ] 👤 Bật `PRO_ENFORCE=on` + đồng ý xoá dữ liệu thử nghiệm D1/R2.
- [ ] 👤 Play: tài khoản tsudev cho người duyệt Google (có Pro) + điền ở "Quyền truy cập ứng dụng"; Thử nghiệm kín
  12 người × 14 ngày khi có bản chính thức.
- [ ] Apple: 👤 Apple Developer Program (đầu 2027) ⇒ tsudev.com bật Apple; workflow đã sẵn bước notarize (bí mật APPLE_*).

Sau khi 👤 nghiệm thu P9 + P7b + mua Pro (phiếu 20261124-02 mục 3):
- [ ] Bản chính thức `vYY.M.DDNN` ⇒ bật kênh gói (`docs/RELEASE.md` mục 6) ⇒ AAB Thử nghiệm kín ⇒ trang Tải về.

Phiên khác làm:
- [ ] Thẻ tsudev.com/apps: phiếu `~/projects/tsudev/logs/handover/20261118-QT3_*` (phiên tsudev).

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

- 24/11/2026 - Phiên `qulythuchi-08` (agent-qulythuchi, nối phiên bị tắt đột ngột 22:32): khôi phục sau sự cố (5
  object git + `refs/stash` + `.github/dependabot.yml` + 4251 tệp `apps/site/node_modules` bị cắt về 0 byte ⇒ chuyển
  object rỗng ra ngoài, `git fetch`, fsck sạch; `npm ci` lại; AKB `ISS-20261124-2309-41e4`). PR #80: dependabot bỏ qua
  typescript major (#79 đỏ: TS 7 vs peer typescript-eslint `<6.1.0`) ⇒ #83 (npm sync-api) + #82 (actions) gộp; #84/#85
  đóng (cần Dart 3.14). **AhnLab-V3 đã gỡ cờ** ⇒ bỏ nháp `v26.11.2401-beta.1` + `v26.11.2402-beta.1` (zip 0/7x; DLL
  còn Cynet). Ngân sách tốc độ: website LCP trung vị 1,9 s, CLS ≤ 0,053, JS 2,2 KB (đạt); APK arm64 ~57 MB cài /
  ~27,5 MB tải (vượt, ghi B.4). Vision macOS có tiếng Việt `vi-VT` (ADR-0021 mục 5, PR #81). LÊN PRODUCTION
  `deploy-2026.11.24.3` (Worker `db6c9687`, màn chào TsuSignInScreen; Playwright `/app/` Sáng + Tối 0 lỗi console) và
  `deploy-2026.11.24.4` (Worker `5ff4dc02`, #83; máy chủ 87 test): `/`, `/app/`, `/tai-ve/`, health, providers 200,
  `/auth/web/start` 302.
- 24/11/2026 - QR3 + chuẩn v5.3.0 (agent-qulythuchi, phiên `qulythuchi-07`, PR #78, ADR-0023, phiếu rà soát
  `20261124-qr3`, THREAT_MODEL T34): màn chào `TsuSignInScreen` (`tsudev_ui` v0.4.0, ô đồng ý 13.4), "Quét để đăng nhập"
  Android/iOS (`TsuXdLink.parse` ⇒ `/x/<id>` trong trình duyệt hệ thống ⇒ OIDC; QR không mang khoá E2EE); theme điều
  hướng `tsuNavigationBarTheme`; knip 6.44.2 + ruff ghim, bước CI. Thẻ `v26.11.2403-beta.1` tự công bố (VirusTotal sạch).

- 24/11/2026 - OCR desktop + widget iOS + UI1 + chuẩn v5.1.0 (agent-qulythuchi, phiên `qulythuchi-07`):
  **OCR hóa đơn trên desktop** (ADR-0021, phiếu rà soát `20261124-ocr-desktop`, T33): Windows.Media.Ocr (C++/WinRT trong
  runner), Vision (macOS, + entitlement `files.user-selected.read-only`), Tesseract hệ thống (Linux, `.deb` Recommends
  `tesseract-ocr-vie`); không thêm DLL vào gói; job CI `desktop-ocr` chạy engine THẬT ⇒ đúng nguyên văn trên cả 3 (PR
  #74). **Widget "Ghi nhanh" + Quick Actions iOS** (ADR-0022, phiếu `20261124-widget-ios`): target WidgetKit thêm vào
  pbxproj, không dữ liệu/App Group; `apple.yml` kiểm `.appex` (PR #75). **UI1** (phiếu `20261124-QR1`): biểu tượng
  thanh điều hướng ≥ 3:1 Sáng/Tối + test chặn tái phát; `.standards` v5.1.0 + cổng cây sạch sau build (PR #73).
  CHANGELOG #76. App 159 test. LÊN PRODUCTION `deploy-2026.11.24.2` (Worker `fa8d1759`): `/`, `/app/`, health,
  `/tai-ve/`, providers 200. Thẻ `v26.11.2402-beta.1`: dựng đủ 3 desktop + APK, ký Sigstore + SLSA; NHÁP vì AhnLab-V3 gắn cờ zip Windows (cùng DLL). AhnLab quét lại
  24/11 chiều: `v26.11.2401-beta.1` vẫn cờ ⇒ giữ nháp.

- 24/11/2026 - Nhập sao kê PDF, kể cả có mật khẩu (agent-qulythuchi, phiên `qulythuchi-1f`, ADR-0020, phiếu rà soát
  `20261124-sao-ke-pdf`, THREAT_MODEL T32): `pdfrx` 3.0.0 (PDFium, ghim) chỉ lấy chữ; lõi `pdfGlyphsToRows` dựng bảng
  (cột theo hồ sơ chiếu dòng giao dịch + tiêu đề; gộp diễn giải xuống dòng chỉ ở cột chữ + cùng trang; bỏ tiêu đề lặp);
  đi tiếp luồng ghép cột CSV/XLSX. CSP `/app/` thêm `blob:` vào `connect-src` (đo bằng Playwright). Lõi 7 test, test app
  khứ hồi PDF do app xuất (60 dòng, 3 trang, PDFium thật trên CI). PR #68 CI xanh (cả iOS/macOS/Android). LÊN PRODUCTION
  `deploy-2026.11.24.1` (Worker `499f067b`): `/`, `/app/`, health, `/tai-ve/`, `pdfium.wasm` 200; Playwright trên
  production nhập PDF thử ra 3 giao dịch, 0 lỗi console. Linux dev cần clang cho `flutter test` (AGENTS.md B.2).

- 24/11/2026 - Play mở bán thử (agent-qulythuchi, phiên `qulythuchi-1f`, 👤 uỷ quyền): tài khoản dịch vụ
  `play-billing-b2@tsudev-com` mời vào Play Console (chỉ Quly Thu Chi: xem tài chính + quản lý đơn); lợi ích gói Pro;
  Thử nghiệm giấy phép = "TsuDev Compass noi bo" (cấp tài khoản, đã báo phiên app-la-ban); kích hoạt `tsudev_pro`/`nam`
  + `ung_ho_*`. Kênh B2 ĐẠT (`thu-b2-play.mjs`: 422 với token giả). Còn 👤 mua thử trên điện thoại.

- 23/11/2026 - Play sản phẩm + kênh gói + dọn (agent-qulythuchi, phiên `qulythuchi-1f`): Play nội bộ ĐÃ xuất bản
  (👤 xác nhận); hồ sơ thanh toán có sẵn ⇒ tạo `tsudev_pro`/`nam` + `ung_ho_*` ở bản nháp (PR #62, #63). Test máy chủ
  chập chờn sửa bằng `CLEANUP_SAMPLE_RATE` (PR #60). Phiếu SEC1 ĐÓNG (PR #61). `packaging/package.json` (PR #64, kênh
  `planned` tới bản chính thức). LÊN PRODUCTION `deploy-2026.11.23.3` (Worker `18200764`): `/`, `/app/`, health,
  `/tai-ve/`, providers 200.

- 23/11/2026 - Android release đầu tiên (agent-qulythuchi, phiên `qulythuchi-1f`): 👤 tạo khoá APK + upload
  (`scripts/android-keys.sh`); vân tay ghi `docs/RELEASE.md` + ghim trong `release.yml` (PR #57, #59). Lần đầu dựng
  Android release lộ 2 lỗi: compileSdk 37 (flutter_local_notifications 23, androidx.core 1.19) + R8 thiếu lớp ML Kit
  Trung/Nhật/Hàn ⇒ `proguard-rules.pro`; thêm job CI Android (PR #58). `v26.11.2304-beta.1` có APK (ký `34:41:64:51...`,
  versionCode 26112304, 0/73 VirusTotal); thẻ `v26.11.2302-beta.1`, `v26.11.2303-beta.1` hỏng, không Release.
  `deploy-2026.11.23.2` (Worker `c118a6e7`): trang Tải về có Android. Play: AAB vào bản nháp Thử nghiệm nội bộ
  (`docs/store/google-play.md` bước 4a); 👤 xác nhận ⇒ agent xuất bản cho danh sách "TsuDev Compass noi bo" (21:03).

- 23/11/2026 - P10 phần desktop + kiểm định (agent-qulythuchi, phiên `qulythuchi-1f`): `release.yml` (thẻ
  `vYY.M.DDNN[-beta.N]` ⇒ Windows zip, macOS zip sandbox, Linux deb + tar.gz; Android APK/AAB chỉ khi có khoá, Gradle
  chặn khoá debug; SBOM SPDX, SHA256SUMS ký Sigstore, chứng thực SLSA + bundle; Release nháp ⇒ VirusTotal ⇒ công bố),
  Environment `release` (chỉ thẻ `v*`), `scripts/package-linux.sh`, `scripts/android-keys.sh` (👤), `docs/RELEASE.md`;
  DAST `dast.yml` (ZAP baseline `/`, `/app/` + VirusTotal tên miền, hằng tuần). Sửa: Windows STL1011 (VS 18,
  local_auth_windows), thêm COEP `require-corp` (ZAP 90004; đã thử /app/ cục bộ + production: Argon2/sinh 24 từ chạy).
  PR #53 (log STD50), #54, #55 gộp. LÊN PRODUCTION `deploy-2026.11.23.1` (Worker `38c7ef91`): `/`, `/app/`, health,
  `/tai-ve/`, providers 200, `/auth/web/start` 302. RELEASE ĐẦU TIÊN `v26.11.2301-beta.1` (Pre-release): 4 tệp 0/74
  VirusTotal, `sha256sum -c` + `gh attestation verify` đạt. Thẻ `v26.11.2201-beta.1` lần chạy hỏng Windows, KHÔNG có
  Release (giữ thẻ, không xoá). Phiếu AV1 ĐÓNG.

- 22/11/2026 - STD50 bản sắc sản phẩm v5.0.0 (agent-qulythuchi, phiên `qulythuchi-2012`), phiếu
  `logs/handover/20261121-STD50_*` ĐÓNG. PR #51 (`.standards` v5.0.0; website nạp `tokens.css` + `products.css`,
  `data-product="qulythuchi"`, xoá `apps/site/src/styles/tokens.css`; app `gen_tokens.dart` gộp đè
  `products/qulythuchi.json` + bo góc `mem`, tiêu đề/số tiền lớn Be Vietnam Pro 600/700 kèm OFL; màu navy cứng ở web
  app/widget Android đổi sang nền chung) gộp `153ab16`. PR #52 (bố cục `bang-dieu-khien` trang chủ website: thanh mục
  trái + thẻ số liệu; hoạ tiết `cot-tang-truong` một hình học cho hero, og-image, thẻ tổng số dư app) gộp `c599394`.
  Cả hai CI xanh (cả iOS/macOS); app 143 test. Ảnh trước/sau `logs/anh/20261121-STD50/`. LÊN PRODUCTION
  `deploy-2026.11.22.1` (Worker `68af605a`): `/`, `/app/`, health, `/tai-ve/`, `/og-image.png`, providers 200; trang
  chủ có `data-product="qulythuchi"`. Ảnh nổi bật Google Play GIỮ bản cũ (đã nộp) - đổi khi cập nhật hồ sơ Play.

- 21/11/2026 - STD43 + việc dở phiên 429b (agent-qulythuchi, phiên `qulythuchi-fa79`): `.standards` v4.3.0; máy chủ
  `GET /api/v1/auth/providers` (hỏi IdP tsudev.com, đệm 5 phút, danh sách trắng google/apple/github, IdP lỗi ⇒ Google +
  GitHub, không bao giờ Apple), `idp_hint=apple` được nhận; app dựng nút theo danh sách + nút Apple theo HIG. Phiếu rà
  soát `20261121-std43-idp-providers`. Lúc làm, tsudev chưa đưa endpoint lên production (404 ⇒ dự phòng, như cũ).
  BP 16946 `crypto_pfs` sửa lời giải thích theo đo thật (TLS 1.3 mặc định có PFS; edge còn nhận bộ mã TLS 1.2 RSA
  cũ - gói Cloudflare miễn phí không tuỳ chỉnh bộ mã; đặt Minimum TLS 1.3 là việc của cả zone tsudev.com, không
  tự làm) - đã nộp, vẫn passing 100%. Đối chiếu hợp đồng Play B2: 409 `purchase_pending` từng bị coi là biên nhận
  hỏng ⇒ sửa thành `purchase_unavailable` (thử lại), ADR-0019 bổ sung. PR #47 CI xanh (cả iOS/macOS), gộp `4606657`.
  LÊN PRODUCTION `deploy-2026.11.21.1` (Worker `d19d3ac0`): `/`, `/app/`, health, `/bao-mat/` 200;
  `/api/v1/auth/providers` = Google, GitHub (`source: idp`, endpoint tsudev #351 đã sống). Lúc đo, discovery OIDC
  tsudev.com trả 429 ⇒ `/auth/*/start` 502 mọi lối (lớp Cloudflare trước Render; tsudev vá #353). Phía ta PR #49:
  thử lại 429/503, discovery/JWKS đệm cũ ≤ 24 giờ, POST /token chỉ thử lại 429 - `deploy-2026.11.21.2` (Worker
  `fd413096`); đo lại `/auth/web/start` 302, `/`, `/app/`, health, providers 200.
- 21/11/2026 - Phiên `qulythuchi-429b` (bị cắt ngang): dependabot bỏ qua vitest major (#44), `.standards` v4.2.0 (#45).

- 21/11/2026 - GP1 Play Console bước 1-3 (agent-qulythuchi, phiên `qulythuchi-dd7b`): tạo app `com.tsudev.qulythuchi`
  (mã Play 4975262284467716976); 11/11 tờ khai Nội dung ứng dụng, danh mục Tài chính, liên hệ, trang thông tin vi+en
  (biểu tượng, ảnh nổi bật, 3 ảnh điện thoại) - tất cả LƯU, chưa gửi. Bước 4 (sản phẩm Play) DỪNG: chưa có hồ sơ thanh
  toán + chưa có AAB có BILLING. Hồ sơ: `docs/store/google-play.md`. Trang `/bao-mat` sửa (email/tên/ảnh đại diện,
  mục xóa tài khoản) - CHƯA lên production.

- 20/11/2026 - LG1 logo riêng Quly Thu Chi (agent-qulythuchi, PR #41, `deploy-2026.11.20.2`): ảnh gốc
  `assets/brand/source/logo-qulythuchi.png`; `no-white` + `iconTile`; dây chuyền sinh icon app 5 nền tảng + bộ đóng
  gói desktop; logo trong app, khối nhà làm TsuDEV, PDF xuất mang logo + chân trang tsudev; đã báo URL logo cho tsudev.
- 20/11/2026 - T7 app + PRO2 phần app (agent-qulythuchi, ADR-0019, phiếu rà soát `20261120-t7-app-pro`): `tsudev_ui`
  v0.2.0 ghim tag; quyền lợi qua `/me/entitlements` kiểm ES256 + JWKS, đệm ≤ 7 ngày; `X-Tsu-Installation`/`X-Tsu-Platform`;
  màn Pro 1 năm + điều khoản 7.5 nguyên văn; kênh `TSU_CHANNEL` (Android mặc định Play, không liên kết web); Play
  Billing `tsudev_pro`/`nam` + `ung_ho_*`; máy chủ `POST /api/v1/me/purchases/play` + `badge` thành viên; 402 theo
  `reason`; nhắc 7.6 (`maybeShowProRenewal`), mốc xoá 30/7 ngày, 7.3; THREAT_MODEL T30-T31. App đủ test (t7 25 ca, gồm
  6 ca 7.6), máy chủ 81 test; PR #36 CI xanh (cả iOS/macOS, ảnh đã xem), gộp `30c08fe`. LÊN PRODUCTION (Worker
  `6f4de037`): `/`, `/app/`, health 200; `purchases/play` 401 khi chưa đăng nhập.

- 20/11/2026 - PRO2 máy chủ (agent-qulythuchi, ADR-0018, phiếu rà soát `20261120-pro2-may-chu`): đồng bộ chuẩn
  v4.0.0 (Pro kỳ 1 năm không tự gia hạn); `purgeLapsedPro` chỉ chọn ứng viên theo đệm rồi hỏi `POST
  /api/rp/entitlements/status` ngay trước khi xoá (đã gia hạn ⇒ giữ + cập nhật hạn; ok quá 90 ngày/deleted ⇒ xoá;
  lỗi/unknown ⇒ hoãn 24 giờ; bỏ luật xoá theo 404 kênh RP); migration 0006 `pro_purge_checks`; máy chủ 76 test. PR #34
  gộp `f772b67`; LÊN PRODUCTION (Worker `434b4cc5`, 0006 áp D1 remote): `/`, `/app/`, health 200; đường Pro 401.

- 20/11/2026 - P7b Tệp đính kèm ảnh hóa đơn E2EE (agent-qulythuchi, ADR-0017, phiếu rà soát
  `20261120-p7b-tep-dinh-kem`): lõi `Attachment` + `AttachmentCipher` (khóa tệp riêng trong bản ghi `attachment` bọc bởi
  khóa ví, ngữ cảnh `attf|ví|giao dịch|tệp`, đệm 64 KiB) + `ImageSanitizer` (bỏ EXIF/GPS/ICC, JPEG ≤ 2000 px ≤ 2 MiB,
  trần 25 MiB/50 triệu điểm ảnh), vector `attachment-file`; máy chủ migration 0005 `wallet_files` + `/wallets/:wid/files/:id`
  (quyền thành viên, Pro chủ ví, hạn mức chung, dọn R2 ví chung); app schema v3 `blobs`, `FileSync`, 402 giữ ảnh cục bộ,
  mục "Ảnh hóa đơn" vi+en, đổi ví mã hóa lại ảnh. Lõi 101, máy chủ 71, app đủ test đạt; PR #32 CI xanh (cả iOS/macOS,
  ảnh chụp đã xem), gộp `aa7fff2`. LÊN PRODUCTION (Worker `f4291be8`, migration 0005 áp D1 remote): `/`, `/app/`, health
  200; đường tệp 401 khi chưa đăng nhập. CHƯA nghiệm thu bằng tài khoản thật (👤).

- 20/11/2026 - AP1 Apple CI (agent-qulythuchi): `.github/workflows/apple.yml` + `scripts/apple-simulator-run.sh` theo mẫu
  lotus-share#80 - iOS release `--no-codesign` ⇒ `.ipa` không ký (artifact 14 ngày), iPhone + iPad 13" giả lập `vi` (còn
  chạy 45 giây, không có `Khởi động thất bại: `, ảnh 2064x2752), macOS release giữ chữ ký ad-hoc của Xcode KÈM
  entitlements (sandbox bật thật, không ký lại `--deep`), kiểm tĩnh Info.plist/entitlements/không `aps-environment`/không
  khai `ITSAppUsesNonExemptEncryption=false`. Thêm `apps/app/ios/Runner/PrivacyInfo.xcprivacy` (UserID + email, không
  theo dõi). Lần chạy đầu xanh cả 2 job (run 44658455602, iOS ~20 phút, macOS ~8 phút); ảnh: iPhone màn chào tiếng
  Việt, macOS mở app (tiếng Anh vì máy chạy đặt en). PR #30 gộp `6394dab`.

- 20/11/2026 - T7 máy chủ Pro (agent-qulythuchi, phiên qulythuchi-28, ADR-0016 ĐÃ CHẤP NHẬN, phiếu rà soát
  `20261120-t7-may-chu-pro`): đồng bộ chuẩn v3.9.1; migration 0004 (đệm quyền lợi ≤ 24 giờ + băm mã cài đặt); kênh RP
  tsudev.com (`private_key_jwt`, kiểm JWS ES256/iss/aud/typ/sub); gate 402 `pro_required` (đẩy, tệp, tạo/mời ví chung,
  email; ví chung theo Pro chủ ví); `GET /api/v1/me/entitlements`; dọn bản mã khi Pro hết > 90 ngày; hạn mức 200 MiB +
  1 GiB; cờ `PRO_ENFORCE` (production `off`). Máy chủ 68 test đạt; PR #27 CI xanh, gộp `adc5e8c`. LÊN PRODUCTION
  (Worker version `cdc9a0d7`, migration 0004 áp D1 remote): `/`, `/app/`, health 200, `/api/v1/me/entitlements` 401
  khi chưa đăng nhập. 👤 đã đặt secret `RP_PRIVATE_JWK` + đăng ký khoá công khai (`kid` `qulythuchi-rp-c5128cae`) ở
  Neon tsudev; agent thử kênh RP thật: assertion đúng ⇒ `404 unknown_subject` cho sub giả, không token ⇒ 401. 👤 thử tài khoản thật: `/me/entitlements` ⇒ `status: ok` + JWS thật (nghiệm thu kênh RP).

- 19/11/2026 - T7 dừng trước khi viết mã (agent-qulythuchi, phiên qulythuchi-b2): T5/T6 ở tsudev chưa có mã, và tsudev
  ADR-0002 bác phương án app tự xác minh Play ⇒ 👤 chọn "phiếu trước, chờ T5". 👤 chốt thêm cho toàn hệ: miễn phí chỉ lưu
  cục bộ, đồng bộ/sao lưu đám mây là Pro, nhắc mỗi 30 ngày khi ≥ 2 thiết bị. Đã viết phiếu gốc
  `~/projects/logs/handover/20261119-PRO1_*` + phiếu con ở 22 repo + ADR-0016 (ĐỀ XUẤT); nhắn tsudev-55, tsucwico-c4,
  lotus-share-1c; tsuscan-56 đã xác nhận nhận phiếu.

- 19/11/2026 - P9 Ví chung gia đình (agent-qulythuchi, ADR-0015, phiếu rà soát `20261119-p9-vi-chung`): lõi
  `WalletSharing` (mã mời UUID + bí mật 32 B, bằng chứng BLAKE2b có khóa, khối chia sẻ `QS 01` = X-Wing + KEK trộn bí
  mật cặp, bọc theo phiên bản `swk|ví|ver`, mã an toàn); máy chủ migration 0003 (không gian bản ghi theo ví, quyền
  chủ/ghi/xem, xoay khóa trong một giao tác, `stale_key`, `shared_wallet`); app (CSDL schema v2, đồng bộ không gian ví,
  chủ ví kiểm bằng chứng trước khi chia khóa, tự xoay khi có người rời, màn Chia sẻ và thành viên + Tham gia ví chung,
  vi+en). Lõi 95, máy chủ 59, app 99 test đạt; PR #23 CI xanh, gộp `cc003d6`. LÊN PRODUCTION (Worker version `1665dbe4`, migration 0003 áp D1 remote): `/`, `/app/`, `/api/v1/health` 200; `/api/v1/wallets`, `/api/v1/invites/:id` 401 khi chưa đăng nhập; web app chứa màn ví chung. CHƯA nghiệm thu bằng hai tài khoản thật (👤).

- 19/11/2026 - P9a Tiện ích tài chính cá nhân (agent-qulythuchi, ADR-0014, phiếu rà soát `20261119-p9a-tien-ich`):
  số dư theo kỳ (chuyển số dư hiển thị, không bút toán), khoản thu nhiều đợt + thuế khấu trừ, thuế TNCN 2020/2026 +
  gross/net + nhắc hạn, QR VietQR/EMVCo (kiểm CRC, mở app ngân hàng qua dl.vietqr.io có đồng ý, tạo mã nhận), 157 tiền
  tệ ISO 4217, nhập theo tệp mẫu CSV/XLSX, ba lối đăng nhập + chế độ khách, máy chủ gửi `idp_hint`. IdP tsudev.com nhận
  `idp_hint` ở tsudev#326 (QT4, phiên tsudev). Lõi 85, app đủ, máy chủ 53 test đạt; PR #21 CI xanh, gộp `adf7374`.
  LÊN PRODUCTION (Worker version `f14986a1`, gồm luôn T3): `/`, `/app/` 200, `/auth/web/start?provider=google` ⇒
  `idp_hint=google`. Dependabot #2 (picomatch, apps/site) là advisory ĐÃ RÚT - không cần xử lý.

- 18/11/2026 - Email Routing (chủ dự án chạy lệnh, agent kiểm): miền con `in.qulythuchi.tsudev.com` bật (MX route1/2/3 +
  SPF đã lan truyền); catch-all của ZONE tsudev.com ⇒ Worker `qulythuchi` (trước đó tắt/drop). Worker từ chối ngay thư
  không thuộc INBOX_DOMAIN nên địa chỉ lạ của tsudev.com vẫn bị trả lại như cũ; 4 quy tắc chuyển tiếp contact@/
  privacy@/abuse@/security@ giữ nguyên. Sản phẩm khác cần catch-all ⇒ phải tách lại (ghi ADR-0012).
- 18/11/2026 - P8 Web + site (agent-qulythuchi): `apps/site` Astro (trang chủ, Tính năng, Bảo mật và quyền riêng tư,
  Tải về, 404, sitemap; đen + tím, bộ chọn giao diện), dây chuyền thương hiệu từ logo tsudev, web app Flutter ở `/app/`
  (`--csp --no-web-resources-cdn`, không service worker, CSP `<meta>`), MỘT Worker phục vụ tĩnh + API (Static Assets),
  `scripts/build-web.sh`, chặn deploy thiếu tệp tĩnh, job CI Website. LÊN PRODUCTION cùng migration 0002 + Email
  Worker của P7; Playwright với production đạt. ADR-0013, phiếu rà soát P8. Đăng nhập thật trên app đạt 18/11 (QT2).
- 18/11/2026 - P7 Tự nhập + thông minh (agent-qulythuchi): lõi `autoimport/` (số tiền tiếng Việt nói/viết, câu ghi
  nhanh, bộ đọc thông báo ngân hàng chung, hóa đơn OCR, gợi ý danh mục học trên máy, trùng/bất thường); app: màn Tự
  nhập + Ghi nhanh (gõ/giọng nói `onDevice`/OCR ML Kit), sao kê CSV/XLSX (dòng tiêu đề, ghi nợ/có, chống trùng, hàng
  chờ), thông báo Android (listener + hàng đợi AES-GCM Keystore), widget Ghi nhanh; máy chủ: email niêm phong
  (migration 0002, `/api/v1/inbox`, Email Worker, tweetnacl + BLAKE2b kiểm với libsodium). ADR-0012, phiếu rà soát P7.
  Tệp đính kèm, PDF, OCR desktop dời lại.
- 18/11/2026 - P6 Đồng bộ trong app (agent-qulythuchi): `apps/app/lib/sync/` (ApiClient bearer + refresh xoay vòng,
  chỉ tin CA gốc ghim, PKCE, vòng lặp 127.0.0.1 / scheme di động / cookie web), `SyncEngine` (khóa ⇒ kéo hợp nhất theo
  trường ⇒ đẩy; chặn trộn khóa chủ, ghim vân tay danh tính, phát hiện quay lui, bỏ bản ghi bị tráo, ràng buộc tài
  khoản tsudev), `SyncController` (tự đồng bộ khi mở khóa/sửa/10 phút/quay lại app), màn "Tài khoản & đồng bộ" (thiết
  bị, thu hồi, dung lượng, xuất, xóa tài khoản, đăng xuất), màn chào "Đăng nhập để lấy dữ liệu đã đồng bộ". 21 test mới
  (máy chủ giả theo hợp đồng P5); 67 test app đạt; build web đạt; TLS ghim với production đạt. Đăng nhập thật CHƯA
  nghiệm thu (hết giờ chờ chủ dự án). ADR-0011, phiếu rà soát P6. Máy chủ không đổi.
- 18/11/2026 - P5 Máy chủ `services/sync-api` (agent-qulythuchi): Workers + Hono + D1 + R2 LÊN PRODUCTION
  `https://qulythuchi.tsudev.com` (Worker `qulythuchi`, D1 `qulythuchi` APAC, R2 `qulythuchi-files` APAC, secret
  SESSION_SECRET/IP_HASH_SALT đã đặt). RP OIDC + mã một lần PKCE cho app, refresh xoay vòng, phiên web cookie,
  đẩy/kéo bản mã theo rev, gói khóa/khóa ví, tệp R2, thiết bị, xuất, xóa tài khoản 30 ngày, giới hạn tần suất/hạn
  mức. 44 test (dữ liệu mẫu THẬT từ lõi), job CI `Máy chủ (services/sync-api)`. ADR-0010, phiếu rà soát P5.
  18/11: client OIDC chèn vào Neon (phiếu tsudev QT1 ĐÓNG); ruleset `main-bao-ve` thêm check Máy chủ.
- 17/11/2026 - P4 Báo cáo + dữ liệu (agent-qulythuchi): báo cáo theo kỳ + so với kỳ trước, thu chi 6 tháng, cơ cấu
  danh mục, tài sản ròng, lịch chi tiêu (mọi biểu đồ có bảng thay thế, màu token), "An toàn để tiêu"; lọc nhiều điều
  kiện + lưu bộ lọc; xuất CSV/XLSX/PDF có cảnh báo, nhập CSV ghép cột, sao lưu/khôi phục `.qtbak` mã hóa (ADR-0009).
  43 test app; Playwright 13 bước P4 đạt 390x844 và 1280x800. Phiếu rà soát P4.
- 17/11/2026 - P3 Nghiệp vụ nâng cao (agent-qulythuchi): ngân sách (kỳ, danh mục/ví, chuyển dư, cảnh báo), 6 hũ,
  mục tiêu, định kỳ (tự ghi/chờ xác nhận), hóa đơn + nhắc (thông báo không lộ nội dung), sổ nợ, sự kiện, tỉ giá nhập
  tay + tổng quy đổi; điều hướng Kế hoạch/Thêm. 28 test; Playwright 19 bước P3 đạt 2 khổ. Phiếu rà soát P3.
- 17/11/2026 - P2 App Flutter khung (agent-qulythuchi): 6 đích, kho khóa (mật khẩu/24 từ/PIN/sinh trắc, tự khóa 60 s,
  FLAG_SECURE), CSDL sqlite3mc (web: WASM + IndexedDB, chỉ bản niêm phong), ví/danh mục 2 tầng/giao dịch/chuyển ví,
  máy tính số tiền, tìm không dấu, token Sáng/Tối, vi+en. 14 test; chạy thật bản web bằng Playwright đạt. Build Linux
  chỉ kiểm trên CI (máy dev thiếu CMake/GTK dev). ADR-0008, phiếu rà soát `docs/security-reviews/20261117-p2-app.md`.
- 17/11/2026 - P1 Lõi `packages/core` (agent-qulythuchi): tiền số nguyên (allocate không mất đồng, quy đổi làm tròn
  chẵn, định dạng/đọc vi+en), ngày lịch, ví/danh mục/giao dịch (chuyển ví = 2 bản ghi)/ngân sách (kỳ, chuyển dư,
  cảnh báo)/định kỳ RRULE/nợ/mục tiêu/sự kiện/6 hũ, HLC + hợp nhất theo trường, phong bì E2EE v1 + phân cấp khóa
  (Argon2id NFKC, 24 từ BIP39, khóa ví, X-Wing chia sẻ, mở email niêm phong). 39 test, độ phủ 95,5%. Vector đối chiếu
  kiểm bằng libsodium 1.0.18 hệ thống (độc lập bản 1.0.22 của Dart): đạt. `docs/THREAT_MODEL.md` (15 kịch bản), ADR-0007.
- 17/11/2026 - P0 Nền móng (agent-qulythuchi): bộ quy ước v3.6.0, `docs/PLAN.md`, `docs/ARCHITECTURE.md`,
  `docs/FEATURES.md`, ADR 0001-0006, LICENSE AGPL-3.0, SECURITY/README/NOTICE/CHANGELOG, CI (quy ước + gitleaks),
  Dependabot. Repo tsudev-org/qulythuchi Public + ruleset `main-bao-ve` + secret scanning/push protection + CodeQL; CI xanh.

## Quyết định quan trọng

- 17/11/2026 - Chủ dự án chốt: repo Public tsudev-org/qulythuchi, E2EE, Android miễn phí + iOS hoãn, 5 cách tự nhập,
  vi+en, ví chung ở phase sau, tên miền qulythuchi.tsudev.com, mã app com.tsudev.qulythuchi (`docs/PLAN.md`).
- 17/11/2026 - Flutter cho mọi đích + lõi Dart + Workers/D1/R2: `docs/adr/0001-*`
- 17/11/2026 - E2EE phân cấp khóa libsodium: `docs/adr/0002-*`
- 17/11/2026 - Đăng nhập qua máy chủ (mẫu sound-db) + ghim chứng chỉ: `docs/adr/0003-*`
- 17/11/2026 - Đồng bộ HLC ghi sau thắng theo trường: `docs/adr/0004-*`
- 17/11/2026 - AGPL-3.0-only: `docs/adr/0005-*`
- 17/11/2026 - 5 cách tự nhập, email là ngoại lệ E2EE có báo trước: `docs/adr/0006-*`
- 17/11/2026 - X-Wing chia sẻ khóa ví, mật khẩu NFKC, Argon2id 64 MiB/3 (sàn 19 MiB/2), phong bì v1: `docs/adr/0007-*`

- 17/11/2026 - sqlite3 3.x + sqlite3mc thay drift/sqlcipher_flutter_libs (EOL); PIN bọc bằng khóa thiết bị: `docs/adr/0008-*`
- 17/11/2026 - Xuất bản rõ có cảnh báo; sao lưu `.qtbak` = gói khóa + phong bì `bak|<id>`, khôi phục chỉ trên máy chưa có tài khoản: `docs/adr/0009-*`
- 18/11/2026 - Máy chủ: không gian bản ghi = tài khoản, rev trong giao tác, tệp xuyên Worker, xóa tài khoản 30 ngày: `docs/adr/0010-*`
- 18/11/2026 - Đồng bộ app: không trộn khóa chủ, gói máy chủ chỉ nhận khi mở được bằng khóa chủ, ghim CA gốc: `docs/adr/0011-*`
- 19/11/2026 - Ví chung: không gian bản ghi theo ví, mã mời có bí mật cặp, thu hồi = xoay khóa: `docs/adr/0015-*`
- 18/11/2026 - Một Worker phục vụ site + web app `/app/` + API, CSP riêng cho app bằng `<meta>`: `docs/adr/0013-*`
- 18/11/2026 - Tự nhập: bộ đọc chung, mọi nguồn vào hàng chờ, hàng đợi thông báo Keystore, email niêm phong tweetnacl: `docs/adr/0012-*`
- 19/11/2026 - Pro (👤 chốt): đồng bộ/sao lưu đám mây, tạo ví chung, hạn mức, xuất PDF/XLSX + báo cáo nâng cao, tự nhập nâng cao; CSV + `.qtbak` vẫn miễn phí: `docs/adr/0016-*` (ĐỀ XUẤT)
- 17/11/2026 - Phiên bản theo phiếu toàn hệ 20261117-V1: `YY.M.DDNN`, thẻ `vYY.M.DDNN`, versionCode `YYMDDNN`

## Sự cố bảo mật

- (chưa có)
