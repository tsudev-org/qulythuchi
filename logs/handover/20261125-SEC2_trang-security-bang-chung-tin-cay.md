# PHIẾU YÊU CẦU SEC2 - Trang `/security` với bằng chứng tin cậy TỰ KIỂM CHỨNG ĐƯỢC

- **Mã phiếu**: 20261125-SEC2 (bản sao cho repo) - **Từ**: phiên `tsudev-8d`, 25/11/2026, theo yêu cầu chủ dự án - **Trạng thái**: MỞ
- **Phiếu gốc (ĐỌC mục 0-2 TRƯỚC)**: `~/projects/logs/handover/20261125-SEC2_trang-security-bang-chung-tin-cay-toan-he.md`
- **Website của repo**: qulythuchi.tsudev.com

## Việc của repo này

E4 security.txt (Contact security@tsudev.com, test Expires) · E5 SSL Labs · E6 Observatory · trang /security thật (mục 2 phiếu gốc) · E8 nếu có bản Windows.

## Ràng buộc (tóm tắt phiếu gốc mục 0)

- TUYỆT ĐỐI không nhãn trang trí: mỗi mục có liên kết tới trang kết quả của bên thứ ba + ngày đo; không có ⇒ không hiện.
- Chỉ khai sự thật; điểm thấp hiện đúng số; không áp dụng ⇒ ghi lý do.
- Số liệu lấy từ tệp trong repo lúc build (không gọi API ngoài khi người xem mở trang).
- Biểu mẫu (Best Practices, SignPath, SSL Labs, Observatory, HSTS preload): mở Edge hồ sơ `tsudev-bp` theo phiếu gốc mục 0.4;
  đăng nhập/OTP/giấy tờ ⇒ 👤 tự nhập. Mỗi lúc một phiên dùng hồ sơ; đóng Edge khi xong.
- Làm trong PR kế tiếp của repo nếu nhỏ; xong ghi một dòng dưới đây + cập nhật hàng của repo ở bảng mục 3 phiếu gốc; `akb` theo chuẩn.

## Kết quả xử lý

- 25/11/2026 - tsudev-8d: mở phiếu.
- 25/11/2026 - agent-qulythuchi (SES-20261125-0104-52cc): E4 (`Contact: mailto:security@tsudev.com` đầu tiên, `Policy` ⇒ `/security/`, `check-dist.mjs` chặn Expires hết hạn/quá 1 năm), E5 SSL Labs A+ (4/4 địa chỉ), E6 Observatory A+ 150 (12/12), trang `/security/` từ `docs/security/trust.json` (E1 16946, E2 7.1, E3 Sigstore + chứng thực + VirusTotal 0/73, E10). E8/E7/E9 ghi "Chưa có" kèm lý do. PR #88; đã cập nhật hàng qulythuchi ở bảng mục 3 phiếu gốc.
