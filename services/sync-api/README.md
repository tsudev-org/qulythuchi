# services/sync-api - máy chủ đồng bộ zero-knowledge

Cloudflare Workers + Hono + D1 + R2. Chỉ nhận/trả **bản mã** (phong bì v1 của `packages/core`), không bao giờ thấy
bản rõ. Quyết định: ADR-0001/0002/0003/0004/0010. Rà soát: `docs/security-reviews/20261118-p5-sync-api.md`.

## Chạy

```bash
npx -y npm@11.21.2 ci        # npm 10 lỗi "edgesOut" với cây phụ thuộc này - dùng npm 11 ghim
npm run check                # typecheck + lint + test (D1/R2 giả lập, IdP giả, không cần token)
npm run audit                # production sạch; dev chỉ ngoại lệ có hạn trong audit-allowlist.json
npm run dev                  # wrangler dev (cần .dev.vars với SESSION_SECRET/IP_HASH_SALT GIẢ - không commit)
```

Dữ liệu mẫu THẬT của lõi: `test/fixtures/core-v1.json`, sinh lại bằng
`(cd ../../packages/core && dart run tool/gen_server_fixture.dart > ../../services/sync-api/test/fixtures/core-v1.json)`.

## API (`/api/v1`)

| Phương thức + đường dẫn | Việc |
| --- | --- |
| `GET /auth/app/start`, `GET /auth/web/start`, `GET /auth/callback` | Đăng nhập tsudev.com (OIDC + PKCE), mã một lần cho app |
| `POST /api/v1/auth/token` | `authorization_code` (đổi mã + verifier) hoặc `refresh_token` (xoay vòng) |
| `POST /api/v1/auth/logout`, `POST /api/v1/auth/web-logout`, `GET /api/v1/auth/status` | Đăng xuất / trạng thái web |
| `POST /api/v1/sync/push` | `{records: [{id, type, wallet_id, sealed(base64), deleted}]}` ≤ 200 ⇒ kết quả từng bản ghi |
| `GET /api/v1/sync/pull?since=&limit=` | Bản ghi có `rev > since`, `cursor`, `has_more` |
| `GET /api/v1/keys`, `PUT /api/v1/keys/account`, `PUT /api/v1/keys/wallets` | Gói khóa tài khoản, khóa ví đã bọc |
| `PUT/GET/DELETE /api/v1/files/:id` | Tệp đính kèm đã mã hóa (≤ 10 MiB) |
| `GET /api/v1/me`, `/me/usage`, `/me/devices`, `DELETE /me/devices/:id`, `/me/export`, `POST/DELETE /me/deletion` | Hồ sơ, thiết bị, xuất, xóa tài khoản |

Lỗi luôn là `{code, message}` (message tiếng Việt cố định, không chứa dữ liệu người dùng).

## Triển khai (production `qulythuchi.tsudev.com`)

```bash
npm run deploy               # áp migration D1 từ xa rồi wrangler deploy
```

- Secret (một lần, giá trị ngẫu nhiên, không in ra): `openssl rand -base64 48 | tr -d '\n' | npx wrangler secret put SESSION_SECRET`,
  tương tự `IP_HASH_SALT`. Đổi `SESSION_SECRET` ⇒ mọi access token cũ hết hiệu lực (refresh vẫn dùng được).
- Migration đã áp dụng là BẤT BIẾN - đổi lược đồ bằng tệp `migrations/000N_*.sql` mới.
- Client OIDC `qulythuchi` phải có ở tsudev.com (phiếu `tsudev/logs/handover/20261118-QT1_*`).
