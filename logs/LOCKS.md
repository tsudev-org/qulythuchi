# LOCKS.md - File đang bị khóa

> KIỂM TRA FILE NÀY TRƯỚC KHI SỬA BẤT KỲ FILE NÀO.
> Định dạng: `<đường dẫn> | <agent hoặc nhiệm vụ> | <HH:mm DD/MM/YYYY>`
> Sửa xong file thì XÓA NGAY dòng khóa của mình, không đợi cuối phiên.
> File đang bị người khác khóa: TUYỆT ĐỐI không sửa - gửi phiếu bàn giao thay thế.

services/sync-api/src/pro/entitlements.ts | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
services/sync-api/src/maintenance.ts | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
services/sync-api/test/pro.test.ts | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
services/sync-api/test/helpers.ts | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
services/sync-api/migrations/0006_* | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
services/sync-api/wrangler*.jsonc, src/env.ts | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
docs/adr/0018-* | agent-qulythuchi PRO2 máy chủ | 12:29 20/11/2026
