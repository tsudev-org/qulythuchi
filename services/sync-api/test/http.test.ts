import { describe, expect, it } from 'vitest';

import { call, login } from './helpers';

describe('HTTP', () => {
  it('header bảo mật trên phản hồi API', async () => {
    const res = await call('/api/v1/health');
    expect(res.status).toBe(200);
    for (const [k, v] of [
      ['Cache-Control', 'no-store'],
      ['X-Content-Type-Options', 'nosniff'],
      ['X-Frame-Options', 'DENY'],
      ['Referrer-Policy', 'no-referrer'],
      ['Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'"],
    ]) {
      expect(res.headers.get(k!), k).toBe(v);
    }
    expect(res.headers.get('Strict-Transport-Security')).toMatch(/max-age=63072000/);
  });

  it('CORS chỉ cho đúng gốc qulythuchi.tsudev.com', async () => {
    const pre = (origin: string) =>
      call('/api/v1/sync/pull', { method: 'OPTIONS', headers: { Origin: origin, 'Access-Control-Request-Method': 'GET' } });
    expect((await pre('https://qulythuchi.tsudev.com')).headers.get('Access-Control-Allow-Origin')).toBe('https://qulythuchi.tsudev.com');
    expect((await pre('https://evil.example')).headers.get('Access-Control-Allow-Origin')).toBeNull();
  });

  it('Worker không tự sinh trang HTML: / là tệp tĩnh (Static Assets, ADR-0013) ⇒ tới Worker chỉ còn JSON 404', async () => {
    const res = await call('/');
    expect(res.status).toBe(404);
    expect(res.headers.get('Content-Type')).toMatch(/application\/json/);
    expect(res.headers.get('Content-Security-Policy')).toBe("default-src 'none'; frame-ancestors 'none'");
  });

  it('404 trả mã máy đọc + thông điệp tiếng Việt, body quá lớn ⇒ 413', async () => {
    const res = await call('/khong-co');
    expect(res.status).toBe(404);
    expect(await res.json()).toEqual({ code: 'not_found', message: 'Không tìm thấy.' });
    const { auth } = await login();
    const big = await call('/api/v1/sync/push', {
      method: 'POST',
      headers: { ...auth, 'content-type': 'application/json' },
      body: JSON.stringify({ records: [], pad: 'x'.repeat(5 * 1024 * 1024) }),
    });
    expect(big.status).toBe(413);
    expect(((await big.json()) as any).code).toBe('too_large');
  });
});
