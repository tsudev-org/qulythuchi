import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

export default defineConfig(async () => {
  const migrations = await readD1Migrations('./migrations');
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: './wrangler.test.jsonc' },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            // Giá trị GIẢ chỉ dùng cho test, không phải bí mật thật.
            SESSION_SECRET: 'test-only-session-secret-0123456789abcdef',
            IP_HASH_SALT: 'test-only-salt',
            PUBLIC_ORIGIN: 'https://qulythuchi.tsudev.com',
            // Dọn dẹp nền ngẫu nhiên (1% yêu cầu) từng chạy purgeLapsedPro chen vào test Pro ⇒ chập chờn. Tắt trong test;
            // các ca dọn dẹp gọi thẳng cleanup()/purge*().
            CLEANUP_SAMPLE_RATE: '0',
          },
        },
      }),
    ],
    test: { setupFiles: ['./test/apply-migrations.ts'], testTimeout: 20_000 },
  };
});
