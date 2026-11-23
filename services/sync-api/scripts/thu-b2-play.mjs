#!/usr/bin/env node
// Thử kênh B2 của tsudev.com (POST /api/rp/entitlements/play) bằng ĐÚNG cách Worker gọi (client assertion ES256 bằng
// khoá RP), với purchase token GIẢ - không mua gì, không ghi gì.
//   200/409/422/404 purchase_* ⇒ Google đã trả lời: tài khoản dịch vụ PLAY_SERVICE_ACCOUNT_JSON có quyền Play.
//   503 play_unavailable       ⇒ Google từ chối (log Render "[play] ... HTTP 401" = quyền Play Console chưa lan truyền,
//                                403 = API chưa bật) hoặc biến chưa đặt.
//
//   SUB=$(npx wrangler d1 execute qulythuchi --remote --json --command "SELECT oidc_sub FROM users LIMIT 1" \
//     | node -e 'process.stdin.on("data",d=>console.log(JSON.parse(d)[0].results[0].oidc_sub))') \
//     node scripts/thu-b2-play.mjs [đường dẫn khoá RP, mặc định ~/.config/tsudev/qulythuchi-rp.jwk]
//
// `sub` phải là tài khoản tsudev có thật (sub lạ ⇒ 404 unknown_subject trước khi hỏi Google). Không in sub, khoá hay token.
import { readFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { homedir } from 'node:os';
import { importJWK, SignJWT } from 'jose';

const sub = process.env.SUB;
if (!sub) { console.error('Thiếu biến SUB (oidc_sub của một tài khoản thật)'); process.exit(2); }
const jwk = JSON.parse(readFileSync(process.argv[2] || `${homedir()}/.config/tsudev/qulythuchi-rp.jwk`, 'utf8'));
const url = 'https://tsudev.com/api/rp/entitlements/play';
const key = await importJWK(jwk, 'ES256');
const assertion = () => new SignJWT({}).setProtectedHeader({ alg: 'ES256', typ: 'JWT', kid: jwk.kid })
  .setIssuer('qulythuchi').setSubject('qulythuchi').setAudience(url).setIssuedAt().setExpirationTime('120s')
  .setJti(randomBytes(18).toString('base64url')).sign(key);

let ok = true;
for (const productId of ['ung_ho_20k', 'tsudev_pro']) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${await assertion()}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ client_id: 'qulythuchi', sub, packageName: 'com.tsudev.qulythuchi', productId,
      purchaseToken: `thu-nghiem-khong-ton-tai-${randomBytes(8).toString('hex')}` }),
  });
  const body = await res.json().catch(() => ({}));
  const code = body.error || body.code || '';
  console.log(`${productId}: ${res.status} ${code}`);
  if (res.status === 503 || res.status === 401) ok = false;
}
console.log(ok ? 'ĐẠT: Google đã trả lời kênh B2' : 'CHƯA: kênh B2 chưa hỏi được Google (xem log Render "[play]")');
process.exit(ok ? 0 : 1);
