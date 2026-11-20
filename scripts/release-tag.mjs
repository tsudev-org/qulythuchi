#!/usr/bin/env node
// Gắn thẻ cho MỖI lần phát hành production (Worker + web app + site) của qulythuchi.tsudev.com.
//
// Phần web/máy chủ của qulythuchi triển khai liên tục, không có bản phát hành dạng tệp (app cài đặt có thẻ `vYY.M.DDNN`
// riêng khi phát hành - P10). "Bản đang chạy trên production" vẫn phải có một tên duy nhất trong git để đối chiếu được
// (VERSIONING.md mục 2.6; OpenSSF Best Practices: version_unique, version_tags, release_notes). Chép cách làm của
// tsudev `scripts/release-tag.js`.
//
// Khuôn: `deploy-YYYY.MM.DD.N` (N đếm từ 1 trong ngày, giờ Việt Nam). Thẻ ANNOTATED, nội dung là ghi chú phát hành:
// danh sách commit (squash của từng PR) trên main kể từ thẻ trước. GitHub hiện ở
// https://github.com/tsudev-org/qulythuchi/releases/tag/<thẻ>. CỐ Ý không tạo GitHub Release (Release không ký ⇒
// Scorecard Signed-Releases chấm 0 thay vì "không áp dụng").
//
//   node scripts/release-tag.mjs               gắn thẻ HEAD rồi đẩy lên origin
//   node scripts/release-tag.mjs --dry-run     chỉ in tên thẻ + ghi chú
//   node scripts/release-tag.mjs --from-deploy gọi sau `npm run deploy` (postdeploy): lỗi điều kiện chỉ cảnh báo
//
// Chỉ gắn khi HEAD TRÙNG origin/main và cây làm việc sạch: bản dựng từ nhánh tính năng hay thay đổi chưa commit không
// phải "phiên bản" của ai cả.

import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const PREFIX = 'deploy-';
export const TAG_RE = /^deploy-(\d{4})\.(\d{2})\.(\d{2})\.(\d+)$/;

/** Thẻ deploy kế tiếp trong ngày `day` (`YYYY.MM.DD`) giữa các thẻ có sẵn. */
export function nextTagName(day, existing) {
  const n = existing.reduce((max, t) => {
    const m = TAG_RE.exec(t);
    return m && `${m[1]}.${m[2]}.${m[3]}` === day ? Math.max(max, Number(m[4])) : max;
  }, 0);
  return `${PREFIX}${day}.${n + 1}`;
}

/** Ngày giờ Việt Nam (UTC+7), không phụ thuộc múi giờ của máy. */
export function vnDate(now = new Date()) {
  const d = new Date(now.getTime() + 7 * 3600 * 1000);
  const p = (n) => String(n).padStart(2, '0');
  return { y: d.getUTCFullYear(), m: p(d.getUTCMonth() + 1), d: p(d.getUTCDate()), hm: `${p(d.getUTCHours())}:${p(d.getUTCMinutes())}` };
}

const git = (...a) => execFileSync('git', a, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();

function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const fromDeploy = args.includes('--from-deploy');
  const stop = (msg) => {
    if (fromDeploy) {
      console.warn(`⚠ không gắn thẻ phiên bản: ${msg}`);
      process.exit(0);
    }
    console.error(`✘ ${msg}`);
    process.exit(1);
  };

  try {
    git('fetch', '--quiet', '--tags', 'origin', 'main');
  } catch {
    stop('không fetch được origin');
  }
  const head = git('rev-parse', 'HEAD');
  if (head !== git('rev-parse', 'origin/main')) stop('HEAD không trùng origin/main');
  if (git('status', '--porcelain', '--untracked-files=no')) stop('cây làm việc có thay đổi chưa commit');

  const onHead = git('tag', '--points-at', 'HEAD', '--list', `${PREFIX}*`);
  if (onHead) {
    console.log(`✓ HEAD đã có thẻ ${onHead.split('\n')[0]} - không gắn thêm`);
    return;
  }

  const t = vnDate();
  const day = `${t.y}.${t.m}.${t.d}`;
  const name = nextTagName(day, git('tag', '--list', `${PREFIX}${day}.*`).split('\n').filter(Boolean));

  let prev = '';
  try {
    prev = git('describe', '--tags', '--abbrev=0', '--match', `${PREFIX}*`, 'HEAD');
  } catch {
    // thẻ đầu tiên
  }
  const range = prev ? `${prev}..HEAD` : 'HEAD~20..HEAD';
  const lines = git('log', '--first-parent', '--format=- %s', range).split('\n').filter(Boolean);
  const msg = [
    `qulythuchi.tsudev.com ${name}`,
    '',
    `Production deployment at ${t.hm} ${t.d}/${t.m}/${t.y} (UTC+7), commit ${head.slice(0, 12)}.`,
    prev ? `Changes since ${prev}:` : 'Changes (first tagged deployment, last 20 commits on main):',
    '',
    ...(lines.length ? lines : ['- (no new commits)']),
    '',
  ].join('\n');

  console.log(msg);
  if (dryRun) {
    console.log(`(chạy thử - chưa gắn ${name})`);
    return;
  }
  git('tag', '-a', name, '-m', msg);
  try {
    execFileSync('git', ['push', 'origin', `refs/tags/${name}`], { stdio: ['ignore', 'inherit', 'inherit'] });
  } catch {
    stop(`đã gắn ${name} ở máy nhưng chưa đẩy được - chạy: git push origin ${name}`);
  }
  console.log(`✓ gắn thẻ ${name} và đẩy lên origin`);
  console.log(`  Thêm một dòng vào CHANGELOG.md mục "Bản triển khai": ${name} - ${t.d}/${t.m}/${t.y} - <tóm tắt>`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
