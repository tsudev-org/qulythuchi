# 20261120-04 - PRO2 máy chủ xong: xoá bản mã vì hết Pro có xác minh

- **Người lập**: agent-qulythuchi, 20/11/2026
- **PR**: #34 (gộp `f772b67`); chuẩn v4.0.0; Worker production `434b4cc5`, migration 0006 đã áp D1 remote
- **Quyết định**: `docs/adr/0018-pro-ky-1-nam-xoa-co-xac-minh.md` (thay một phần ADR-0016); phiếu rà soát
  `docs/security-reviews/20261120-pro2-may-chu.md`

## 1. Đã làm

- Bộ quy ước **v4.0.0** (PRODUCT_POLICY v1.2.0: Pro 490.000 ₫/1 năm, không tự gia hạn; mục 7.4 kênh trạng thái; 7.6 nhắc).
- `services/sync-api`: `fetchSubjectStatus` (`src/pro/entitlements.ts`) gọi `POST ENTITLEMENTS_STATUS_URL` với client
  assertion `aud` = URL kênh; `purgeLapsedPro` (`src/maintenance.ts`) chỉ chọn ứng viên theo `pro_until` đệm, rồi hỏi kênh
  trạng thái NGAY TRƯỚC khi xoá: đã gia hạn ⇒ giữ + cập nhật hạn; `ok` quá 90 ngày / `deleted` ⇒ xoá
  (`audit_log.detail = verified:<trạng thái>`); `unknown_subject`/lỗi/hết giờ/khung sai/chưa cấu hình ⇒ hoãn, hỏi lại
  sau ≥ 24 giờ (bảng `pro_purge_checks`, migration 0006). Bỏ luật cũ xoá theo `404` kênh RP.
- Máy chủ KHÔNG nhận JWS từ app ⇒ luật `iat` ≤ 24 giờ / `401 stale` chưa áp dụng (ADR-0018 mục 2.8).
- Production: `/`, `/app/`, `/api/v1/health` 200; `/api/v1/me/entitlements`, `/api/v1/sync/push` 401 khi chưa đăng nhập.

## 2. Việc kế tiếp / lưu ý

1. **Phần APP của PRO2 + app T7** (một phase): `tsudev_ui` **v0.2.0 ĐÃ PHÁT HÀNH** (tin phiên điều phối projects-28,
   20/11/2026) - git dependency ghim `ref: v0.2.0`. Đọc README + CHANGELOG của `tsudev-org/tsudev-ui-flutter`:
   - Nhắc gia hạn 7.6: MỘT `ProRenewalController(store:)` cho cả tiến trình, nối
     `AppLifecycleListener(onStateChange: c.handleAppLifecycleState)`, gọi `maybeShowProRenewal(context, controller:,
     state:, onRenew:, hasCloudSync: true)` mỗi lần mở/quay lại sau khi làm mới quyền lợi. `onRenew`: bản Play ⇒ IAP
     `tsudev_pro`/`nam`; ngoài cửa hàng ⇒ `proWebUrl(clientId)`; bản Play `MUST NOT` dẫn ra web. Đủ 6 test 7.6.
   - Màn mua chỉ "1 năm", điều khoản nguyên văn 7.5 (vi/en) đứng trước nút mua, test so nguyên văn với
     `.standards/docs/PRODUCT_POLICY.md`; gỡ mọi `thang`/"tự gia hạn". Ủng hộ giữ nguyên.
   - App qulythuchi lấy quyền lợi QUA máy chủ (`GET /api/v1/me/entitlements`), không gửi JWS lên máy chủ ⇒
     `jwsForServer`/`sendWithServerJws`/DPoP của `tsudev_ui` chưa cần (chỉ cần nếu đổi thiết kế, kèm ADR mới).
   - 402 `reason`: `no_pro` ⇒ màn Pro; `reauth` ⇒ mời đăng nhập lại; `owner_no_pro` ⇒ báo chủ ví chưa Pro (FileSync
     hiện coi mọi 402 là blocked).
   - Đụng `apps/app` ⇒ có job Apple; chờ xanh và xem ảnh chụp. Ảnh nhắc gia hạn vi/en Sáng/Tối đính vào PR (phiếu PRO2 mục 3).
2. Kênh trạng thái tsudev.com chưa lên (`POST` trả 405, 20/11/2026) - phiên tsudev làm theo phiếu mẹ
   `~/projects/logs/handover/20261120-PRO2_*`. Không cần sửa gì ở đây khi kênh lên.
3. Tệp lạ `logo-qulythuchi.png` ở gốc repo (chưa commit, không phải của phiên này) - chủ dự án quyết định (logo riêng ⇒
   `BRAND_ASSETS.md` mục 15, thay `assets/brand/source/`).

## 2b. Việc cần chủ dự án (👤)

- [ ] (Play Console, khi tạo sản phẩm) `tsudev_pro` chỉ có gói cơ sở **trả trước** `nam` (P1Y); không tạo `thang`.
- [ ] Bật `PRO_ENFORCE=on` chỉ khi: khoá RP đã đăng ký ở tsudev, secret `RP_PRIVATE_JWK` đã đặt, app có màn Pro, đồng ý
  xoá dữ liệu thử nghiệm; nên chờ kênh trạng thái tsudev.com trả 200 (nếu chưa, máy chủ chỉ hoãn, không xoá).
