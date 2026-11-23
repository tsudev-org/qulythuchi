# Phát hành app cài đặt - Quly Thu Chi

Web app, website và máy chủ triển khai liên tục (`wrangler deploy`, thẻ `deploy-YYYY.MM.DD.N`, `scripts/release-tag.mjs`).
Tài liệu này dành cho **app cài đặt** (Android, Windows, macOS, Linux): thẻ `vYY.M.DDNN`, workflow
[`.github/workflows/release.yml`](../.github/workflows/release.yml). Chuẩn: `.standards/docs/VERSIONING.md` mục 2,
`.standards/docs/DISTRIBUTION_TRUST.md` mục 2 và 7.

## 1. Cắt một bản

1. `main` xanh CI (kể cả Apple). Ghi mục mới vào `CHANGELOG.md` trong PR trước đó.
2. Thẻ ANNOTATED trên commit của `main`: `git tag -a v26.11.2201 -m "Quly Thu Chi 26.11.2201"` rồi `git push origin
   v26.11.2201`. Bản thử: `v26.11.2201-beta.1` ⇒ Release đánh dấu Pre-release. Thẻ đã đẩy KHÔNG đổi tên, KHÔNG xoá.
3. Workflow dựng trên runner sạch, tạo Release NHÁP, quét VirusTotal (khi có `VT_API_KEY`), không engine nào gắn cờ thì
   tự công bố. `versionCode` = `YYMDDNN` (bỏ dấu chấm), Windows FileVersion = `YY.M.DDNN.0` (workflow kiểm).

## 2. Tệp trên Release

| Tệp | Nền tảng | Trạng thái ký |
| --- | --- | --- |
| `qulythuchi_<V>_windows-x64-portable.zip` | Windows 10/11 x64 | Chưa Authenticode (chờ SignPath/Certum) - SmartScreen có thể hỏi |
| `qulythuchi_<V>_macos-universal.zip` | macOS 12+ (Intel + Apple Silicon) | Ad-hoc + sandbox; chưa notarize (chờ Apple Developer 2027) |
| `qulythuchi_<V>_linux-x64.deb` / `.tar.gz` | Ubuntu 22.04+, Debian 12+ | Kiểm bằng SHA256SUMS + chứng thực |
| `qulythuchi_<V>_android-universal.apk` | Android (minSdk của Flutter) | Khoá APK riêng (chỉ khi đã có bí mật, mục 4) |
| `qulythuchi_<V>_sbom.spdx.json` | SBOM SPDX của mã nguồn | |
| `qulythuchi_<V>_provenance.intoto.jsonl` | Bundle chứng thực SLSA (kiểm ngoại tuyến) | |
| `SHA256SUMS.txt` + `SHA256SUMS.txt.sigstore.json` | Mã băm mọi tệp, ký Sigstore keyless | |

AAB cho Google Play (`TSU_CHANNEL=play`) chỉ là artifact của lần chạy (30 ngày), nộp tay vào Play Console - KHÔNG lên
Release. APK trên Release dùng `TSU_CHANNEL=direct` và khoá khác bản Play nên KHÔNG cập nhật chéo được.

## 3. Người dùng kiểm tệp tải về

```bash
sha256sum -c SHA256SUMS.txt --ignore-missing
cosign verify-blob SHA256SUMS.txt --bundle SHA256SUMS.txt.sigstore.json \
  --certificate-identity-regexp '^https://github.com/tsudev-org/qulythuchi/.github/workflows/release.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
gh attestation verify qulythuchi_<V>_linux-x64.deb --repo tsudev-org/qulythuchi
```

Windows PowerShell: `Get-FileHash .\qulythuchi_<V>_windows-x64-portable.zip -Algorithm SHA256` rồi so với `SHA256SUMS.txt`.

## 4. Bí mật (Environment `release`, chỉ thẻ `v*` dùng được)

| Bí mật | Dùng cho | Ai đặt |
| --- | --- | --- |
| `ANDROID_APK_KEYSTORE_BASE64`, `_KEYSTORE_PASSWORD`, `_KEY_ALIAS`, `_KEY_PASSWORD` | APK trên Release | 👤 `scripts/android-keys.sh` |
| `ANDROID_UPLOAD_*` (cùng bốn hậu tố) | AAB nộp Play | 👤 `scripts/android-keys.sh` |
| `APPLE_CERT_P12_BASE64`, `APPLE_CERT_PASSWORD`, `APPLE_SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD` | Ký Developer ID + notarize macOS | 👤 khi có Apple Developer |
| `VT_API_KEY` (repo) | Quét VirusTotal | 👤 |

Thiếu bí mật nào thì bước đó tự bỏ qua (có cảnh báo); Gradle chặn mọi tệp ký bằng khoá debug
(`QLTC_REQUIRE_RELEASE_KEY=1`). Khi nạp khoá Android, 👤 `SHOULD` bật "Required reviewers" cho Environment `release`.

Dấu vân tay SHA-256 chứng chỉ ký (ghi khi 👤 tạo khoá; người dùng đối chiếu bằng `apksigner verify --print-certs`):

- APK trên Release (`qulythuchi-apk`, tạo 23/11/2026):
  `34:41:64:51:7B:22:3B:DB:8A:3D:E3:26:7D:BE:1C:87:0B:73:34:58:BF:F9:DA:B3:19:EE:DB:A7:62:FC:4E:98`
- Upload Play (`qulythuchi-upload`, tạo 23/11/2026; Play App Signing giữ khoá ký app thật):
  `41:86:5C:BF:CC:B2:0A:11:C8:18:72:3A:5B:68:E3:6C:D7:8A:D6:3E:1B:2D:02:BB:54:4F:BB:2A:59:49:64:84`

## 5. Kiểm định định kỳ

- DAST: [`.github/workflows/dast.yml`](../.github/workflows/dast.yml) - ZAP baseline (thụ động) với `/` và `/app/`
  hằng tuần; cảnh báo chưa ghi lý do trong `.zap/rules.tsv` ⇒ đỏ.
- Khôi phục: test `.qtbak` (sao lưu/khôi phục mã hoá) và đồng bộ chạy trong CI mỗi PR; kiểm tay trên bản phát hành:
  cài mới ⇒ "Khôi phục từ tệp sao lưu" ⇒ số dư trùng máy gốc.

## 6. Kênh trình quản lý gói (Scoop, Homebrew, winget, APT/RPM, MSIX)

Nguồn khai báo duy nhất: [`packaging/package.json`](../packaging/package.json) (`.standards/docs/PACKAGING.md` mục 3).
Bucket `tsudev-org/scoop-bucket`, tap `tsudev-org/homebrew-tap` và kho `tsudev-org/linux-packages` (APT/RPM
`pkg.tsudev.com`) tự sinh manifest từ GitHub Release - repo này KHÔNG giữ token ghi vào chúng.

Hiện `channels` để trống, mọi kênh ở `planned`: các bản đến nay đều là `-beta` (Pre-release) và Scoop/Homebrew đọc
`releases/latest` (bỏ qua Pre-release); `tagRegex` cũng chỉ nhận thẻ chính thức. Khi có bản chính thức đầu tiên
(sau khi 👤 nghiệm thu P9/P7b): chuyển kênh từ `planned` sang `channels`, mở PR thêm sản phẩm vào bucket/tap
(`bucket/qulythuchi.json`, `Casks/qulythuchi.rb`) và `linux-packages/products.json` theo AGENTS.md của từng repo đó.
winget/MSIX cần tài khoản Microsoft Partner Center (👤).
