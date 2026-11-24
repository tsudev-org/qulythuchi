# Sổ antivirus / báo nhầm - Quly Thu Chi

Chuẩn: `.standards/docs/DISTRIBUTION_TRUST.md` mục 3, 3.1. Job VirusTotal chạy trong `release.yml` (mẫu chung
`tsudev-org/.github`); có engine gắn cờ ⇒ Release giữ NHÁP, nộp báo nhầm ≤ 48 giờ theo phiếu điều phối
`~/projects/logs/handover/20261122-AV1_bao-nham-antivirus-toan-he.md`. Kênh nộp: https://docs.virustotal.com/docs/false-positive-contacts

| Ngày | Bản | Tệp | Kết quả | Việc đã làm |
| --- | --- | --- | --- | --- |
| 24/11/2026 (tối, phiên `qulythuchi-39`) | v26.11.2401-beta.1 + v26.11.2402-beta.1 | zip 2401, `pdfrx_pdfium_gate.dll`, zip 2402 | zip 2402 quét MỚI: 1/73 AhnLab-V3 (cùng mã); zip 2401 + DLL: VirusTotal báo đang quét (`AlreadySubmittedError`), kết quả cũ vẫn cờ | Giữ NHÁP cả hai. Chưa tới mốc 01/12/2026 đánh giá bỏ DLL |
| 24/11/2026 | v26.11.2402-beta.1 | `qulythuchi_26.11.2402-beta.1_windows-x64-portable.zip` (SHA-256 `45ea61e1…6fcab4`) | **1/73: AhnLab-V3 `Trojan/Win.Generic.C5980531`** (cùng mã với 2401 - cùng `pdfrx_pdfium_gate.dll`) | Job VirusTotal tự giữ NHÁP. Không gửi thư mới (thư 24/11 đã nêu DLL; gửi thêm chỉ khi 👤 uỷ quyền). Bỏ nháp cùng lúc với 2401 khi AhnLab gỡ cờ |
| 24/11/2026 (chiều, quét lại) | v26.11.2401-beta.1 | zip + `pdfrx_pdfium_gate.dll` | zip 1/73 (AhnLab-V3, cùng mã); DLL 2/73 (AhnLab-V3, Cynet) | `POST /analyse` cả hai (phiên `qulythuchi-07`) - AhnLab chưa gỡ cờ, mới vài giờ sau thư. Giữ NHÁP. Mốc đánh giá bỏ DLL khỏi gói Windows: 01/12/2026 |
| 24/11/2026 | v26.11.2401-beta.1 | `qulythuchi_26.11.2401-beta.1_windows-x64-portable.zip` | **1/73: AhnLab-V3 `Trojan/Win.Generic.C5980531`** (4 tệp khác 0/73) | Release giữ NHÁP. Khoanh vùng: cờ AhnLab nằm ở `pdfrx_pdfium_gate.dll` (DLL 102 KB do build hook `pdfium_dart` biên dịch, không có thông tin phiên bản) - mới từ bản này (ADR-0020). **24/11 đã gửi thư mục 1** tới v3sos@ahnlab.com từ security@tsudev.com (Resend id `01a20bcb-b2f6-7ce9-ae0a-d9421aec48a7`, CC security@, 👤 uỷ quyền bằng lời). Chờ hãng trả lời |
| 23/11/2026 | v26.11.2304-beta.1 | 5 tệp | 0/73 mỗi tệp | Không cần nộp |
| 23/11/2026 | v26.11.2301-beta.1 | 4 tệp | 0/74 mỗi tệp | Không cần nộp |

Đo từng tệp trong zip 24/11 (VirusTotal API v3): `pdfrx_pdfium_gate.dll` 2/73 (AhnLab-V3, Cynet), `sqlite3mc.dll`
1/74 (Cynet), `libsodium.dll` 1/73 (Cynet), `pdfium.dll` 1/74 (Skyhigh `BehavesLike.Win64.Trojan.wh`), còn lại
(`qulythuchi.exe`, `flutter_windows.dll`, plugin) 0/73. Các DLL thư viện bên thứ ba (sqlite3mc, libsodium, PDFium) bị
Cynet/Skyhigh gắn cờ theo hành vi/điểm học máy - không làm tệp zip bị gắn cờ.

