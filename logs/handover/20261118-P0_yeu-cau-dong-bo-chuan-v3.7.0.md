# PHIẾU YÊU CẦU - P0 phiếu toàn hệ 20261117-P2: đồng bộ bộ quy ước lên v3.7.0

- **Mã phiếu**: 20261118-P0
- **Từ**: phiên điều phối `~/projects` (projects-7e), 18/11/2026
- **Đến**: phiên kế tiếp của repo `qulythuchi` (repo đang có phiên khác làm việc nên phiên điều phối KHÔNG sửa hộ)
- **Trạng thái**: ĐÓNG (18/11/2026, agent-qulythuchi)

## Việc (một PR nhỏ, merge khi CI xanh)

1. `./scripts/sync-standards.sh --ref v3.7.0` (bản MINOR - không cần sửa code; thêm `docs/DISTRIBUTION_TRUST.md`,
   `docs/VERSIONING.md` v3, cổng kiểm 5b chỉ LƯU Ý). Hoặc chạy nguyên script cơ học
   `~/projects/logs/tools/p0-sync-standards.sh ~/projects/qulythuchi "hàng 10 (`qulythuchi`)"` (làm trên worktree riêng, tự mở PR).
2. Cùng PR: thêm vào đầu `logs/STATE.md` khối "Phiên kế tiếp: đọc
   `~/projects/logs/handover/20261117-P2_ke-hoach-phan-phoi-tin-cay-da-nen-tang.md` hàng 10 (`qulythuchi`) ở mục 3 +
   `.standards/docs/DISTRIBUTION_TRUST.md`".
3. Ghi "Đã đọc" phiếu V1 (`logs/handover/20261117-V1_*` mục 6 bản sao trong repo này).
4. Xong: ghi một dòng vào mục 8 phiếu `~/projects/logs/handover/20261117-P2_*` (số PR) và ĐÓNG phiếu này.

Mẫu đã làm ở 13 repo khác: ví dụ tsudev-org/sound-db#12, tsudev-org/tsucontact#32.

## Kết quả xử lý (agent-qulythuchi, 18/11/2026)

- Bước 1-2: chạy `p0-sync-standards.sh` trên worktree riêng: `.standards` v3.7.0 (ref chuyển từ `main` sang nhãn
  `v3.7.0`), khối "Phiên kế tiếp" đầu `logs/STATE.md`; `check-standards.sh` đạt.
- Bước 3: phiếu V1 mục 6 đã có "Đã đọc" từ 17/11/2026 - không cần ghi thêm.
- Bước 4: số PR ghi ở mục 8 phiếu P2.
