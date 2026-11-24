// Hoạ tiết chữ ký `cot-tang-truong` của Quly Thu Chi (tsudev-standards v5.0.0, DESIGN_SYSTEM.md mục 1.2.4): các cột
// tăng dần như biểu đồ tiết kiệm lớn lên. TĨNH, tô bằng `accent` với độ mờ ĐỘ_PHỦ (≤ 15%) để chữ đè lên vẫn đủ tương
// phản. Một hình học dùng chung cho hero website (CotTangTruong.astro) và og-image (scripts/brand-assets.mjs); app
// Flutter chép đúng công thức ở apps/app/lib/ui/widgets/cot_tang_truong.dart.

const SO_COT = 9;
export const DO_PHU = 0.12;

/** Các cột trong khung rong x cao: chiều cao tăng dần từ 22% tới 100%, cột chiếm 62% bước, đỉnh bo góc. */
function cotTangTruong(rong, cao, soCot = SO_COT) {
  const buoc = rong / soCot;
  const be = buoc * 0.62;
  const cot = [];
  for (let i = 0; i < soCot; i++) {
    const h = cao * (0.22 + 0.78 * Math.pow(i / (soCot - 1), 1.15));
    cot.push({ x: +(i * buoc + (buoc - be) / 2).toFixed(2), y: +(cao - h).toFixed(2), w: +be.toFixed(2), h: +h.toFixed(2) });
  }
  return cot;
}

/** Chuỗi <rect> SVG (dùng chung web + og-image). */
export function cotSvg(rong, cao, { mau = 'currentColor', bo = 6, soCot = SO_COT, dx = 0, dy = 0 } = {}) {
  return cotTangTruong(rong, cao, soCot)
    .map((c) => `<rect x="${(c.x + dx).toFixed(2)}" y="${(c.y + dy).toFixed(2)}" width="${c.w}" height="${c.h}" rx="${bo}" fill="${mau}"/>`)
    .join('');
}
