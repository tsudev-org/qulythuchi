#!/usr/bin/env node
/**
 * Dây chuyền thương hiệu của sản phẩm - MỘT lệnh sinh mọi bản logo / icon / favicon từ
 * MỘT ảnh gốc. Đổi logo sau này = thay `assets/brand/source/<tệp>` + chạy lại lệnh này.
 *
 *   node apps/site/scripts/brand-assets.mjs           # sinh lại, ghi tệp
 *   node apps/site/scripts/brand-assets.mjs --check   # CI: báo lỗi nếu tệp đã commit lệch nguồn
 *
 * Cấu hình: `assets/brand/brand.json` (đường dẫn ảnh gốc, chế độ xử lý nền, màu nền đặc,
 * chữ trên ảnh OG). Cần `sharp` (Astro kéo sẵn trong node_modules).
 *
 * Chế độ xử lý ảnh gốc (`mode`):
 *   - "tile"    : logo vẽ sẵn trên NỀN ĐẶC (ô biểu tượng ứng dụng). Cắt vuông chính giữa, bo
 *                 góc theo `tileRadius`. KHÔNG xoá nền - nét trắng trên nền tối sẽ biến mất
 *                 trên nền Sáng nếu xoá.
 *   - "no-white": logo trên nền TRẮNG. Xoá vùng trắng NỐI LIỀN mép ảnh bằng flood fill (lòng
 *                 logo khép kín giữ nguyên), làm mềm biên + khử nhân với trắng (không quầng xám
 *                 trên nền tối), cắt sát, chừa lề `padding`.
 *
 * Định dạng đầu ra (apps/site/public/ và apps/app/web/):
 *   - brand/logo-<id>-{48,96,144,192}.{avif,webp} + brand/logo-<id>.png (512): <picture> ở
 *     header - AVIF/WebP nhỏ hơn PNG 5-20 lần, PNG chỉ là đường lui.
 *   - favicon.ico 7 lớp THẬT (16-256), favicon-{16,32,96}.png, android-chrome-{192,512}.png,
 *     maskable riêng (nền đặc, vùng an toàn 80%), apple-touch-icon 180 nền đặc, og-image 1200x630.
 *   - apps/app/web/: favicon.png + icons/Icon-{192,512}.png, Icon-maskable-{192,512}.png, apple-touch-icon.png
 *     của web app Flutter (/app/).
 *   - Icon app gốc (LG1): Android mipmap (cũ + adaptive + monochrome), iOS AppIcon (nền đặc, không alpha), macOS
 *     AppIcon (ô bo góc theo lưới Big Sur), Windows app_icon.ico 7 lớp, Linux (cửa sổ GTK đọc từ asset Flutter).
 *   - apps/app/assets/brand/: logo trong giao diện app và trong tệp xuất (PDF) - logo sản phẩm + logo tsudev
 *     (khối nhà làm, mục 15.5).
 *   - assets/brand/app/: bộ đóng gói desktop (qulythuchi.ico, qulythuchi.icns, linux/qulythuchi-<cỡ>.png).
 */
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { DO_PHU, cotSvg } from '../src/lib/cot-tang-truong.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WEB = path.resolve(HERE, '..'); // apps/site
const ROOT = path.resolve(WEB, '../..');
const require = createRequire(path.join(WEB, 'package.json'));
const sharp = require('sharp');

const CFG = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/brand/brand.json'), 'utf8'));
// Bản sắc sản phẩm (tsudev-standards v5.0.0): og-image dùng màu chế độ Tối của products/<id>.json + hoạ tiết chữ ký.
const BAN_SAC = JSON.parse(fs.readFileSync(path.join(ROOT, `.standards/tokens/products/${CFG.id}.json`), 'utf8'));
const CHECK = process.argv.includes('--check');
const outputs = new Map(); // đường dẫn tuyệt đối -> Buffer

const emit = (abs, buf) => outputs.set(abs, buf);
const pub = (rel) => path.join(WEB, 'public', rel);
const hex = (h) => ({
  r: parseInt(h.slice(1, 3), 16),
  g: parseInt(h.slice(3, 5), 16),
  b: parseInt(h.slice(5, 7), 16),
  alpha: 1,
});
const CLEAR = { r: 0, g: 0, b: 0, alpha: 0 };

