#!/usr/bin/env bash
# Chạy thử bản Simulator của apps/app trên một máy giả lập iOS (dùng trong .github/workflows/apple.yml).
#
# Cách dùng: scripts/apple-simulator-run.sh <udid> <tên-ảnh>
#   - Khởi động máy giả lập, đặt ngôn ngữ hệ thống vi / vùng vi_VN (lần đầu mở phải ra tiếng Việt).
#   - Cài + mở apps/app/build/ios/iphonesimulator/Runner.app, đợi 45 giây.
#   - Lỗi nếu ứng dụng thoát/sập, hoặc rơi vào màn hình lỗi khởi động (main.dart in "$INIT_ERROR<loại lỗi>").
#   - Chụp màn hình vào shots/<tên-ảnh>.png rồi tắt máy giả lập.
# Biến môi trường cần: BUNDLE_ID, INIT_ERROR (đặt ở env của workflow).
set -euo pipefail

udid="$1"
shot="$2"
[[ -n "${BUNDLE_ID-}" && -n "${INIT_ERROR-}" ]] || { echo "::error::Thiếu BUNDLE_ID/INIT_ERROR"; exit 1; }

xcrun simctl list devices | grep -F "$udid" | sed 's/^ *//'
xcrun simctl boot "$udid"
xcrun simctl bootstatus "$udid" -b
xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array vi
xcrun simctl spawn "$udid" defaults write -g AppleLocale vi_VN
xcrun simctl install "$udid" apps/app/build/ios/iphonesimulator/Runner.app
xcrun simctl launch --stdout="$PWD/$shot-app.log" --stderr="$PWD/$shot-app.log" "$udid" "$BUNDLE_ID"
sleep 45
if ! xcrun simctl spawn "$udid" launchctl list | grep -q "UIKitApplication:$BUNDLE_ID"; then
  echo "::error::Ứng dụng thoát/sập trên máy giả lập ($shot) trong 45 giây đầu"
  cat "$shot-app.log" 2>/dev/null | tail -40 || true
  xcrun simctl spawn "$udid" log show --last 2m --predicate 'process == "Runner"' | tail -80
  exit 1
fi
mkdir -p shots
xcrun simctl io "$udid" screenshot "shots/$shot.png"
# Tiến trình còn sống chưa đủ: màn hình lỗi khởi động cũng giữ tiến trình (bài học AP1 mục 2.10).
{ cat "$shot-app.log" 2>/dev/null; xcrun simctl spawn "$udid" log show --last 5m --style compact \
    --predicate "eventMessage CONTAINS \"${INIT_ERROR%: }\""; } > "$shot-check.log" || true
if grep -qF "$INIT_ERROR" "$shot-check.log"; then
  echo "::error::Ứng dụng ($shot) hiện màn hình lỗi khởi động:"
  grep -F "$INIT_ERROR" "$shot-check.log" | tail -3
  exit 1
fi
xcrun simctl shutdown "$udid"
