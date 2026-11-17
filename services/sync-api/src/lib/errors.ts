import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

/**
 * Lỗi API: `code` máy đọc được + `message` tiếng Việt hiện thẳng ra giao diện (AUTH_AND_ACCOUNT.md mục 15).
 * Thông điệp là câu cố định - KHÔNG BAO GIỜ nhúng dữ liệu người dùng (D3) vào đây.
 */
export class ApiError extends Error {
  constructor(
    readonly status: ContentfulStatusCode,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export function errorResponse(c: Context, err: ApiError) {
  return c.json({ code: err.code, message: err.message }, err.status);
}

export const badRequest = (message = 'Yêu cầu không hợp lệ.') => new ApiError(400, 'invalid_request', message);
