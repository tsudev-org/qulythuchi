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
          },
        },
      }),
    ],
    test: { setupFiles: ['./test/apply-migrations.ts'] },
  };
});
