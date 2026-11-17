# STATE.md - Trạng thái project Quly Thu Chi

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`. Kế hoạch tổng: `docs/PLAN.md`.

## Hàng đợi task (làm từ trên xuống)

- [ ] **P2 - App Flutter khung** (phiếu `logs/handover/20261117-02_p1-xong-bat-dau-p2.md`)
- [ ] P3 - Nghiệp vụ nâng cao
- [ ] P4 - Báo cáo + dữ liệu
- [ ] P5 - Máy chủ `services/sync-api` (cần 👤 client OIDC + token Cloudflare)
- [ ] P6 - Đồng bộ trong app
- [ ] P7 - Tự nhập + thông minh
- [ ] P8 - Web + site
- [ ] P9 - Ví chung gia đình
- [ ] P10 - Phát hành + kiểm định (cần 👤 khóa ký Android)

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

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

## Sự cố bảo mật

- (chưa có)
