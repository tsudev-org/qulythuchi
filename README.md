# Quly Thu Chi

Quản lý thu chi cá nhân và gia đình - **mã hóa đầu-cuối, dùng được khi mất mạng, đồng bộ mọi thiết bị** cùng tài
khoản TsuDEV. Android, iOS, Windows, macOS, Linux và web tại <https://qulythuchi.tsudev.com>.

> Trạng thái: web app chạy tại <https://qulythuchi.tsudev.com/app/>; bản cài đặt (Android, iOS, desktop) chưa phát hành
> (phase P10). Kế hoạch: [`docs/PLAN.md`](docs/PLAN.md). Mỗi lần triển khai production có thẻ `deploy-YYYY.MM.DD.N`
> kèm ghi chú thay đổi: <https://github.com/tsudev-org/qulythuchi/tags>.

## Điểm chính

- Nhiều ví, danh mục, chuyển ví, đa tiền tệ; ngân sách, phong bì, 6 hũ; định kỳ, hóa đơn, nợ/vay, mục tiêu, sự kiện.
- Báo cáo, lịch chi tiêu, "an toàn để tiêu"; xuất/nhập CSV, XLSX, PDF.
- Tự nhập từ thông báo ngân hàng (Android), sao kê, ảnh hóa đơn, giọng nói, email chuyển tiếp.
- Máy chủ **không đọc được** dữ liệu của bạn - xem [`SECURITY.md`](SECURITY.md).

Tính năng đầy đủ: [`docs/FEATURES.md`](docs/FEATURES.md). Kiến trúc: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Build và kiểm thử

Lệnh chạy và yêu cầu khi gửi pull request: [`CONTRIBUTING.md`](CONTRIBUTING.md). Báo lỗi / đề xuất:
[GitHub Issues](https://github.com/tsudev-org/qulythuchi/issues/new/choose). Báo lỗ hổng: [`SECURITY.md`](SECURITY.md).

## English summary

Quly Thu Chi is a personal and family finance tracker: **end-to-end encrypted, offline-first, synced across your
devices** with a TsuDEV account. Multiple wallets and currencies, budgets, recurring bills, debts, goals, reports,
CSV/XLSX import and export, receipt photos, shared family wallets. The sync server only ever stores ciphertext
(libsodium; see [`SECURITY.md`](SECURITY.md)). Flutter app for Android, iOS, Windows, macOS, Linux and the web, plus a
Cloudflare Workers sync server. Status: the web app is live at <https://qulythuchi.tsudev.com/app/>; installable
releases are not published yet. Build, test and contribution rules: [`CONTRIBUTING.md`](CONTRIBUTING.md). Bugs and
feature requests: [GitHub Issues](https://github.com/tsudev-org/qulythuchi/issues) (English or Vietnamese).
Licence: AGPL-3.0-only.

## Giấy phép

[AGPL-3.0-only](LICENSE). Tên và logo: xem [`NOTICE`](NOTICE).
