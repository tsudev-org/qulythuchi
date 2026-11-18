#!/usr/bin/env bash
# Dựng toàn bộ qulythuchi.tsudev.com: web app Flutter (/app/) + site Astro, gom vào apps/site/dist (ADR-0013).
# Worker `qulythuchi` phục vụ thư mục đó bằng Workers Static Assets (services/sync-api/wrangler.jsonc).
#   ./scripts/build-web.sh            # build app + site
#   ./scripts/build-web.sh --bo-app   # chỉ site, dùng lại apps/app/build/web có sẵn
# Deploy sau đó: (cd services/sync-api && npm run deploy).
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${1:-}" != "--bo-app" ]]; then
  (
    cd apps/app
    ./tool/fetch_web_assets.sh
    # --csp: không sinh mã động; --no-web-resources-cdn: CanvasKit tự phục vụ (CSP chỉ 'self', không gọi gstatic).
    flutter build web --release --base-href /app/ --csp --no-web-resources-cdn
  )
fi
(cd apps/site && QT_CAN_APP=1 npm run build)
