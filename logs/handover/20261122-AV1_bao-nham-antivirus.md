# PHIẾU YÊU CẦU AV1 - Antivirus / báo nhầm (qulythuchi)

- **Mã phiếu**: 20261122-AV1
- **Thời điểm**: 22/11/2026
- **Người gửi**: agent-tsuswico (phiên tsuswico-6e) theo uỷ quyền của chủ dự án
- **Phiếu điều phối**: `~/projects/logs/handover/20261122-AV1_bao-nham-antivirus-toan-he.md` (bảng kết quả cả hệ + thư soạn sẵn từng hãng)
- **Chuẩn**: `.standards/docs/DISTRIBUTION_TRUST.md` mục 3, 3.1
- **Trạng thái**: MỞ

## 1. Hiện trạng 22/11/2026

Repo chưa phát hành tệp nhị phân trên GitHub Release (không có tệp để quét). Tên miền chung tsudev.com + swico./files./sound. sạch trên VirusTotal.

## 2. Việc cần làm (phòng ngừa)

1. Khi bắt đầu phát hành tệp chạy được (exe/msi/apk/dmg/AppImage/zip): Release NHÁP + job VirusTotal dùng chung (`tsudev-org/.github/.github/workflows/virustotal.yml`); sạch mới công bố; cờ ⇒ ghi `docs/store/antivirus.md` + nộp ≤ 48 giờ theo phiếu điều phối.
2. Repo có website riêng: kiểm tên miền trên VirusTotal (`/api/v3/domains/<tên miền>`) và Google Safe Browsing; bị gắn cờ ⇒ báo theo `DISTRIBUTION_TRUST.md` mục 3.
3. Không có việc khác ⇒ ghi kết quả kiểm vào phiếu rồi ĐÓNG.

## 3. Kết quả (agent-qulythuchi, phiên qulythuchi-1f, 22/11/2026)

1. ĐÃ CÓ: `.github/workflows/release.yml` (PR #54) tạo Release NHÁP ⇒ job `virustotal` dùng mẫu chung
   `tsudev-org/.github/.github/workflows/virustotal.yml` (secret org `VT_API_KEY`) ⇒ không engine gắn cờ mới công bố.
   Bị gắn cờ ⇒ Release giữ nháp, ghi `docs/store/antivirus.md` + nộp theo phiếu điều phối mục 2.
2. Tên miền `qulythuchi.tsudev.com`, `in.qulythuchi.tsudev.com`: job `ten-mien` trong `.github/workflows/dast.yml`
   hỏi VirusTotal API v3 hằng tuần (thứ Tư), đỏ khi có hãng gắn cờ. Google Safe Browsing: theo dõi qua Google Search
   Console của tsudev.com (👤, DISTRIBUTION_TRUST mục 1.5).
