/** Kiểm định dạng dùng chung - khớp `packages/core` (SyncRecord, Envelope). */

/** UUID chữ thường (máy khách sinh UUID v4 - ADR-0002 mục 2). */
export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** Loại bản ghi: khớp `SyncRecord._typePattern`. */
export const RECORD_TYPE = /^[a-z][a-z_]{1,31}$/;

/** Phong bì v1: 'Q' 'T' 01 01 ‖ nonce 24 ‖ bản mã + thẻ 16 (ADR-0007 mục 5). */
export const ENVELOPE_HEADER = [0x51, 0x54, 0x01, 0x01] as const;
export const ENVELOPE_OVERHEAD = 4 + 24 + 16;

/** true nếu [bytes] mang đầu phong bì phiên bản máy chủ biết và đủ dài cho khối đệm tối thiểu. */
export function isEnvelope(bytes: Uint8Array, minPadded: number): boolean {
  if (bytes.length < ENVELOPE_OVERHEAD + minPadded) return false;
  return ENVELOPE_HEADER.every((b, i) => bytes[i] === b);
}
