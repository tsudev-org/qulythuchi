#!/usr/bin/env bash
# Tải tài nguyên web tự phục vụ (KHÔNG dùng CDN lúc chạy), kiểm checksum ghim. Chạy trước `flutter build web`.
#  - sodium.js (libsodium.js sumo 0.8.4): `sodium:update_web` tự kiểm sha512; thêm sha256 ghim ở đây.
#  - sqlite3.wasm của sqlite3.dart 3.9.2 (khớp phiên bản gói sqlite3 trong pubspec.lock).
set -euo pipefail
cd "$(dirname "$0")/.."

SODIUM_JS_SHA256='dedbeb3a33be1cf9d1b923832c5f188f990a6ed543f94eae366c5e73aed3c34e'
SQLITE_VERSION='3.9.2'
SQLITE_WASM_SHA256='e7451780e78c56ff864fe9317a0fbcd6aeb2e8de3beba7f5efd963202f7ec3d9'

locked=$(awk '/^  sqlite3:/{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
if [ "$locked" != "$SQLITE_VERSION" ]; then
  echo "pubspec.lock dùng sqlite3 $locked nhưng script ghim $SQLITE_VERSION - cập nhật SQLITE_* ở đây" >&2
  exit 1
fi

if ! echo "$SODIUM_JS_SHA256  web/sodium.js" | sha256sum -c --status - 2>/dev/null; then
  dart run sodium:update_web --sumo --no-edit-index
  echo "$SODIUM_JS_SHA256  web/sodium.js" | sha256sum -c -
fi

if ! echo "$SQLITE_WASM_SHA256  web/sqlite3.wasm" | sha256sum -c --status - 2>/dev/null; then
  tmp=$(mktemp)
  curl -sSfL -o "$tmp" "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE_VERSION}/sqlite3.wasm"
  echo "$SQLITE_WASM_SHA256  $tmp" | sha256sum -c -
  mv "$tmp" web/sqlite3.wasm
  chmod 644 web/sqlite3.wasm
fi
echo "Tài nguyên web sẵn sàng."
