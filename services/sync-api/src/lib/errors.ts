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
    /** Trường máy đọc thêm (ví dụ `reason` của 402). Chỉ giá trị cố định, không dữ liệu người dùng. */
    readonly extra?: Record<string, string>,
  ) {
    super(message);
  }
}

export function errorResponse(c: Context, err: ApiError) {
  // 402: hợp đồng chung PRODUCT_POLICY 7.4 đòi `{"error":"pro_required"}`; giữ thêm code/message như mọi lỗi khác.
  const contract = err.status === 402 ? { error: err.code } : {};
  return c.json({ ...contract, code: err.code, message: err.message, ...err.extra }, err.status);
}

export const badRequest = (message = 'Yêu cầu không hợp lệ.') => new ApiError(400, 'invalid_request', message);