/** Ô biểu tượng: cắt vuông chính giữa, bo góc (mặt nạ SVG). */
async function tile(buf) {
  const m = await sharp(buf).metadata();
  const side = Math.min(m.width, m.height);
  const big = 1024;
  const sq = await sharp(buf)
    .extract({
      left: Math.floor((m.width - side) / 2),
      top: Math.floor((m.height - side) / 2),
      width: side,
      height: side,
    })
    .resize(big, big, { kernel: 'lanczos3' })
    .png()
    .toBuffer();
  const r = Math.round(big * (CFG.tileRadius ?? 0.22));
  const mask = Buffer.from(
    `<svg width="${big}" height="${big}"><rect width="${big}" height="${big}" rx="${r}" ry="${r}"/></svg>`
  );
  return { rounded: await sharp(sq).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer(), square: sq };
}

/** Xoá nền trắng nối liền mép; giữ mọi mảng trắng nằm TRONG logo. */
async function noWhite(buf, { inner = 12, outer = 40 } = {}) {
  const { data, info } = await sharp(buf).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: W, height: H } = info;
  const C = 4;
  const dev = (p) => 255 - Math.min(data[p * C], data[p * C + 1], data[p * C + 2]);
  const bg = new Uint8Array(W * H);
  const st = [];
  const push = (x, y) => {
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    const p = y * W + x;
    if (bg[p] || dev(p) > outer) return;
    bg[p] = 1;
    st.push(x, y);
  };
  for (let x = 0; x < W; x++) {
    push(x, 0);
    push(x, H - 1);
  }
  for (let y = 0; y < H; y++) {
    push(0, y);
    push(W - 1, y);
  }
  while (st.length) {
    const y = st.pop();
    const x = st.pop();
    push(x + 1, y);
    push(x - 1, y);
    push(x, y + 1);
    push(x, y - 1);
  }
  for (let p = 0; p < W * H; p++) {
    if (!bg[p]) continue;
    const d = dev(p);
    const a = d <= inner ? 0 : Math.round(((d - inner) / (outer - inner)) * 255);
    if (a > 0 && a < 255) {
      const k = a / 255;
      for (let c = 0; c < 3; c++) {
        const v = (data[p * C + c] - (1 - k) * 255) / k;
        data[p * C + c] = Math.max(0, Math.min(255, Math.round(v)));
      }
    }
    data[p * C + 3] = a;
  }
  const png = await sharp(data, { raw: { width: W, height: H, channels: C } }).png().toBuffer();
  const trimmed = await sharp(png).trim({ threshold: 1 }).png().toBuffer();
  const m = await sharp(trimmed).metadata();
  const side = Math.round(Math.max(m.width, m.height) * (1 + 2 * (CFG.padding ?? 0.06)));
  const sq = await sharp({ create: { width: side, height: side, channels: 4, background: CLEAR } })
    .composite([{ input: trimmed, left: Math.round((side - m.width) / 2), top: Math.round((side - m.height) / 2) }])
    .png()
    .toBuffer();
  return { rounded: sq, square: sq };
}

/** ICO thật nhiều lớp (PNG bên trong mỗi lớp). */
function buildIco(entries) {
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(entries.length, 4);
  const dir = Buffer.alloc(16 * entries.length);
  let offset = header.length + dir.length;
  entries.forEach((e, i) => {
    const b = i * 16;
    dir.writeUInt8(e.size >= 256 ? 0 : e.size, b);
    dir.writeUInt8(e.size >= 256 ? 0 : e.size, b + 1);
    dir.writeUInt16LE(1, b + 4);
    dir.writeUInt16LE(32, b + 6);
    dir.writeUInt32LE(e.data.length, b + 8);
    dir.writeUInt32LE(offset, b + 12);
    offset += e.data.length;
  });
  return Buffer.concat([header, dir, ...entries.map((e) => e.data)]);
}

/** ICNS: các khối PNG có mã kiểu 4 byte (icp4=16, icp5=32, icp6=64, ic07=128, ic08=256, ic09=512, ic10=1024). */
function buildIcns(chunks) {
  const parts = chunks.map(([type, data]) => {
    const h = Buffer.alloc(8);
    h.write(type, 0, 'ascii');
    h.writeUInt32BE(data.length + 8, 4);
    return Buffer.concat([h, data]);
  });
  const head = Buffer.alloc(8);
  head.write('icns', 0, 'ascii');
  head.writeUInt32BE(8 + parts.reduce((n, b) => n + b.length, 0), 4);
  return Buffer.concat([head, ...parts]);
}

