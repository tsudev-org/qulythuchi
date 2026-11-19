# STATE.md - Trạng thái project Quly Thu Chi

> **Phiên kế tiếp (phiếu toàn hệ 20261117-P2):** đọc `~/projects/logs/handover/20261117-P2_ke-hoach-phan-phoi-tin-cay-da-nen-tang.md` hàng 10 (`qulythuchi`) ở mục 3,
> rồi `.standards/docs/DISTRIBUTION_TRUST.md` (chuẩn v3.7.0) và `.standards/docs/VERSIONING.md` mục 2. Khuôn thẻ/tên tệp mới
> chỉ áp cho bản phát hành KẾ TIẾP, đọc mục 2.4 (updater đã cài) trước khi đổi.

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`. Kế hoạch tổng: `docs/PLAN.md`.

## Hàng đợi task (làm từ trên xuống)

- [ ] **P9 - Ví chung gia đình** (phiếu `logs/handover/20261118-04_p8-xong-bat-dau-p9.md`, prompt ở mục 6b).
  👤: thử đăng nhập trên `/app/` production; gửi thử một thư tới địa chỉ chuyển tiếp thật (bật trong app).
- [ ] Dời từ P7 (chưa giao phase): tệp đính kèm ảnh hóa đơn mã hóa (`PUT /files` + đồng bộ tệp), sao kê PDF, OCR
  desktop (Tesseract), widget/lối tắt iOS.
- [ ] Thẻ tsudev.com/apps: phiếu `~/projects/tsudev/logs/handover/20261118-QT3_*` (phiên tsudev làm).
- [ ] T7 toàn hệ (`~/projects/logs/handover/20261119-01_*` hàng T7): Pro tháng/năm + Ủng hộ + huy hiệu (PRODUCT_POLICY 3.3).
- [ ] AP1 toàn hệ (`~/projects/logs/handover/20261119-AP1_*`): workflow `apple.yml` iOS/macOS cho `apps/app`.
- [ ] Đề xuất "Đăng nhập với Apple" chờ tsudev-standards duyệt (`tsudev-standards/logs/handover/20261119-01_*`).
- [ ] P10 - Phát hành + kiểm định (cần 👤 khóa ký Android); sinh icon app gốc từ dây chuyền thương hiệu (hiện chỉ web)

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

- 19/11/2026 - P9a Tiện ích tài chính cá nhân (agent-qulythuchi, ADR-0014, phiếu rà soát `20261119-p9a-tien-ich`):
  số dư theo kỳ (chuyển số dư hiển thị, không bút toán), khoản thu nhiều đợt + thuế khấu trừ, thuế TNCN 2020/2026 +
  gross/net + nhắc hạn, QR VietQR/EMVCo (kiểm CRC, mở app ngân hàng qua dl.vietqr.io có đồng ý, tạo mã nhận), 157 tiền
  tệ ISO 4217, nhập theo tệp mẫu CSV/XLSX, ba lối đăng nhập + chế độ khách, máy chủ gửi `idp_hint`. IdP tsudev.com nhận
  `idp_hint` ở tsudev#326 (QT4, phiên tsudev). Lõi 85, app đủ, máy chủ 53 test đạt. Deploy web chạy từ main sau khi gộp
  (gồm luôn T3).

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
- 18/11/2026 - Một Worker phục vụ site + web app `/app/` + API, CSP riêng cho app bằng `<meta>`: `docs/adr/0013-*`
- 18/11/2026 - Tự nhập: bộ đọc chung, mọi nguồn vào hàng chờ, hàng đợi thông báo Keystore, email niêm phong tweetnacl: `docs/adr/0012-*`
- 17/11/2026 - Phiên bản theo phiếu toàn hệ 20261117-V1: `YY.M.DDNN`, thẻ `vYY.M.DDNN`, versionCode `YYMDDNN`

## Sự cố bảo mật

- (chưa có)
