# LOCKS.md - File đang bị khóa

> KIỂM TRA FILE NÀY TRƯỚC KHI SỬA BẤT KỲ FILE NÀO.
> Định dạng: `<đường dẫn> | <agent hoặc nhiệm vụ> | <HH:mm DD/MM/YYYY>`
> Sửa xong file thì XÓA NGAY dòng khóa của mình, không đợi cuối phiên.
> File đang bị người khác khóa: TUYỆT ĐỐI không sửa - gửi phiếu bàn giao thay thế.

apps/site/** | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
assets/brand/** | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
apps/app/web/** | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
services/sync-api/** (định tuyến tĩnh, wrangler) | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
.github/workflows/ci.yml | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
docs/security-reviews/20261118-p8-web-site.md | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
CHANGELOG.md | agent-qulythuchi / P8 web + site | 19:55 18/11/2026
