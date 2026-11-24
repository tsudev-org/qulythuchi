/**
 * Danh sách cho phép đích quay về của APP (so khớp tuyệt đối, không tiền tố) - ADR-0003:
 * - `com.tsudev.qulythuchi:/auth/callback` - Android, iOS.
 * - `http://127.0.0.1:<cổng>/callback` - Windows, macOS, Linux (RFC 8252 mục 7.3: cổng vòng lặp do hệ điều hành cấp
 *   nên được tự do, mọi phần khác khớp tuyệt đối).
 * Phải khớp cấu hình đăng nhập của `apps/app` (P6).
 */
const APP_SCHEME_REDIRECT = 'com.tsudev.qulythuchi:/auth/callback';

export function isAllowedAppRedirect(value: string): boolean {
  if (value === APP_SCHEME_REDIRECT) return true;
  const m = /^http:\/\/127\.0\.0\.1:(\d{1,5})\/callback$/.exec(value);
  if (!m) return false;
  const port = Number(m[1]);
  return port >= 1024 && port <= 65535;
}

const DEFAULT_RETURN_TO = '/app/';

/** Đích nội bộ sau đăng nhập web: chỉ đường dẫn tương đối cùng gốc (chống open redirect). */
export function safeReturnTo(value: string | undefined | null): string {
  if (!value?.startsWith('/') || value.startsWith('//') || value.includes('\\') || /[\r\n\t]/.test(value)) {
    return DEFAULT_RETURN_TO;
  }
  return value.length > 256 ? DEFAULT_RETURN_TO : value;
}