const esc = (s) => String(s).replace(/[<>&'"]/g, (c) => `&#${c.charCodeAt(0)};`);

async function main() {
  const raw = fs.readFileSync(path.join(ROOT, 'assets/brand', CFG.source));
  // eslint-disable-next-line prefer-const
  let { rounded, square } = CFG.mode === 'tile' ? await tile(raw) : await noWhite(raw);
  const SOLID = hex(CFG.solidBg);
  const at = (size, src = rounded) =>
    sharp(src).resize(size, size, { fit: 'contain', background: CLEAR, kernel: 'lanczos3' }).png({ compressionLevel: 9 }).toBuffer();
  const png = async (size, src) => sharp(await at(size, src)).png({ palette: true, quality: 92, effort: 10, compressionLevel: 9 }).toBuffer();
  const onSolid = async (size, scale, src = rounded) => {
    const inner = Math.round(size * scale);
    const pad = Math.round((size - inner) / 2);
    return sharp({ create: { width: size, height: size, channels: 4, background: SOLID } })
      .composite([{ input: await at(inner, src), top: pad, left: pad }])
      .flatten({ background: SOLID })
      .removeAlpha()
      .png({ compressionLevel: 9 })
      .toBuffer();
  };
  const ico = async (src) => {
    const entries = [];
    for (const size of [16, 24, 32, 48, 64, 128, 256]) entries.push({ size, data: await at(size, src) });
    return buildIco(entries);
  };
  // Ô bo góc nền đặc (lưới icon macOS / ô logo trên nền tối), trong suốt ngoài ô.
  const roundTile = async (size, scale, radius = 0.225) => {
    const r = Math.round(size * radius);
    const mask = Buffer.from(`<svg width="${size}" height="${size}"><rect width="${size}" height="${size}" rx="${r}" ry="${r}"/></svg>`);
    const solid = await onSolid(size, scale, square);
    return sharp(solid).ensureAlpha().composite([{ input: mask, blend: 'dest-in' }]).png({ compressionLevel: 9 }).toBuffer();
  };
  const padTo = async (size, inner, src) => {
    const pad = Math.round((size - inner) / 2);
    return sharp({ create: { width: size, height: size, channels: 4, background: CLEAR } })
      .composite([{ input: src, top: pad, left: pad }])
      .png({ compressionLevel: 9 })
      .toBuffer();
  };
  // `iconTile`: logo nền trắng có mảng tối (navy chìm trên nền Tối) ⇒ mọi bản "icon" (favicon, logo header, .ico,
  // PNG Linux, logo trong app) đặt trên ô nền đặc bo góc. Trên nền Sáng ô hòa vào nền; trên nền Tối logo vẫn rõ.
  if (CFG.iconTile) rounded = await roundTile(1024, 0.84);

  // --- Logo cho giao diện website (<picture>).
  for (const s of [48, 96, 144, 192]) {
    const base = sharp(await at(s));
    emit(pub(`brand/logo-${CFG.id}-${s}.avif`), await base.clone().avif({ quality: 70, effort: 9 }).toBuffer());
    emit(pub(`brand/logo-${CFG.id}-${s}.webp`), await base.clone().webp({ quality: 90, effort: 6 }).toBuffer());
  }
  emit(pub(`brand/logo-${CFG.id}.png`), await png(512));

  // --- Dấu hiệu tsudev ở chân trang (nối về nhà chung): LUÔN từ logo tsudev chính thức, kể cả khi sản phẩm có logo riêng.
  const tsudev = (await tile(fs.readFileSync(path.join(ROOT, 'assets/brand/source/logo-tsudev.png')))).rounded;
  for (const s of [48, 96]) {
    const base = sharp(await at(s, tsudev));
    emit(pub(`brand/logo-tsudev-${s}.avif`), await base.clone().avif({ quality: 70, effort: 9 }).toBuffer());
    emit(pub(`brand/logo-tsudev-${s}.webp`), await base.clone().webp({ quality: 90, effort: 6 }).toBuffer());
  }
  emit(pub('brand/logo-tsudev-256.png'), await png(256, tsudev));

  // --- Favicon + PWA.
  emit(pub('favicon.ico'), await ico(rounded));
  for (const s of [16, 32, 96]) emit(pub(`favicon-${s}x${s}.png`), await png(s));
  for (const s of [192, 512]) {
    emit(pub(`android-chrome-${s}x${s}.png`), await png(s));
    emit(pub(`android-chrome-maskable-${s}x${s}.png`), await onSolid(s, 0.8, square));
  }
  // iOS tô đen chỗ trong suốt và tự bo góc: nền đặc, ô vuông đầy (tile) hoặc logo 86% (no-white).
  emit(pub('apple-touch-icon.png'), await onSolid(180, CFG.mode === 'tile' ? 1 : 0.86, square));

  // --- Ảnh chia sẻ 1200x630 (nền tối là hằng thương hiệu, không theo chế độ người xem).
  const W = 1200;
  const H = 630;
  const L = 300;
  const toi = BAN_SAC.colors.dark;
  const back = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
    <defs><radialGradient id="g" cx="0.28" cy="0.5" r="0.75"><stop offset="0%" stop-color="${toi.primary}" stop-opacity="0.16"/><stop offset="100%" stop-color="#0a0a0a" stop-opacity="0"/></radialGradient></defs>
    <rect width="${W}" height="${H}" fill="#0a0a0a"/>
    <rect width="${W}" height="${H}" fill="url(#g)"/>
    <g fill-opacity="${DO_PHU}">${cotSvg(560, 360, { mau: toi.accent, bo: 12, dx: W - 600, dy: H - 360 })}</g>
    <text x="500" y="270" font-family="DejaVu Sans, Verdana, sans-serif" font-size="68" font-weight="700" fill="#ededed">${esc(CFG.name)}</text>
    ${CFG.ogLines.map((l, i) => `<text x="500" y="${340 + i * 44}" font-family="DejaVu Sans, Verdana, sans-serif" font-size="30" fill="#b4b4b4">${esc(l)}</text>`).join('')}
    <text x="500" y="${360 + CFG.ogLines.length * 44 + 20}" font-family="DejaVu Sans, Verdana, sans-serif" font-size="26" fill="${toi['text-link']}">${esc(CFG.domain)}</text>
  </svg>`);
  emit(
    pub('og-image.png'),
    await sharp(back)
      .composite([{ input: await at(L), left: 140, top: Math.round((H - L) / 2) }])
      .png({ palette: true, quality: 92, effort: 10, compressionLevel: 9 })
      .toBuffer()
  );

  // --- Hồ sơ Google Play (docs/store/google-play.md, phiếu GP1): biểu tượng 512x512 PNG 32-bit (Play đòi kênh alpha,
  // tự bo góc + đổ bóng nên ô phải vuông đầy, nền đặc) và ảnh nổi bật 1024x500 (không chữ sát mép: Play có thể cắt).
  const store = (rel) => path.join(ROOT, 'assets/store', rel);
  emit(store('play-icon-512.png'), await sharp(await onSolid(512, 0.86, square)).ensureAlpha().png({ compressionLevel: 9 }).toBuffer());
  const FW = 1024;
  const FH = 500;
  const FL = 260;
  const feat = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${FW}" height="${FH}">
    <defs><radialGradient id="g" cx="0.25" cy="0.5" r="0.8"><stop offset="0%" stop-color="${CFG.ogGlow}"/><stop offset="100%" stop-color="#0a0a0a"/></radialGradient></defs>
    <rect width="${FW}" height="${FH}" fill="url(#g)"/>
    <text x="410" y="220" font-family="DejaVu Sans, Verdana, sans-serif" font-size="56" font-weight="700" fill="#ededed">${esc(CFG.name)}</text>
    ${CFG.ogLines.map((l, i) => `<text x="410" y="${280 + i * 38}" font-family="DejaVu Sans, Verdana, sans-serif" font-size="24" fill="#b4b4b4">${esc(l)}</text>`).join('')}
  </svg>`);
  emit(
    store('play-feature-1024x500.png'),
    await sharp(feat)
      .composite([{ input: await at(FL), left: 110, top: Math.round((FH - FL) / 2) }])
      .flatten({ background: '#0a0a0a' })
      .removeAlpha()
      .png({ compressionLevel: 9 })
      .toBuffer()
  );

  // --- Web app Flutter (/app/): favicon + icon PWA trong manifest.json của nó.
  const web = (rel) => path.join(ROOT, 'apps/app/web', rel);
  emit(web('favicon.png'), await png(32));
  for (const s of [192, 512]) {
    emit(web(`icons/Icon-${s}.png`), await png(s));
    emit(web(`icons/Icon-maskable-${s}.png`), await onSolid(s, 0.8, square));
  }

  // --- web /app/: apple-touch nền đặc (iOS tô đen chỗ trong suốt).
  emit(web('apple-touch-icon.png'), await onSolid(180, 0.86, square));

  // --- Icon app gốc (apps/app). Cùng ảnh gốc, cùng nền đặc.
  const app = (rel) => path.join(ROOT, 'apps/app', rel);
  const res = (rel) => app(`android/app/src/main/res/${rel}`);
  const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
  for (const [d, k] of Object.entries(dens)) {
    // Bản cũ (< Android 8): ô bo góc nền đặc, lề 1/12 như icon hệ thống.
    const legacy = Math.round(48 * k);
    emit(res(`mipmap-${d}/ic_launcher.png`), await padTo(legacy, Math.round(legacy * 0.84), await roundTile(Math.round(legacy * 0.84), 0.82)));
    // Adaptive 108dp: logo trong vùng an toàn 66dp (61%).
    const fg = Math.round(108 * k);
    const inner = Math.round(fg * 0.61);
    emit(res(`mipmap-${d}/ic_launcher_foreground.png`), await padTo(fg, inner, await at(inner, square)));
    // Monochrome (icon theo chủ đề, Android 13+): giữ alpha, tô trắng.
    const mono = await sharp(await at(inner, square)).ensureAlpha().linear(0, 255).png().toBuffer();
    emit(res(`mipmap-${d}/ic_launcher_monochrome.png`), await padTo(fg, inner, mono));
  }
  emit(
    res('mipmap-anydpi-v26/ic_launcher.xml'),
    Buffer.from(`<?xml version="1.0" encoding="utf-8"?>
<!-- SINH bởi apps/site/scripts/brand-assets.mjs - không sửa tay. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
`)
  );
  emit(
    res('values/ic_launcher_background.xml'),
    Buffer.from(`<?xml version="1.0" encoding="utf-8"?>
<!-- SINH bởi apps/site/scripts/brand-assets.mjs từ assets/brand/brand.json (solidBg) - không sửa tay. -->
<resources>
    <color name="ic_launcher_background">${CFG.solidBg}</color>
</resources>
`)
  );
  // iOS: ảnh vuông đầy nền đặc, không alpha (App Store từ chối alpha); hệ thống tự bo góc.
  const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  const iosNames = JSON.parse(fs.readFileSync(app(`${iosDir}/Contents.json`), 'utf8')).images.map((i) => i.filename);
  for (const f of new Set(iosNames)) {
    const mm = /Icon-App-([\d.]+)x[\d.]+@(\d)x\.png/.exec(f);
    if (!mm) continue;
    emit(app(`${iosDir}/${f}`), await onSolid(Math.round(Number(mm[1]) * Number(mm[2])), 0.8, square));
  }
  // macOS: lưới Big Sur - ô bo góc 824/1024, logo trong ô.
  for (const s2 of [16, 32, 64, 128, 256, 512, 1024]) {
    const t = Math.round(s2 * (824 / 1024));
    emit(app(`macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${s2}.png`), await padTo(s2, t, await roundTile(t, 0.8)));
  }
  // Windows: .ico 7 lớp trong suốt.
  const winIco = await ico(rounded);
  emit(app('windows/runner/resources/app_icon.ico'), winIco);
  // Giao diện app + tệp xuất (PDF) + icon cửa sổ Linux: logo sản phẩm; logo tsudev chỉ cho khối nhà làm.
  emit(app('assets/brand/logo-qulythuchi-256.png'), await png(256));
  emit(app('assets/brand/logo-tsudev-128.png'), await png(128, tsudev));

  // --- Bộ đóng gói desktop (assets/brand/app/), dùng ở P10.
  const pack = (rel) => path.join(ROOT, 'assets/brand/app', rel);
  emit(pack(`${CFG.id}.ico`), winIco);
  const macTile = async (s2) => {
    const t = Math.round(s2 * (824 / 1024));
    return padTo(s2, t, await roundTile(t, 0.8));
  };
  emit(
    pack(`${CFG.id}.icns`),
    buildIcns([
      ['icp4', await macTile(16)],
      ['icp5', await macTile(32)],
      ['icp6', await macTile(64)],
      ['ic07', await macTile(128)],
      ['ic08', await macTile(256)],
      ['ic09', await macTile(512)],
      ['ic10', await macTile(1024)],
    ])
  );
  for (const s2 of [16, 24, 32, 48, 64, 128, 256, 512]) emit(pack(`linux/${CFG.id}-${s2}.png`), await png(s2));

  // --- Ghi hoặc kiểm.
  const bad = [];
  for (const [abs, buf] of outputs) {
    const rel = path.relative(ROOT, abs);
    if (CHECK) {
      if (!fs.existsSync(abs) || !fs.readFileSync(abs).equals(buf)) bad.push(rel);
      continue;
    }
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, buf);
    console.log(`  ${rel.padEnd(52)} ${(buf.length / 1024).toFixed(1)} kB`);
  }
  if (CHECK) {
    if (bad.length) {
      console.error(`brand-assets: ${bad.length} tệp lệch nguồn - chạy lại không có --check:\n  ${bad.join('\n  ')}`);
      process.exit(1);
    }
    console.log(`brand-assets: khớp nguồn (${outputs.size} tệp).`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
