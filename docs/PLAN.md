# KẾ HOẠCH TỔNG - Quly Thu Chi

> Mỗi phase = **một phiên làm việc**. Cuối phase: cập nhật `logs/STATE.md`, viết phiếu `logs/handover/`,
> nhả khóa `logs/LOCKS.md`, dừng mọi Monitor/tiến trình nền, cây làm việc sạch, rồi đóng phiên.
> Phiên mới mở bằng khối lệnh ở `.standards/docs/AGENT_PROTOCOL.md` mục 2.

## Mục tiêu

App quản lý thu chi **local-first, mã hóa đầu-cuối (E2EE)**, chạy trên Android, iOS, Windows, macOS, Linux và
web (`https://qulythuchi.tsudev.com`), đồng bộ giữa các thiết bị cùng tài khoản tsudev. Chi phí vận hành 0 đồng.

## Ràng buộc đã chốt với chủ dự án (17/11/2026)

| Mục | Quyết định |
| --- | --- |
| Repo | `tsudev-org/qulythuchi`, Public |
| Bảo vệ dữ liệu | E2EE - máy chủ chỉ giữ bản mã (ADR-0002) |
| Phát hành di động | Android miễn phí (GitHub Releases, sau đó F-Droid); iOS viết sẵn mã, chờ tài khoản Apple; iPhone tạm dùng PWA |
| Tự nhập giao dịch | Thông báo ngân hàng (Android), file sao kê, OCR hóa đơn, giọng nói, email chuyển tiếp (ADR-0006) |
| Ngôn ngữ | Tiếng Việt (mặc định) + tiếng Anh |
| Ví chung gia đình | Có, ở phase sau; khóa theo từng ví thiết kế từ đầu |
| Giấy phép | AGPL-3.0 (ADR-0005) |
| Tên miền / mã app | `qulythuchi.tsudev.com` / `com.tsudev.qulythuchi` |
| Phân loại dữ liệu | **D3** (tài chính) ⇒ rà soát bảo mật bắt buộc, ghim chứng chỉ |

## Các phase

| # | Phase | Kết quả nghiệm thu |
| --- | --- | --- |
| P0 | Nền móng | Bộ quy ước, tài liệu kiến trúc, ADR 0001-0006, ma trận tính năng, repo GitHub + bảo vệ nhánh + CI khung |
| P1 | Lõi `packages/core` (Dart thuần) | Mô hình miền, tiền tệ số nguyên, phong bì mã hóa + phân cấp khóa, HLC, vector đối chiếu, test ≥ 90% nhánh lõi |
| P2 | App Flutter khung | 6 đích build; drift + SQLCipher; i18n vi/en; token thiết kế; khóa app sinh trắc/PIN; ví, danh mục, giao dịch, chuyển ví |
| P3 | Nghiệp vụ nâng cao | Ngân sách (danh mục/phong bì/6 hũ), giao dịch định kỳ, hóa đơn + nhắc, sổ nợ/vay, mục tiêu tiết kiệm, sự kiện/chuyến đi, đa tiền tệ |
| P4 | Báo cáo + dữ liệu | Biểu đồ, dòng tiền, lịch chi tiêu, "an toàn để tiêu", tìm kiếm không dấu, xuất/nhập CSV/XLSX/PDF, sao lưu tệp mã hóa |
| P5 | Máy chủ `services/sync-api` | Workers + D1 + R2: RP OIDC tsudev, token app, thiết bị, API đồng bộ bản mã, tệp đính kèm, giới hạn tần suất, header bảo mật; triển khai production |
| P6 | Đồng bộ trong app | Đăng nhập, thiết lập mật khẩu mã hóa + khóa khôi phục 24 từ, đồng bộ nền, quản lý/thu hồi thiết bị, ghim chứng chỉ |
| P7 | Tự nhập + thông minh | Bộ đọc thông báo ngân hàng VN, bộ phân tích sao kê, OCR trên máy, giọng nói tiếng Việt, email chuyển tiếp niêm phong, tự xếp danh mục, widget |
| P8 | Web + site | Flutter web (PWA) tại `/app`, trang giới thiệu Astro, tải về, chính sách riêng tư; thẻ ở tsudev.com/apps |
| P9 | Ví chung gia đình | Khóa danh tính X25519, mời/nhận thành viên, phân quyền xem/ghi, thu hồi + xoay khóa ví |
| P10 | Phát hành + kiểm định | Release ký, SBOM, chứng thực nguồn gốc; APK, MSIX/zip, dmg, deb/rpm/AppImage; Scoop/brew/APT/winget; rà soát mối đe dọa, quét DAST (ZAP), kiểm thử khôi phục |

Thứ tự phụ thuộc: P0 → P1 → P2 → (P3, P4) → P5 → P6 → (P7, P8) → P9 → P10. P3/P4 và P7/P8 có thể song song theo
ranh giới file ở `AGENTS.md` B.3.

## Việc cần chủ dự án (không tự làm được)

- Đăng ký client OIDC `qulythuchi` ở tsudev.com, redirect `https://qulythuchi.tsudev.com/auth/callback` (P5).
- Token Cloudflare (Workers, D1, R2, Email Routing, DNS cho `qulythuchi.tsudev.com`) đặt ở thư mục ngoài repo; thu hồi sau khi xong.
- Khóa ký Android (giữ ngoại tuyến) → secret Environment `release` (P10).
- Duyệt logo riêng (`BRAND_ASSETS.md` mục 15) - tạm dùng logo tsudev.