## 1. AhnLab - email v3sos@ahnlab.com (BẮT BUỘC để công bố bản) - ĐÃ GỬI 24/11/2026

**Subject:** False positive report: Quly Thu Chi 26.11.2401-beta.1 (Trojan/Win.Generic.C5980531)

```text
Hello AhnLab V3 team,

We are TsuDEV (https://tsudev.com), the publisher of the files below. AhnLab-V3 on VirusTotal reports them as
Trojan/Win.Generic.C5980531. We believe this is a false positive and kindly ask you to review and whitelist them.

1) qulythuchi_26.11.2401-beta.1_windows-x64-portable.zip
   SHA-256: 965ecbaf4db2b959b4a57e099e2c1c52d8a76ea28744c8a23e92667708d06fd2
   VirusTotal: https://www.virustotal.com/gui/file/965ecbaf4db2b959b4a57e099e2c1c52d8a76ea28744c8a23e92667708d06fd2

2) pdfrx_pdfium_gate.dll (inside the zip above)
   SHA-256: 22e6a70b0dbbf843c695232d0407f1c93899d97b29a7deb9676c7460d4d2c0bd
   VirusTotal: https://www.virustotal.com/gui/file/22e6a70b0dbbf843c695232d0407f1c93899d97b29a7deb9676c7460d4d2c0bd

Product: Quly Thu Chi - an open-source (AGPL-3.0) personal finance app with end-to-end encryption, built with
Flutter. pdfrx_pdfium_gate.dll is a small helper library compiled at build time by the open-source pdfrx /
pdfium_dart package (https://github.com/espresso3389/pdfrx) to load PDFium, which the app uses only to read the
text of bank statements the user chooses to import. It makes no network calls.
Release: https://github.com/tsudev-org/qulythuchi/releases/tag/v26.11.2401-beta.1
Source: https://github.com/tsudev-org/qulythuchi

The files are built from public source code on GitHub Actions and published on GitHub Releases together with a
SHA256SUMS.txt signed with Sigstore. Each file carries SLSA build provenance, verifiable with:
  gh attestation verify <file> -R tsudev-org/qulythuchi
The files are not yet Authenticode-signed.

Please reply to security@tsudev.com if you need anything else.

Thank you,
TsuDEV
https://tsudev.com
```

## 2. Cynet - email soc@cynet.com (tuỳ chọn - cờ chỉ trên DLL lẻ, không trên tệp phát hành)

**Subject:** False positive report: open-source DLLs shipped in Quly Thu Chi (3 files)

```text
Hello Cynet team,

We are TsuDEV (https://tsudev.com). Cynet on VirusTotal reports the following DLLs, shipped inside our open-source
app Quly Thu Chi (https://github.com/tsudev-org/qulythuchi), as "Malicious (score: 100)". They are well-known
open-source libraries; we believe these are false positives and kindly ask you to review them.

1) pdfrx_pdfium_gate.dll - helper built by the pdfrx package (https://github.com/espresso3389/pdfrx)
   SHA-256: 22e6a70b0dbbf843c695232d0407f1c93899d97b29a7deb9676c7460d4d2c0bd
2) sqlite3mc.dll - SQLite3 Multiple Ciphers (https://github.com/utelle/SQLite3MultipleCiphers)
   SHA-256: 6289acda05ea848c59d228f4f63a52d1880e6313f2fa63a7f07440de03feaa7f
3) libsodium.dll - libsodium (https://libsodium.org)
   SHA-256: 8c5de52e433a987bccedb636293f3a476105d998b33cb543f963daf30854ebf3

Release: https://github.com/tsudev-org/qulythuchi/releases/tag/v26.11.2401-beta.1 (SHA256SUMS.txt signed with
Sigstore; SLSA provenance: gh attestation verify <file> -R tsudev-org/qulythuchi).

Please reply to security@tsudev.com if you need anything else.

Thank you,
TsuDEV
https://tsudev.com
```

## 3. Sau khi hãng gỡ cờ

Quét lại tệp trên VirusTotal (nút "Reanalyze" hoặc API `POST /api/v3/files/<sha256>/analyse`) ⇒ 0 engine ⇒ bỏ nháp:
`gh release edit v26.11.2401-beta.1 --draft=false -R tsudev-org/qulythuchi`, rồi ghi dòng kết quả vào bảng trên.
