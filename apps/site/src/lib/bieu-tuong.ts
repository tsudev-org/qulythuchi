// Biểu tượng thẻ (DESIGN_SYSTEM.md mục 5 v6.0.0): nét mảnh 1.5px kiểu Lucide, 24x24. Phần có lớp `bt-dong` là phần
// chuyển động khi rê/focus thẻ (chỉ transform), kiểu chuyển động theo `chuyenDong` (site.css `[data-chuyen-dong]`):
//   nang  - phần động nhấc lên (khoá mở, điện thoại nhấc)    vao  - mũi tên đi vào khay (nhập dữ liệu)
//   moc   - cột mọc lên từ đáy (báo cáo)                     nghieng - nghiêng bút/ngoặc (ghi, mã)
//   nhip  - phóng nhẹ một nhịp (đích, khiên)
type ChuyenDong = 'nang' | 'vao' | 'moc' | 'nghieng' | 'nhip';
export interface BieuTuong { duong: string; chuyenDong: ChuyenDong }

export const BIEU_TUONG = {
  khoa: { chuyenDong: 'nang', duong: '<rect x="4.5" y="11" width="15" height="10" rx="2"/><path class="bt-dong" d="M8 11V7.5a4 4 0 0 1 8 0V11"/><path d="M12 15v2"/>' },
  but: { chuyenDong: 'nghieng', duong: '<g class="bt-dong"><path d="M4 20h4L19 9l-4-4L4 16v4Z"/><path d="M13.5 6.5l4 4"/></g>' },
  nhap: { chuyenDong: 'vao', duong: '<path class="bt-dong" d="M12 3v11M7.5 9.5 12 14l4.5-4.5"/><path d="M4 15v4a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-4"/>' },
  dich: { chuyenDong: 'nhip', duong: '<g class="bt-dong"><circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="0.8"/></g>' },
  cot: { chuyenDong: 'moc', duong: '<path d="M4 20h16"/><path class="bt-dong" d="M7 17v-4M12 17V8M17 17V5"/>' },
  dienThoai: { chuyenDong: 'nang', duong: '<g class="bt-dong"><rect x="7" y="2.5" width="10" height="19" rx="2"/><path d="M11 18.5h2"/></g>' },
  khongTheoDoi: { chuyenDong: 'nhip', duong: '<path d="M3 3l18 18"/><g class="bt-dong"><path d="M10.6 5.1A10 10 0 0 1 12 5c6 0 9.5 7 9.5 7a17 17 0 0 1-3 3.8M6.6 6.6A17 17 0 0 0 2.5 12S6 19 12 19a9.6 9.6 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/></g>' },
  ma: { chuyenDong: 'nghieng', duong: '<g class="bt-dong"><path d="M8 7l-5 5 5 5M16 7l5 5-5 5"/></g><path d="M13.5 5l-3 14"/>' },
  khien: { chuyenDong: 'nhip', duong: '<g class="bt-dong"><path d="M12 3l7.5 3v5.5c0 4.4-3.2 8.3-7.5 9.5-4.3-1.2-7.5-5.1-7.5-9.5V6L12 3Z"/><path d="M9 12l2 2 4-4"/></g>' },
} satisfies Record<string, BieuTuong>;
