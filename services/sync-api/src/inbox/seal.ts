import { blake2b } from '@noble/hashes/blake2.js';
import nacl from 'tweetnacl';

/**
 * `crypto_box_seal` của libsodium (định dạng: khóa công khai tạm ‖ crypto_box(m, nonce, pk, esk), nonce =
 * BLAKE2b-192(epk ‖ pk)) - đúng thứ app mở bằng `KeyHierarchy.openSealedEmail`.
 *
 * Vì sao không dùng libsodium.js: workerd cấm biên dịch WASM động. `nacl.box` của tweetnacl (thuần JS, đã kiểm định)
 * CHÍNH LÀ `crypto_box` (X25519 + HSalsa20 + XSalsa20-Poly1305); phần ghép duy nhất là nonce theo đúng đặc tả của
 * libsodium. Tương thích được kiểm hai chiều với libsodium hệ thống: `test/fixtures/sealed-box-v1.json`
 * (`scripts/gen-sealed-vector.py`). Không tự chế nguyên hàm mật mã (AGENTS.md B.5, ADR-0012).
 */
const SEAL_OVERHEAD = nacl.box.publicKeyLength + nacl.box.overheadLength; // 48

function sealNonce(epk: Uint8Array, pk: Uint8Array): Uint8Array {
  const input = new Uint8Array(epk.length + pk.length);
  input.set(epk, 0);
  input.set(pk, epk.length);
  return blake2b(input, { dkLen: nacl.box.nonceLength });
}

export function sealFor(publicKey: Uint8Array, plaintext: Uint8Array): Uint8Array {
  if (publicKey.length !== nacl.box.publicKeyLength) throw new Error('bad_public_key');
  const eph = nacl.box.keyPair();
  try {
    const box = nacl.box(plaintext, sealNonce(eph.publicKey, publicKey), publicKey, eph.secretKey);
    const out = new Uint8Array(eph.publicKey.length + box.length);
    out.set(eph.publicKey, 0);
    out.set(box, eph.publicKey.length);
    return out;
  } finally {
    eph.secretKey.fill(0);
  }
}

/** Chỉ dùng trong test (máy chủ không bao giờ có khóa bí mật của người dùng). */
export function openSealed(sealed: Uint8Array, publicKey: Uint8Array, secretKey: Uint8Array): Uint8Array | null {
  if (sealed.length < SEAL_OVERHEAD) return null;
  const epk = sealed.subarray(0, nacl.box.publicKeyLength);
  return nacl.box.open(sealed.subarray(nacl.box.publicKeyLength), sealNonce(epk, publicKey), epk, secretKey);
}
