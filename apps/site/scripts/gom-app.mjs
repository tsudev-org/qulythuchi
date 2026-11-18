// Gom web app Flutter (apps/app/build/web, build với --base-href /app/) vào dist/app/ để MỘT Worker phục vụ cả site
// lẫn app (ADR-0013). Kiểm trước khi gom: base href đúng, có CSP <meta> riêng của app (site gỡ CSP chung ở /app/*,
// public/_headers), tài nguyên tự phục vụ (không CDN gstatic).
//   QT_CAN_APP=1 ⇒ bắt buộc có bản build (deploy); không đặt ⇒ thiếu bản build thì bỏ qua (CI chỉ kiểm site).
import { cpSync, existsSync, readFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const nguon = join(here, '../../app/build/web');
const dich = join(here, '../dist/app');
const batBuoc = process.env.QT_CAN_APP === '1';

if (!existsSync(join(nguon, 'index.html'))) {
  if (batBuoc) {
    console.error('gom-app: thiếu apps/app/build/web - chạy scripts/build-web.sh (hoặc flutter build web như trong đó).');
    process.exit(1);
  }
  console.warn('gom-app: chưa có bản build web app, bỏ qua /app/ (đặt QT_CAN_APP=1 để bắt buộc).');
  process.exit(0);
}
const html = readFileSync(join(nguon, 'index.html'), 'utf8');
const loi = [];
if (!html.includes('<base href="/app/">')) loi.push('index.html: cần build với --base-href /app/');
if (!/<meta http-equiv="Content-Security-Policy" content="[^"]*script-src 'self' 'wasm-unsafe-eval'/.test(html)) {
  loi.push('index.html: thiếu CSP <meta> của app');
}
if (!existsSync(join(nguon, 'canvaskit/canvaskit.wasm'))) loi.push('thiếu canvaskit/ tự phục vụ: build với --no-web-resources-cdn');
for (const f of ['sodium.js', 'sqlite3.wasm', 'main.dart.js', 'flutter_bootstrap.js']) {
  if (!existsSync(join(nguon, f))) loi.push(`thiếu ${f}`);
}
const boot = readFileSync(join(nguon, 'flutter_bootstrap.js'), 'utf8');
if (/gstatic\.com/.test(boot) && !boot.includes('"useLocalCanvasKit":true')) loi.push('flutter_bootstrap.js trỏ CDN gstatic');
if (loi.length) {
  console.error(`gom-app: ${loi.length} lỗi\n  ${loi.join('\n  ')}`);
  process.exit(1);
}
rmSync(dich, { recursive: true, force: true });
// Không gom service worker cũ của Flutter (không đăng ký - web/flutter_bootstrap.js), source map, bảng ký hiệu gỡ lỗi.
cpSync(nguon, dich, { recursive: true, filter: (p) => !/(flutter_service_worker\.js|\.map|\.symbols)$/.test(p) });
console.log('gom-app: đã gom web app vào dist/app/.');
