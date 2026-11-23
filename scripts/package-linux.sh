#!/usr/bin/env bash
# Đóng gói bản Linux đã dựng (`flutter build linux --release`) thành tệp phát hành theo VERSIONING.md mục 2.2:
#   qulythuchi_<V>_linux-x64.tar.gz   bản portable (giải nén, chạy ./qulythuchi)
#   qulythuchi_<V>_linux-x64.deb      gói Debian/Ubuntu, cài vào /opt/qulythuchi + lối tắt menu + icon hicolor
#
#   scripts/package-linux.sh <thư mục bundle> <phiên bản YY.M.DDNN> <thư mục ra>
#
# `libc6 (>= X)` lấy từ GLIBC cao nhất mà các tệp trong bundle thật sự đòi (đo bằng objdump), không đoán.
set -euo pipefail

bundle=${1:?thiếu thư mục bundle}
ver=${2:?thiếu phiên bản}
out=${3:?thiếu thư mục ra}
root=$(cd "$(dirname "$0")/.." && pwd)
icons="$root/assets/brand/app/linux"
name=qulythuchi
appid=com.tsudev.qulythuchi

[[ "$ver" =~ ^[0-9]{2}\.[1-9][0-9]?\.[0-3][0-9][0-9]{2}$ ]] || { echo "Phiên bản sai khuôn YY.M.DDNN: $ver" >&2; exit 1; }
test -x "$bundle/$name" || { echo "Không thấy $bundle/$name" >&2; exit 1; }
mkdir -p "$out"

glibc=$(find "$bundle" -type f \( -name '*.so*' -o -perm -u+x \) -exec objdump -T {} + 2>/dev/null \
  | grep -oE 'GLIBC_[0-9]+\.[0-9]+' | sort -uV | tail -1)
glibc=${glibc#GLIBC_}
echo "GLIBC cao nhất bundle đòi: $glibc"

tar -C "$bundle" --owner=0 --group=0 -czf "$out/${name}_${ver}_linux-x64.tar.gz" .

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
pkg="$work/pkg"
mkdir -p "$pkg/DEBIAN" "$pkg/opt/$name" "$pkg/usr/bin" "$pkg/usr/share/applications"
cp -a "$bundle/." "$pkg/opt/$name/"
ln -s "/opt/$name/$name" "$pkg/usr/bin/$name"
for s in 16 24 32 48 64 128 256 512; do
  d="$pkg/usr/share/icons/hicolor/${s}x${s}/apps"
  mkdir -p "$d"
  cp "$icons/$name-$s.png" "$d/$appid.png"
done
cat > "$pkg/usr/share/applications/$appid.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Quly Thu Chi
GenericName=Quản lý thu chi
Comment=Quản lý thu chi cá nhân, mã hoá đầu cuối
Comment[en]=Personal finance manager with end-to-end encryption
Exec=/opt/$name/$name %U
Icon=$appid
Terminal=false
Categories=Office;Finance;
Keywords=thu chi;tài chính;ngân sách;finance;budget;
StartupWMClass=$appid
EOF
mkdir -p "$pkg/usr/share/doc/$name"
cp "$root/LICENSE" "$pkg/usr/share/doc/$name/copyright"
size=$(du -sk "$pkg" | cut -f1)
cat > "$pkg/DEBIAN/control" <<EOF
Package: $name
Version: $ver-1
Architecture: amd64
Maintainer: TsuDEV <contact@tsudev.com>
Installed-Size: $size
Depends: libc6 (>= $glibc), libgtk-3-0 | libgtk-3-0t64, libsecret-1-0
Section: misc
Priority: optional
Homepage: https://qulythuchi.tsudev.com
Description: Quly Thu Chi - quản lý thu chi cá nhân mã hoá đầu cuối
 Ghi thu chi, ngân sách, mục tiêu, báo cáo; dữ liệu mã hoá trên máy và khi
 đồng bộ. Mã nguồn AGPL-3.0: https://github.com/tsudev-org/qulythuchi
EOF
find "$pkg" -type d -exec chmod 0755 {} +
dpkg-deb --root-owner-group -Zxz --build "$pkg" "$out/${name}_${ver}_linux-x64.deb" >/dev/null
dpkg-deb --info "$out/${name}_${ver}_linux-x64.deb" | sed -n '/Package:/,$p'
