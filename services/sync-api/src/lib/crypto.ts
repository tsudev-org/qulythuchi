const encoder = new TextEncoder();

export function randomToken(bytes = 32): string {
  const buf = new Uint8Array(bytes);
  crypto.getRandomValues(buf);
  return base64Url(buf);
}

function base64Url(data: Uint8Array): string {
  return base64(data).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function base64(data: Uint8Array): string {
  let s = '';
  for (const b of data) s += String.fromCharCode(b);
  return btoa(s);
}

const B64 = /^[A-Za-z0-9+/]*={0,2}$/;

/** Giải base64 chuẩn (có đệm). Trả null nếu sai định dạng - không ném lỗi chứa dữ liệu vào. */
export function fromBase64(value: string): Uint8Array | null {
  if (value.length % 4 !== 0 || !B64.test(value)) return null;
  try {
    const s = atob(value);
    const out = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i);
    return out;
  } catch {
    return null;
  }
}

function hex(buf: ArrayBuffer): string {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function sha256Hex(value: string | Uint8Array): Promise<string> {
  const bytes = typeof value === 'string' ? encoder.encode(value) : value;
  return hex(await crypto.subtle.digest('SHA-256', bytes));
}

/** PKCE S256: BASE64URL(SHA256(verifier)). */
export async function pkceChallenge(verifier: string): Promise<string> {
  return base64Url(new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(verifier))));
}

/** So sánh thời gian hằng cho hai chuỗi cùng nguồn gốc (băm, challenge). */
export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