- [ ] (còn từ trước) nghiệm thu P7b, P9 bằng tài khoản thật.

## 3. File liên quan / đang khóa

| Đường dẫn | Lý do | Còn khóa? |
| --- | --- | --- |
| (không) | | Không |

## 4. Rủi ro đã biết

- Kênh trạng thái chưa lên ⇒ nếu bật `PRO_ENFORCE=on`, bản mã người hết Pro nằm quá 90 ngày (cố ý: hoãn thay vì xoá nhầm).
- Tài khoản tsudev đã xoá (`deleted`): chỉ dọn dữ liệu Pro; dòng `users` còn lại.

## 6b. PROMPT CHUẨN CHO PHIÊN SAU

```text
Bạn là agent-qulythuchi, repo ~/projects/qulythuchi (GitHub tsudev-org/qulythuchi). Việc của phiên: APP T7 + PRO2 phần
APP (apps/app) - màn Pro chỉ gói 1 năm + điều khoản 7.5 nguyên văn, Ủng hộ, huy hiệu, xử lý 402 reason
(no_pro/reauth/owner_no_pro), nhắc gia hạn 7 ngày + báo hết kỳ theo PRODUCT_POLICY 7.6 bằng tsudev_ui v0.2.0.

1. KHỞI ĐỘNG - chỉ đọc đúng các tệp này, không quét cả repo:
   AGENTS.md → logs/STATE.md ("Hàng đợi task" + "Đang thực hiện") → logs/LOCKS.md →
   logs/handover/20261120-04_pro2-may-chu-xong.md (mục 2, 2b) →
   logs/handover/20261120-PRO2_pro-ky-1-nam-nhac-gia-han-xoa-co-xac-minh.md (mục 2.1, 2.2, 3) →
   logs/handover/20261120-01_t7-may-chu-xong.md → ADR-0016 (mục 2-4) + ADR-0018 →
   .standards/docs/PRODUCT_POLICY.md mục 3.3, 7.5, 7.6, 8 (nguyên văn vi/en).
   README + CHANGELOG của tsudev-org/tsudev-ui-flutter tại tag v0.2.0 (gh api, chỉ đọc).
   Chạy: git status; git log --oneline -3; gh api user -q .login; ./scripts/check-standards.sh; cat .standards-version
   (cần >= v4.0.0). Cây làm việc có thay đổi chưa commit ⇒ việc dở: đọc diff, làm tiếp, KHÔNG xoá
   (riêng logo-qulythuchi.png ở gốc: của chủ dự án, không đụng).
2. NHẬN VIỆC: nhánh feat/t7-app-pro từ origin/main; khóa LOCKS + "Đang thực hiện" ở STATE trong commit
   "chore(logs): nhận T7 app Pro, khóa file", đẩy ngay.
3. THIẾT KẾ: ADR mới (ADR đã chấp nhận chỉ thay bằng ADR mới) nếu lệch ADR-0016/0018; phiếu rà soát
   docs/security-reviews/<ngày>-t7-app-pro.md (đụng IAP + quyền lợi). Dùng ProRenewalController/maybeShowProRenewal của
   tsudev_ui - KHÔNG tự viết lại; bản Play MUST NOT dẫn ra web; đủ 6 test 7.6 + test so nguyên văn 7.5.
   Chuỗi mới vi+en trong lib/l10n/*.arb rồi flutter gen-l10n. Tiền là số nguyên.
4. TIẾT KIỆM: chỉ chạy test liên quan (flutter test <tệp>, dart test lõi khi đụng); không đọc lại tệp lớn; chờ CI bằng
   lệnh nền (gh run watch); lỗi thì chỉ đọc gh run view --log-failed. PR đụng apps/app ⇒ chờ job Apple xanh, xem ảnh chụp.
5. CỔNG TRƯỚC PR: export PATH="$HOME/tools/flutter/bin:$PATH"; (cd apps/app && flutter analyze && flutter test);
   dart format; ./scripts/check-standards.sh. Ảnh nhắc gia hạn vi/en Sáng/Tối trong PR.
6. KẾT THÚC: PR vào main ⇒ CI xanh ⇒ squash-merge ⇒ ./scripts/build-web.sh && (cd services/sync-api && npm run deploy)
   ⇒ thử nhanh production (/, /app/, /api/v1/health 200) ⇒ ghi một dòng vào mục 5 của phiếu PRO2 ⇒ CHANGELOG, STATE,
   nhả khóa, phiếu bàn giao mới kèm prompt chuẩn (PR chore(logs)). Báo cáo ngắn: làm gì, kiểm gì, việc cần chủ dự án.
7. Repo khác có phiên đang làm (ListAgents): KHÔNG sửa hộ, viết phiếu + SendMessage. Cần đổi gì ở tsudev.com hoặc
   tsudev_ui ⇒ phiếu.
```

## 7. Kết quả xử lý (agent nhận điền sau khi thực hiện)

-
