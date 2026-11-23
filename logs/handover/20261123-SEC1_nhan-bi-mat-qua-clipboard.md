# PHIẾU YÊU CẦU SEC1 - Nhận token/secret qua clipboard (qulythuchi)

- **Mã phiếu**: 20261123-SEC1
- **Thời điểm**: 23/11/2026
- **Người gửi**: agent-tsuswico (phiên tsuswico-6e) theo yêu cầu của chủ dự án
- **Phiếu điều phối (ĐỌC TRƯỚC)**: `~/projects/logs/handover/20261123-SEC1_nhan-bi-mat-qua-clipboard-toan-he.md`
- **Trạng thái**: ĐÓNG (23/11/2026, agent-qulythuchi phiên `qulythuchi-1f`)

## 1. Quy tắc áp dụng ngay cho agent của repo này

- KHÔNG đề nghị chủ dự án dán token/secret vào chat, tệp hay lệnh `!`. Lỡ dán vào chat ⇒ coi là đã lộ, đề nghị thay.
- Nhận bí mật: chạy `tsu-nhan-bi-mat ...` bằng `run_in_background`, nhắn "Bấm Copy trên trang <dịch vụ> - không dán vào chat".
  Ưu tiên `--stdout | <lệnh đích>`; cần giữ ⇒ `--luu ~/.config/tsudev/<ten>.env` (chmod 600, ngoài repo).
- KHÔNG in giá trị bí mật (`cat .env`, `sed`…); chỉ in tên biến/độ dài/kết quả kiểm tra.
- Cần người dán vào dashboard ⇒ `tsu-nhan-bi-mat --dua-vao-clipboard <tệp>` rồi `--xoa-lich-su <tệp>`.
- Lịch sử Win+V trên máy đang BẬT ⇒ luôn để công cụ xoá mục khỏi lịch sử.

## 2. Việc cần làm

1. Rà tài liệu/hướng dẫn của repo (README thiết lập, `docs/`, `logs/STATE.md`, phiếu cũ còn mở) - chỗ nào bảo dán token
   vào chat/.env bằng tay ⇒ sửa theo phiếu điều phối mục 2-3.
2. Kiểm `.gitignore` có `.env*` (trừ `.env.example`); gitleaks/push protection theo SECURITY_BASELINE.
3. Liệt kê TÊN các bí mật repo dùng + nơi lưu (GitHub Actions secret / Cloudflare / Vercel / Render / `~/.config/tsudev/`)
   + phạm vi quyền vào mục 3 dưới (không ghi giá trị). Cái nào từng lộ trong chat/log ⇒ báo chủ dự án thay.
4. Ghi AKB của repo "áp dụng SEC1", đổi Trạng thái → ĐÓNG.

## 3. Bí mật của repo (agent điền - CHỈ TÊN)

| Tên | Nơi lưu | Phạm vi | Ghi chú |
| --- | --- | --- | --- |
| `SESSION_SECRET` | Cloudflare Worker `qulythuchi` (secret) | Ký cookie phiên web, mã một lần | Sinh `openssl rand` ⇒ pipe `wrangler secret put` (services/sync-api/README.md) |
| `IP_HASH_SALT` | Cloudflare Worker `qulythuchi` (secret) | Băm IP cho giới hạn tần suất | Như trên |
| `RP_PRIVATE_JWK` | Cloudflare Worker `qulythuchi` (secret) + tệp 600 ngoài repo | Client assertion kênh RP tsudev.com (chỉ đọc quyền lợi) | `services/sync-api/scripts/rp-key.mjs` ⇒ `wrangler secret put < tệp`; xoay theo THREAT_MODEL T28 |
| `ANDROID_APK_{KEYSTORE_BASE64,KEYSTORE_PASSWORD,KEY_ALIAS,KEY_PASSWORD}` | GitHub Environment `release` (chỉ thẻ `v*`) + `~/khoa-ky/qulythuchi` (700/600) | Ký APK trên GitHub Release | `scripts/android-keys.sh` sinh + pipe `gh secret set`, không in |
| `ANDROID_UPLOAD_{...}` (4 bí mật) | Như trên | Ký AAB nộp Google Play (khoá upload) | Như trên |
| `VT_API_KEY` | GitHub secret cấp org `tsudev-org` | Quét VirusTotal (release.yml, dast.yml) | Repo không giữ bản riêng |
| `GITHUB_TOKEN` | Tự cấp mỗi lần chạy Actions | Theo `permissions` từng job | - |

## 4. Kết quả rà (agent-qulythuchi)

1. Tài liệu: không chỗ nào bảo dán token vào chat/.env; mọi bí mật sinh bằng `openssl`/`keytool` và pipe thẳng vào
   `wrangler secret put` / `gh secret set`. Không cần sửa.
2. `.gitignore`: `.env`, `.env.*` (trừ `.env.example`/`.sample`), `*.jks`, `android/key.properties`. gitleaks chạy mỗi PR;
   secret scanning + push protection bật (P0).
3. Không bí mật nào từng lộ trong chat/log của repo (vân tay SHA-256 chứng chỉ Android là thông tin CÔNG KHAI).
4. Đã ghi AKB "áp dụng SEC1".
