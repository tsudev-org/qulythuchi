// Chặn deploy khi thư mục tĩnh chưa dựng đủ: deploy thiếu site hoặc thiếu /app/ sẽ XÓA chúng khỏi production.
// Dựng bằng ./scripts/build-web.sh ở gốc repo (ADR-0013).
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const dist = join(dirname(fileURLToPath(import.meta.url)), '../../../apps/site/dist');
const can = ['index.html', 'bao-mat/index.html', '_headers', 'favicon.ico', 'app/index.html', 'app/main.dart.js', 'app/sodium.js', 'app/sqlite3.wasm'];
const thieu = can.filter((f) => !existsSync(join(dist, f)));
if (thieu.length) {
  console.error(`kiem-tinh: apps/site/dist thiếu ${thieu.join(', ')} - chạy ./scripts/build-web.sh trước khi deploy.`);
  process.exit(1);
}
console.log('kiem-tinh: thư mục tĩnh đủ.');
