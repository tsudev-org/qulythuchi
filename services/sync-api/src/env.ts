export interface Env {
  DB: D1Database;
  /** Tệp đính kèm đã mã hóa ở máy khách. */
  FILES: R2Bucket;
  PUBLIC_ORIGIN: string;
  OIDC_ISSUER: string;
  OIDC_CLIENT_ID: string;
  /** HMAC ký access token của app. >= 32 ký tự ngẫu nhiên, `wrangler secret put`. */
  SESSION_SECRET: string;
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
