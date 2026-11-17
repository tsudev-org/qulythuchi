#!/usr/bin/env bash
# Sinh lib/sync/pinned_roots.g.dart: tập CA gốc mà Cloudflare dùng cho qulythuchi.tsudev.com (ADR-0003, ADR-0011).
# App CHỈ tin các CA này khi gọi máy chủ đồng bộ (ghim gốc tin cậy). Nguồn: kho CA của hệ điều hành (ca-certificates).
# Chạy lại khi Cloudflare đổi tập CA; mỗi lần đổi phải ra bản app mới và cập nhật bảng SPKI trong ADR-0011.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=${CA_DIR:-/etc/ssl/certs}
ROOTS=(
  ISRG_Root_X1 ISRG_Root_X2                                   # Let's Encrypt
  GTS_Root_R1 GTS_Root_R3 GTS_Root_R4                         # Google Trust Services (hiện tại: WE1 <- GTS Root R4)
  SSL.com_TLS_RSA_Root_CA_2022 SSL.com_TLS_ECC_Root_CA_2022   # SSL.com
  SSL.com_Root_Certification_Authority_RSA SSL.com_Root_Certification_Authority_ECC
  GlobalSign_Root_R46 GlobalSign_Root_E46                     # dự phòng: GlobalSign (ký chéo GTS)
)
OUT=lib/sync/pinned_roots.g.dart
{
  echo "// SINH TỰ ĐỘNG bởi tool/gen_pinned_roots.sh - KHÔNG sửa tay."
  echo "// ignore_for_file: lines_longer_than_80_chars"
  echo
  echo "/// (tên, SHA-256 SPKI base64, SHA-256 DER hex) của từng CA gốc được ghim."
  echo "const pinnedRootInfo = <(String, String, String)>["
  for r in "${ROOTS[@]}"; do
    f="$SRC/$r.pem"
    spki=$(openssl x509 -in "$f" -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
    der=$(openssl x509 -in "$f" -outform der | sha256sum | cut -d' ' -f1)
    echo "  ('$r', '$spki', '$der'),"
  done
  echo "];"
  echo
  echo "/// PEM nối liền, nạp vào SecurityContext(withTrustedRoots: false)."
  echo "const pinnedRootsPem = '''"
  for r in "${ROOTS[@]}"; do openssl x509 -in "$SRC/$r.pem" -outform pem; done
  echo "''';"
} > "$OUT"
dart format "$OUT" >/dev/null
echo "Đã ghi $OUT (${#ROOTS[@]} CA)"
