# PHIẾU BÀN GIAO 20261125-02 - Việc cho phiên sau (sau phiên `qulythuchi-10`)

- **Người gửi**: agent-qulythuchi (phiên `qulythuchi-10`, AKB `SES-20261125-0937-994b`), 25/11/2026
- **Trạng thái**: MỞ. Thay phiếu `20261125-01` (ĐÓNG). Bảng việc chờ 👤 vẫn ở phiếu `20261124-03` mục 2.
- **Đọc kèm**: `logs/STATE.md`, phiếu `20261125-UI2_*` (mục Kết quả), `third_party/sodium/BAN_VA.md` (trong #89).

## 0. Hiện trạng (25/11/2026, trưa)

- `main` = `b7f492c` (#88). **#89 CHƯA gộp ⇒ `main` dựng macOS/iOS vẫn HỎNG**, chưa cắt beta trên Flutter 3.50.
- Upstream Skycoder42/libsodium_dart_bindings#245 vẫn MỞ, `sodium` mới nhất 4.1.5+1 ⇒ giữ `third_party/sodium`.
- PR mở (thứ tự gộp gợi ý):

  | PR | Nội dung | CI | Ghi chú |
  | --- | --- | --- | --- |
  | #89 | Vá tạm hook sodium macOS/iOS | 17/17 xanh | Gộp TRƯỚC - các PR khác đỏ macOS/iOS + gitleaks cho tới khi #89 vào `main` |
  | #90 | Đo khởi động desktop (chồng #89) | xanh | GitHub tự đổi đích sang `main` khi #89 gộp ⇒ kiểm CI lại |
  | #91 | Log phiên 09 + 10 (STATE, phiếu) | - | Chỉ `logs/` |
  | #92 | UI2-a site: preload font + font dự phòng đo thật, tràn ngang 360 px | đỏ macOS OCR + gitleaks (do `main`, mục 4) | |
  | #93 | UI2 `/app/`: màn chờ theo Sáng/Tối, chữ TsuDEV | đỏ macOS/iOS + gitleaks (do `main`) | |
  | #94 | Sync tsudev-standards v6.0.0 (nền Sáng giấy) | - | **Chồng #93** - gộp #93 trước |
  | #95 | Màn lỗi Linux hướng dẫn Secret Service | - | |

- Sau khi gộp #92-#94: deploy website + `/app/` (`scripts/build-web.sh` + wrangler, ghi nhớ `cloudflare-deploy-tooling`),
  rồi quay khung hình production lại (mục 1.2).

## 1. Việc agent tự làm (theo thứ tự)

1. **Sau khi 👤 gộp #89**: kiểm CI #90 (đổi đích) và chạy lại CI #92-#95 (macOS/iOS + gitleaks phải xanh); cắt beta
   `v26.11.DDNN-beta.1` - bản đầu trên Flutter 3.50 + pdfrx 3.1.0 (+ màn chờ web, bảng màu v6 nếu đã gộp); theo dõi
   VirusTotal (`pdfrx_pdfium_gate.dll` băm mới, `docs/store/antivirus.md`). Theo dõi #245 mỗi phiên.
2. **UI2 đợt 2** (phiếu `20261125-UI2_*` mục Kết quả "Chưa làm"): (a) quay khung hình production sau deploy, kiểm hệ số
   font dự phòng trên máy CÓ Arial (WSL này không có Arial/Arimo/Liberation); (b) B.2 hoạ tiết header/footer tĩnh
   (≤ 15% sắc sản phẩm, hoạ tiết `cot-tang-truong`), B.3 nền thẻ theo thể loại bằng hoạ tiết hình học CSS + chuyển động
   icon khi rê (tắt dưới reduced-motion) - DESIGN_SYSTEM.md mục 5 v6.0.0; (c) Lighthouse lại (LCP/CLS/INP).
3. APK unbundled (phiếu 20261125-01 mục 1.4, số đo không đổi): **CHỜ 👤 chọn (a)/(b)/(c)**, chưa làm.
4. `material_ui`: khi `tsudev_ui` có bản dùng `material_ui` (hiện v0.5.0 chưa) ⇒ `dart fix --apply
   --code=migrate_design_widgets`, gỡ 76 dòng ignore + header `l10n.yaml`. Màn chào `TsuSignInScreen` lấy màu của
   `tsudev_ui` - theo bảng Sáng v6.0.0 khi gói nâng.
5. QR vai XÁC NHẬN (`tsudev_ui` v0.5.0 `TsuXdApprover`): kiểm QR2b phía tsudev.com trước.

## 2. Bằng chứng / số đo của phiên

- UI2: bảng lỗi + cách sửa ở phiếu `20261125-UI2_*` mục Kết quả. Font sau sửa bắt đầu tải ~175 ms (cùng lúc CSS) thay vì
  sau khi CSS về; `/app/` `flutter-first-frame` ~5 s (không giới hạn mạng), màn chờ gỡ đúng ở Sáng + Tối.
- Linux mục 1.5 (cũ): bản phát hành `v26.11.2403-beta.1` KHÔNG sập khi thiếu `org.freedesktop.secrets` (PlatformException ⇒
  `StartupErrorApp`); `terminate ... LibsecretError` chỉ ở bản dựng bằng clang cục bộ (AKB `ISS-20261125-1046-bbaf`).
- Test app 169/169 (#95), 167/167 (#93, #94); `check-standards.sh` đạt với v6.0.0.

## 3. Việc chờ 👤

Gộp #89 → #90 → #91 → #92 → #93 → #94 → #95; chọn phương án APK (phiếu 20261125-01 mục 1.4). Còn lại không đổi (phiếu
20261124-03 mục 2): mua thử Pro + Ủng hộ; nghiệm thu P9 + P7b; Quét hóa đơn desktop; "Quét để đăng nhập"; `PRO_ENFORCE=on`.

## 4. Bẫy mới

- **gitleaks quét `--all`**: CI checkout `fetch-depth: 0` kéo mọi nhánh ⇒ commit `third_party/sodium` của #89 (báo nhầm
  `generic-api-key`) làm MỌI PR khác đỏ cho tới khi #89 gộp (ngoại lệ nằm trong `.gitleaks.toml` của #89). Tái hiện:
  `gitleaks git --log-opts="--all" .` (AKB `LES-20261125-1032-25c7`).
- **Lỗi native chỉ thấy ở bản dựng cục bộ** (clang trong `~/.cache/lotus-tmp`): đối chiếu artefact CI trước khi coi là lỗi
  người dùng. Backtrace không cần gdb: `LD_PRELOAD` thư viện nhỏ chặn `__cxa_throw` + `addr2line`.
- `flutter test` cục bộ cần `source ~/.cache/lotus-tmp/envflutter.sh` (clang cho native assets pdfium) RỒI mới đặt
  `PATH=$HOME/tools/flutter/bin:$PATH` (envflutter.sh trỏ Flutter 3.47.9 của phiên khác).
- Dựng web (`scripts/build-web.sh`) khi máy bận (phiên khác chạy Gradle/Flutter) mất > 30 phút - chạy nền; KHÔNG đổi nhánh
  trong lúc dựng (dùng `git worktree` cho việc ghi log).
- Playwright: Chromium headless shell `~/.cache/ms-playwright/chromium_headless_shell-1254/...`; đặt `locale: 'vi-VN'` khi
  rà `/app/` (mặc định `en-US` ⇒ app hiện tiếng Anh).
