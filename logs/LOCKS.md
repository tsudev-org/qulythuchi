# LOCKS.md - File đang bị khóa

> KIỂM TRA FILE NÀY TRƯỚC KHI SỬA BẤT KỲ FILE NÀO.
> Định dạng: `<đường dẫn> | <agent hoặc nhiệm vụ> | <HH:mm DD/MM/YYYY>`
> Sửa xong file thì XÓA NGAY dòng khóa của mình, không đợi cuối phiên.
> File đang bị người khác khóa: TUYỆT ĐỐI không sửa - gửi phiếu bàn giao thay thế.

apps/app/** | agent-qulythuchi / P6 đồng bộ trong app | 01:43 18/11/2026
services/sync-api/** | agent-qulythuchi / P6 (chỉ nếu cần đổi máy chủ) | 01:43 18/11/2026
docs/** | agent-qulythuchi / P6 (ADR, rà soát, THREAT_MODEL) | 01:43 18/11/2026
