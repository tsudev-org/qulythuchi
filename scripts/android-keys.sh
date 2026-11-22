#!/usr/bin/env bash
# 👤 CHỦ DỰ ÁN chạy (không phải agent): tạo HAI khoá ký Android cho qulythuchi và nạp vào Environment `release` của
# GitHub (DISTRIBUTION_TRUST.md mục 1.3):
#   - upload: ký AAB nộp Google Play (Play App Signing giữ khoá ký app thật; mất khoá upload thì xin Google đặt lại).
#   - apk:    ký APK tải trực tiếp trên GitHub Release - khoá RIÊNG, phải đăng ký trong Play Console (mục 1.3.2).
#             MẤT khoá này = người dùng APK không cập nhật được nữa ⇒ sao lưu NGOẠI TUYẾN ngay.
#
#   scripts/android-keys.sh [thư mục giữ khoá, mặc định ~/khoa-ky/qulythuchi]
#
# Tệp .jks + mật khẩu chỉ nằm ở thư mục đó (chmod 700) và trong secret GitHub; KHÔNG commit, KHÔNG gửi qua chat.
set -euo pipefail

dir=${1:-$HOME/khoa-ky/qulythuchi}
repo=tsudev-org/qulythuchi
command -v keytool >/dev/null || { echo "Cần keytool (JDK 17+)" >&2; exit 1; }
[ "$(gh api user -q .login)" = tsudev-tsudev ] || { echo "gh phải đăng nhập tsudev-tsudev" >&2; exit 1; }
mkdir -p "$dir" && chmod 700 "$dir"

for kind in upload apk; do
  ks="$dir/qulythuchi-$kind.jks"
  if [ -e "$ks" ]; then echo "Đã có $ks - giữ nguyên (không tạo đè)"; else
    pass=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)
    keytool -genkeypair -keystore "$ks" -storetype PKCS12 -storepass "$pass" -keypass "$pass" \
      -alias "qulythuchi-$kind" -keyalg RSA -keysize 4096 -validity 10000 \
      -dname "CN=TsuDEV, O=TsuDEV, C=VN" >/dev/null
    printf '%s\n' "$pass" > "$dir/qulythuchi-$kind.pass" && chmod 600 "$dir/qulythuchi-$kind.pass" "$ks"
  fi
  pass=$(cat "$dir/qulythuchi-$kind.pass")
  up=$(echo "$kind" | tr a-z A-Z)
  base64 -w0 "$ks" | gh secret set "ANDROID_${up}_KEYSTORE_BASE64" --repo "$repo" --env release
  printf '%s' "$pass" | gh secret set "ANDROID_${up}_KEYSTORE_PASSWORD" --repo "$repo" --env release
  printf '%s' "$pass" | gh secret set "ANDROID_${up}_KEY_PASSWORD" --repo "$repo" --env release
  printf '%s' "qulythuchi-$kind" | gh secret set "ANDROID_${up}_KEY_ALIAS" --repo "$repo" --env release
  echo "== $kind: SHA-256 chứng chỉ (ghi vào docs/RELEASE.md + Play Console):"
  keytool -list -v -keystore "$ks" -storepass "$pass" -alias "qulythuchi-$kind" | grep -E 'SHA256:'
done
echo "Xong. Sao lưu $dir ra nơi ngoại tuyến (USB mã hoá) rồi báo agent chạy lại Release."
