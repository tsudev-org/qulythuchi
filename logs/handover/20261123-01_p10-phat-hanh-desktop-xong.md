# PHIẾU BÀN GIAO 20261123-01 - P10 phát hành desktop + kiểm định xong, còn Android/kênh gói

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-1f`), 23/11/2026
- **Trạng thái**: MỞ (phần còn lại ở mục 3)

## 1. Đã xong

- Dây chuyền phát hành `.github/workflows/release.yml` + `docs/RELEASE.md` (cắt bản, tệp, cách kiểm, bí mật).
- Release đầu tiên `v26.11.2301-beta.1` (Pre-release): Windows zip, macOS zip, Linux deb + tar.gz, SBOM, SHA256SUMS
  ký Sigstore, bundle chứng thực; VirusTotal 0/74 cả 4 tệp; kiểm `sha256sum -c` + `gh attestation verify` đạt.
- DAST `.github/workflows/dast.yml`: ZAP baseline 0 FAIL sau khi thêm COEP và ghi lý do 7 cảnh báo ở `.zap/rules.tsv`;
  VirusTotal tên miền sạch. Production `deploy-2026.11.23.1`; trang `/tai-ve/` dẫn bản thử nghiệm.

## 2. Bẫy đã gặp

- MSVC 14.52 (windows-2025, VS 18) coi `<experimental/coroutine>` của `local_auth_windows` là lỗi STL1011 ⇒
  `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` trong `apps/app/windows/CMakeLists.txt`.
- Windows FileVersion: build-number phải là `0` (versionCode `YYMDDNN` tràn 16 bit); chuỗi FileVersion sửa ở
  `windows/runner/CMakeLists.txt`.
- Thẻ đã đẩy không xoá: `v26.11.2201-beta.1` không có Release.

## 3. Còn lại

1. 👤 `scripts/android-keys.sh` (tạo khoá APK + upload, nạp secret Environment `release`, in vân tay SHA-256) ⇒ báo
   agent; agent ghi vân tay vào `docs/RELEASE.md` mục 4, bật Required reviewers cho Environment `release` nếu 👤 đồng
   ý, cắt thẻ mới ⇒ APK lên Release, AAB (artifact `play-aab`) nộp Thử nghiệm nội bộ Play (GP1 bước 4: sản phẩm
   `tsudev_pro`/`nam`, `ung_ho_*`).
2. Kênh gói (`.standards/docs/PACKAGING.md`): MSIX + Microsoft Store (👤 tài khoản), winget, Scoop bucket, Homebrew tap
   (cask, macOS ad-hoc), kho APT/RPM `pkg.tsudev.com` - kiểm phiếu/hạ tầng chung ở repo tsudev trước khi làm.
3. Bản chính thức (bỏ `-beta`) sau khi 👤 nghiệm thu P9 (hai tài khoản) + P7b trên production.
4. Dời từ P7: sao kê PDF, OCR desktop, widget/lối tắt iOS.
