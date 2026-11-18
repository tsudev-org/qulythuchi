#!/usr/bin/env python3
"""Sinh vector đối chiếu crypto_box_seal bằng libsodium HỆ THỐNG (độc lập với mã TypeScript của Worker).

Chạy: python3 scripts/gen-sealed-vector.py > test/fixtures/sealed-box-v1.json
Kiểm ngược (bản niêm phong do Worker tạo, mở bằng libsodium): python3 scripts/gen-sealed-vector.py --open <json>
Khóa trong vector chỉ dùng cho test.
"""
import base64
import ctypes
import ctypes.util
import json
import sys

lib = ctypes.CDLL(ctypes.util.find_library("sodium"))
assert lib.sodium_init() >= 0
PK, SK, SEAL = 32, 32, 48
b64 = lambda b: base64.b64encode(bytes(b)).decode()


def open_sealed(pk: bytes, sk: bytes, sealed: bytes) -> bytes:
    out = ctypes.create_string_buffer(len(sealed) - SEAL)
    if lib.crypto_box_seal_open(out, sealed, ctypes.c_ulonglong(len(sealed)), pk, sk) != 0:
        raise SystemExit("libsodium: không mở được")
    return out.raw


if len(sys.argv) == 3 and sys.argv[1] == "--open":
    v = json.load(open(sys.argv[2]))
    print(open_sealed(base64.b64decode(v["pk"]), base64.b64decode(v["sk"]), base64.b64decode(v["sealed"])).decode())
    sys.exit(0)

pk, sk = ctypes.create_string_buffer(PK), ctypes.create_string_buffer(SK)
lib.crypto_box_keypair(pk, sk)
msg = json.dumps({"v": 1, "from": "a@b.example", "subject": "Biến động", "text": "GD: -50,000VND"}, ensure_ascii=False).encode()
sealed = ctypes.create_string_buffer(len(msg) + SEAL)
lib.crypto_box_seal(sealed, msg, ctypes.c_ulonglong(len(msg)), pk.raw)
assert open_sealed(pk.raw, sk.raw, sealed.raw) == msg
print(json.dumps({"description": "crypto_box_seal từ libsodium hệ thống - chỉ dùng cho test", "pk": b64(pk.raw),
                  "sk": b64(sk.raw), "message": msg.decode(), "sealed": b64(sealed.raw)}, ensure_ascii=False, indent=2))
