import { defineConfig } from 'astro/config';

// Trang tĩnh. Script phía trình duyệt là tệp cùng nguồn (CSP script-src 'self'), không nội tuyến:
// assetsInlineLimit 0 để Vite không nhét script/CSS nhỏ vào HTML. Web app Flutter KHÔNG do Astro dựng: gom vào
// dist/app/ sau khi build (scripts/gom-app.mjs).
export default defineConfig({
  site: 'https://qulythuchi.tsudev.com',
  trailingSlash: 'always',
  compressHTML: true,
  build: { format: 'directory', inlineStylesheets: 'never' },
  vite: { build: { assetsInlineLimit: 0 } },
});
