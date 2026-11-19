import { Hono } from 'hono';

import { blockIfDeleting, requireUser } from '../auth/middleware';
import type { AppEnv } from '../env';
import { badRequest, ApiError } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { ENVELOPE_HEADER, ENVELOPE_OVERHEAD, UUID } from '../lib/validate';
import { requirePro } from '../pro/entitlements';

/**
 * Tệp đính kèm (ảnh hóa đơn...) ĐÃ mã hóa ở máy khách (phong bì v1, khối đệm 4096 - ADR-0007).
 * Đi xuyên Worker thay vì URL ký trước của R2 (ADR-0010 mục 4): quyền kiểm ở MỌI lượt tải, không cần cấp khóa S3.
 * Khóa R2: `u/<user_id>/<file_id>` - không thể đọc chéo tài khoản vì user_id lấy từ phiên, không từ URL.
 */
export const MAX_FILE_BYTES = 10 * 1024 * 1024;
export const ACCOUNT_FILE_QUOTA = 1024 * 1024 * 1024;
const FILE_MIN_PADDED = 4096;

export const filesRoutes = new Hono<AppEnv>();

filesRoutes.use('/api/v1/files/*', requireUser, blockIfDeleting);

const objectKey = (userId: string, id: string) => `u/${userId}/${id}`;

function fileId(raw: string): string {
  if (!UUID.test(raw)) throw badRequest('Mã tệp không hợp lệ.');
  return raw;
}

// Tải tệp lên cần TsuDEV Pro (ADR-0016); tải về/xoá luôn mở.
filesRoutes.put('/api/v1/files/:id', requirePro, async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  await rateLimit(c.env.DB, `files-w:${userId}`, 60, 60_000);
  const walletId = c.req.query('wallet_id') ?? null;
  if (walletId !== null && !UUID.test(walletId)) throw badRequest('Mã ví không hợp lệ.');
  const declared = Number(c.req.header('Content-Length'));
  if (!Number.isInteger(declared) || declared <= 0) throw new ApiError(411, 'length_required', 'Thiếu kích thước tệp.');
  if (declared > MAX_FILE_BYTES) throw new ApiError(413, 'too_large', 'Tệp quá lớn (tối đa 10 MB).');
  if (declared < ENVELOPE_OVERHEAD + FILE_MIN_PADDED) throw badRequest('Tệp không phải bản mã hợp lệ.');

  const existing = await c.env.DB.prepare('SELECT size FROM files WHERE user_id = ? AND id = ?')
    .bind(userId, id)
    .first<{ size: number }>();
  // Tệp đính kèm là bất biến (nội dung đổi = tệp mới): tải lại cùng id là lũy đẳng, không ghi đè.
  if (existing) return c.json({ id, size: existing.size, status: 'unchanged' });
  const used = await c.env.DB.prepare('SELECT COALESCE(SUM(size), 0) AS bytes FROM files WHERE user_id = ?')
    .bind(userId)
    .first<{ bytes: number }>();
  if ((used?.bytes ?? 0) + declared > ACCOUNT_FILE_QUOTA) {
    throw new ApiError(507, 'quota', 'Đã hết dung lượng tệp đính kèm của tài khoản.');
  }

  const body = new Uint8Array(await c.req.arrayBuffer());
  if (body.length !== declared || !ENVELOPE_HEADER.every((b, i) => body[i] === b)) {
    throw badRequest('Tệp không phải bản mã hợp lệ.');
  }
  await c.env.FILES.put(objectKey(userId, id), body, {
    httpMetadata: { contentType: 'application/octet-stream' },
  });
  await c.env.DB.prepare('INSERT INTO files (user_id, id, wallet_id, size, created_at) VALUES (?, ?, ?, ?, ?)')
    .bind(userId, id, walletId, body.length, Date.now())
    .run();
  return c.json({ id, size: body.length, status: 'stored' }, 201);
});

filesRoutes.get('/api/v1/files/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  await rateLimit(c.env.DB, `files-r:${userId}`, 300, 60_000);
  const row = await c.env.DB.prepare('SELECT size FROM files WHERE user_id = ? AND id = ?').bind(userId, id).first();
  const obj = row ? await c.env.FILES.get(objectKey(userId, id)) : null;
  if (!obj) throw new ApiError(404, 'not_found', 'Không tìm thấy tệp.');
  return new Response(obj.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Length': String(obj.size),
      'Content-Disposition': 'attachment',
      'Cache-Control': 'private, no-store',
    },
  });
});

filesRoutes.delete('/api/v1/files/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = fileId(c.req.param('id'));
  const row = await c.env.DB.prepare('DELETE FROM files WHERE user_id = ? AND id = ? RETURNING id').bind(userId, id).first();
  if (row) await c.env.FILES.delete(objectKey(userId, id));
  return c.body(null, 204);
});
