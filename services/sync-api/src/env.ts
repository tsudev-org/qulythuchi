export interface Env {
  DB: D1Database;
  /** Tệp đính kèm đã mã hóa ở máy khách. */
  FILES: R2Bucket;
  PUBLIC_ORIGIN: string;
  OIDC_ISSUER: string;
  OIDC_CLIENT_ID: string;
  /** Miền nhận email chuyển tiếp (Email Routing catch-all ⇒ Worker này), ví dụ `in.qulythuchi.tsudev.com`. */
  INBOX_DOMAIN: string;
  /** HMAC ký access token của app. >= 32 ký tự ngẫu nhiên, `wrangler secret put`. */
  SESSION_SECRET: string;
  /**
   * Kênh RP của máy chủ quyền lợi tsudev.com (PRODUCT_POLICY 7.4), ví dụ `https://tsudev.com/api/rp/entitlements`.
   * Cũng là `aud` của client assertion.
   */
  ENTITLEMENTS_URL: string;
  /**
   * `on` ⇒ gate Pro (402 `pro_required`) + dọn bản mã khi Pro hết hạn quá 90 ngày. `off` ⇒ không gọi tsudev.com, không
   * chặn (trước khi chủ dự án đồng ý xoá dữ liệu thử nghiệm và khoá RP được đăng ký). ADR-0016.
   */
  PRO_ENFORCE: string;
  /** Khoá riêng EC P-256 (JWK có `d`) ký client assertion kênh RP, `wrangler secret put`. Thiếu ⇒ không lấy được quyền lợi. */
  RP_PRIVATE_JWK?: string;
  /** Muối băm IP trong nhật ký, `wrangler secret put`. */
  IP_HASH_SALT: string;
}

export interface AuthContext {
  userId: string;
  deviceId: string;
  via: 'bearer' | 'cookie';
  /** Đã yêu cầu xóa tài khoản, đang trong ân hạn 30 ngày. */
  pendingDeletion: boolean;
}

export interface AppEnv {
  Bindings: Env;
  Variables: { auth: AuthContext };
}
