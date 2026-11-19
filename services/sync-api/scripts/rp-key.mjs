// Sinh cặp khoá EC P-256 cho kênh RP của máy chủ quyền lợi tsudev.com (ADR-0016, tsudev ADR-0002 "Bổ sung PRO1").
// - Khoá RIÊNG ghi ra tệp NGOÀI repo (quyền 600), rồi: npx wrangler secret put RP_PRIVATE_JWK < <tệp>
// - Khoá CÔNG KHAI + câu SQL in ra để chủ tài khoản tsudev (OWNER) đăng ký vào OAuthClient.rpPublicJwk.
// Chạy: node scripts/rp-key.mjs [đường-dẫn-tệp-khoá-riêng]   (mặc định ~/.config/tsudev/qulythuchi-rp.jwk)
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

const out = process.argv[2] ?? join(homedir(), '.config', 'tsudev', 'qulythuchi-rp.jwk');
if (existsSync(out)) {
  console.error(`Đã có ${out} - không ghi đè. Xoá tay nếu thật sự muốn xoay khoá.`);
  process.exit(1);
}
const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
const kid = `qulythuchi-rp-${randomUUID().slice(0, 8)}`;
const priv = { ...privateKey.export({ format: 'jwk' }), kid, alg: 'ES256' };
const pub = { ...publicKey.export({ format: 'jwk' }), kid, alg: 'ES256', use: 'sig' };
mkdirSync(dirname(out), { recursive: true, mode: 0o700 });
writeFileSync(out, JSON.stringify(priv), { mode: 0o600 });
console.log(`Khoá riêng: ${out}`);
console.log(`Khoá công khai (gửi cho OWNER tsudev):\n${JSON.stringify(pub)}`);
console.log(`\nSQL (Neon tsudev, OWNER chạy):\nUPDATE "OAuthClient" SET "rpPublicJwk" = '${JSON.stringify(pub)}'::jsonb WHERE id = 'qulythuchi';`);
