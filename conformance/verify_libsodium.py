#!/usr/bin/env python3
"""Kiểm vector phong bì bằng libsodium CỦA HỆ ĐIỀU HÀNH (bản build độc lập với gói Dart).
Chạy: python3 -I conformance/verify_libsodium.py conformance/envelope-v1.json packages/core/lib/src/crypto/bip39_english.dart
"""
import ctypes, json, sys, hashlib, unicodedata
L = ctypes.CDLL('libsodium.so.23'); assert L.sodium_init() >= 0
L.sodium_version_string.restype = ctypes.c_char_p; print('phiên bản', L.sodium_version_string().decode())
v = json.load(open(sys.argv[1])); key = bytes.fromhex(v['keyHex']); import re; words = re.findall(r"^  '([a-z]+)',$", open(sys.argv[2]).read(), re.M); assert len(words) == 2048
for c in v['envelopes']:
    s = bytes.fromhex(c['sealedHex']); hdr = s[:4]; assert hdr == b'QT\x01\x01'
    nonce = s[4:28]; ct = s[28:]; assert nonce.hex() == v['nonceHex']
    aad = hdr + c['context'].encode()
    out = ctypes.create_string_buffer(len(ct)); olen = ctypes.c_ulonglong()
    rc = L.crypto_aead_xchacha20poly1305_ietf_decrypt(out, ctypes.byref(olen), None, ct, ctypes.c_ulonglong(len(ct)), aad, ctypes.c_ulonglong(len(aad)), nonce, key)
    assert rc == 0, c['name']
    ulen = ctypes.c_size_t()
    assert L.sodium_unpad(ctypes.byref(ulen), out, ctypes.c_size_t(olen.value), ctypes.c_size_t(c['padBlock'])) == 0
    assert out.raw[:ulen.value].hex() == c['plaintextHex'], c['name']
    assert olen.value % c['padBlock'] == 0
    bad = aad + b'x'
    assert L.crypto_aead_xchacha20poly1305_ietf_decrypt(out, ctypes.byref(olen), None, ct, ctypes.c_ulonglong(len(ct)), bad, ctypes.c_ulonglong(len(bad)), nonce, key) != 0
    print('ĐẠT phong bì', c['name'])
a = v['argon2id']; outk = ctypes.create_string_buffer(32)
pw = unicodedata.normalize('NFKC', a['passwordNfkc']).encode()
assert L.crypto_pwhash(outk, ctypes.c_ulonglong(32), pw, ctypes.c_ulonglong(len(pw)), bytes.fromhex(a['saltHex']), ctypes.c_ulonglong(a['ops']), ctypes.c_size_t(a['mem']), ctypes.c_int(2)) == 0
assert outk.raw.hex() == a['keyHex']; print('ĐẠT argon2id')
r = v['recoveryKdf']
assert L.crypto_kdf_derive_from_key(outk, ctypes.c_size_t(32), ctypes.c_uint64(r['subkeyId']), r['context'].encode(), bytes.fromhex(r['entropyHex'])) == 0
assert outk.raw.hex() == r['keyHex']; print('ĐẠT kdf khôi phục')
ent = bytes.fromhex(r['entropyHex']); bits = ''.join(f'{b:08b}' for b in ent) + f'{hashlib.sha256(ent).digest()[0]:08b}'
assert [words[int(bits[i*11:i*11+11], 2)] for i in range(24)] == r['words']; print('ĐẠT BIP39')
# Ví chung (ADR-0015): bằng chứng nhận lời mời + KEK chia sẻ + phong bì swk. X-Wing không kiểm ở đây (1.0.18 chưa có).
s = v['sharing']; psk = bytes.fromhex(s['pairSecretHex'])
def b2b(msg, key):
    o = ctypes.create_string_buffer(32)
    assert L.crypto_generichash(o, ctypes.c_size_t(32), msg, ctypes.c_ulonglong(len(msg)), key, ctypes.c_size_t(len(key))) == 0
    return o.raw
seqb = lambda n, st: bytes((st + i) & 0xff for i in range(n))
pk = seqb(s['kemPublicKeyBytes'], s['kemPublicKeyStart']); ct = seqb(s['kemCiphertextBytes'], s['kemCiphertextStart'])
assert b2b(f"QTINV1|{s['walletId']}|{s['inviteId']}|".encode() + pk, psk).hex() == s['proofHex']; print('ĐẠT bằng chứng mời')
kek = b2b(b'QTSHARE2' + bytes.fromhex(s['sharedSecretHex']) + ct, psk)
blob = bytes.fromhex(s['shareBlobHex']); assert blob[:3] == b'QS\x01' and blob[3:3 + len(ct)] == ct
env = blob[3 + len(ct):]; assert env[:4] == b'QT\x01\x01'
aad = env[:4] + f"swk|{s['walletId']}|{s['version']}".encode(); n2 = env[4:28]; c2 = env[28:]
out = ctypes.create_string_buffer(len(c2)); olen = ctypes.c_ulonglong()
assert L.crypto_aead_xchacha20poly1305_ietf_decrypt(out, ctypes.byref(olen), None, c2, ctypes.c_ulonglong(len(c2)), aad, ctypes.c_ulonglong(len(aad)), n2, kek) == 0
ulen = ctypes.c_size_t(); assert L.sodium_unpad(ctypes.byref(ulen), out, ctypes.c_size_t(olen.value), ctypes.c_size_t(16)) == 0
assert out.raw[:ulen.value].hex() == s['walletKeyHex']; print('ĐẠT chia sẻ khóa ví')
