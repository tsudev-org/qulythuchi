import type { Context } from 'hono';

import type { AppEnv } from '../env';
import { sha256Hex } from './crypto';

export function clientIp(c: Context<AppEnv>): string {
  // CF-Connecting-IP do Cloudflare đặt; X-Forwarded-For do người gửi đặt được nên KHÔNG đọc.
  return c.req.header('CF-Connecting-IP') ?? 'unknown';
}

async function ipHash(c: Context<AppEnv>): Promise<string> {
  return (await sha256Hex(`${c.env.IP_HASH_SALT}:${clientIp(c)}`)).slice(0, 32);
}

/** Ghi sự kiện bảo mật. `detail` chỉ là id kỹ thuật - không bao giờ dữ liệu D3. */
export async function audit(c: Context<AppEnv>, userId: string | null, event: string, detail?: string) {
  await c.env.DB.prepare('INSERT INTO audit_log (user_id, event, detail, ip_hash, at) VALUES (?, ?, ?, ?, ?)')
    .bind(userId, event, detail ?? null, await ipHash(c), Date.now())
    .run();
}
