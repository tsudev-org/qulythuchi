import { Hono, type Context } from 'hono';
import { cors } from 'hono/cors';
import { HTTPException } from 'hono/http-exception';

import { authRoutes } from './auth/routes';
import type { AppEnv, Env } from './env';
import { filesRoutes } from './files/routes';
import { handleEmail } from './inbox/email';
import { inboxRoutes } from './inbox/routes';
import { keysRoutes } from './keys/routes';
import { ApiError, errorResponse } from './lib/errors';
import { cleanup } from './maintenance';
import { meRoutes } from './me/routes';
import { homeCsp, homePage } from './home';
import { syncRoutes } from './sync/routes';

const app = new Hono<AppEnv>();

// Header bảo mật cho mọi phản hồi (SECURITY_BASELINE.md mục 7.2). Phản hồi API mặc định không cache.
app.use('*', async (c, next) => {
  await next();
  if (c.req.path.startsWith('/api/') && Math.random() < 0.01) {
    c.executionCtx.waitUntil(cleanup(c.env).catch((e: unknown) => { console.error('cleanup', e instanceof Error ? e.name : 'error'); }));
  }
  const h = c.res.headers;
  if (!h.has('Cache-Control')) h.set('Cache-Control', 'no-store');
  h.set('X-Content-Type-Options', 'nosniff');
  h.set('Referrer-Policy', 'no-referrer');
  h.set('X-Frame-Options', 'DENY');
  h.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  h.set('Cross-Origin-Resource-Policy', 'same-origin');
  h.set('Cross-Origin-Opener-Policy', 'same-origin');
  h.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()');
  if (!h.has('Content-Security-Policy')) h.set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
});

// CORS: chỉ đúng gốc của web app. App gốc (Android/desktop) không chịu CORS; gốc khác không nhận header cho phép.
app.use(
  '/api/*',
  cors({
    origin: (origin, c: Context<AppEnv>) => (origin === c.env.PUBLIC_ORIGIN ? origin : null),
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowHeaders: ['Content-Type', 'Authorization', 'X-Qt-Csrf'],
    credentials: true,
    maxAge: 600,
  }),
);

app.get('/api/v1/health', (c) => c.json({ ok: true, service: 'qulythuchi-sync-api', time: new Date().toISOString() }));

app.route('/', authRoutes);
app.route('/', syncRoutes);
app.route('/', keysRoutes);
app.route('/', filesRoutes);
app.route('/', meRoutes);
app.route('/', inboxRoutes);

// Trang chủ tạm cho tới P8 (site Astro + web app tại /app).
app.get('/', async (c) =>
  c.html(homePage(), 200, { 'Content-Security-Policy': await homeCsp(), 'Cache-Control': 'public, max-age=300' }),
);

app.notFound((c) => c.json({ code: 'not_found', message: 'Không tìm thấy.' }, 404));

app.onError((err, c) => {
  if (err instanceof ApiError) return errorResponse(c, err);
  if (err instanceof HTTPException) {
    return c.json(
      { code: err.status === 413 ? 'too_large' : 'http_error', message: err.status === 413 ? 'Dữ liệu gửi lên quá lớn.' : 'Yêu cầu không hợp lệ.' },
      err.status,
    );
  }
  // Chỉ ghi tên lớp lỗi: thông điệp/stack có thể chứa dữ liệu yêu cầu (D3).
  console.error('unhandled', err.name);
  return c.json({ code: 'internal', message: 'Máy chủ gặp lỗi. Hãy thử lại sau.' }, 500);
});

export default {
  fetch: app.fetch,
  // Email chuyển tiếp niêm phong (ADR-0012). Lỗi ⇒ từ chối thư (người gửi nhận thư báo lỗi), không ghi nội dung.
  async email(message, env) {
    try {
      await handleEmail(message, env);
    } catch (e) {
      console.error('email', e instanceof Error ? e.name : 'error');
      message.setReject('Temporary failure');
    }
  },
} satisfies ExportedHandler<Env>;
