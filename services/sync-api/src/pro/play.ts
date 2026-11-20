import type { Env } from '../env';
import { idpFetch } from '../auth/oidc';
import { ApiError } from '../lib/errors';
import { clientAssertion } from './entitlements';

/**
 * Chuyển biên nhận Google Play lên máy chủ quyền lợi tsudev.com (ADR-0016 mục 2.4, ADR-0019 mục 4).
 *
 * Máy chủ này KHÔNG xác minh biên nhận (PRODUCT_POLICY 7.4: chỉ tsudev.com xác minh) - chỉ kiểm hình dạng, gắn đúng
 * `sub` của người đang đăng nhập rồi chuyển tiếp bằng client assertion (`aud` = đúng URL kênh). Mã mua là bí mật
 * ngắn hạn: không ghi log, không lưu D1.
 */

/** Định danh cửa hàng của hợp đồng chung (PRODUCT_POLICY 7.4) - KHÔNG có `thang`. */
export const PLAY_PRODUCTS = new Set(['tsudev_pro', 'ung_ho_20k', 'ung_ho_50k', 'ung_ho_100k', 'ung_ho_200k']);
export const PLAY_PACKAGE = 'com.tsudev.qulythuchi';
const TOKEN_RE = /^[A-Za-z0-9._:-]{16,4096}$/;
const TIMEOUT_MS = 15_000;

export const playReceiptUrl = (env: Env) => `${env.ENTITLEMENTS_URL}/play`;

export const purchaseUnavailable = () =>
  new ApiError(503, 'purchase_unavailable', 'Chưa xác nhận được giao dịch lúc này. Giao dịch được giữ lại và thử lại sau.');
export const purchaseInvalid = () => new ApiError(400, 'purchase_invalid', 'Giao dịch không hợp lệ.');

export function validPlayReceipt(productId: unknown, token: unknown): productId is string {
  return typeof productId === 'string' && PLAY_PRODUCTS.has(productId) && typeof token === 'string' && TOKEN_RE.test(token);
}

/**
 * Gửi `{sub, packageName, productId, purchaseToken}` tới `POST <ENTITLEMENTS_URL>/play`.
 * - 200 ⇒ tsudev.com đã xác minh + acknowledge ⇒ app mới được hoàn tất giao dịch.
 * - 400/422 ⇒ `purchase_invalid` (app KHÔNG hoàn tất - Play tự hoàn tiền giao dịch không được xác nhận).
 * - Còn lại ⇒ `purchase_unavailable` - app giữ giao dịch, thử lại: 409 `purchase_pending` (đang chờ thanh toán, tsudev
 *   ADR-0002 mục 2), 503 `play_unavailable` (gửi lại an toàn, sổ cái idempotent ⇒ 200 `already_recorded`),
 *   401/403/404/405/429/5xx, mạng, hết giờ.
 */
export async function forwardPlayReceipt(env: Env, sub: string, productId: string, purchaseToken: string): Promise<void> {
  const url = playReceiptUrl(env);
  let res: Response;
  try {
    res = await idpFetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${await clientAssertion(env, url)}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ client_id: env.OIDC_CLIENT_ID, sub, packageName: PLAY_PACKAGE, productId, purchaseToken }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  } catch (e) {
    if (e instanceof ApiError) throw purchaseUnavailable();
    console.error('play_receipt', e instanceof Error ? e.name : 'error');
    throw purchaseUnavailable();
  }
  if (res.ok) return;
  if (res.status === 400 || res.status === 422) throw purchaseInvalid();
  console.error('play_receipt', res.status);
  throw purchaseUnavailable();
}
