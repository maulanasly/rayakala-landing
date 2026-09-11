#!/usr/bin/env bash
# rollback.sh — restore previous landing binary. Run as root.
# Usage: sudo bash /opt/rayakala-landing/scripts/rollback.sh
set -euo pipefail

APP_BIN="/usr/local/bin/rayakala-landing"
APP_PREV="/usr/local/bin/rayakala-landing.prev"
SERVICE="rayakala-landing"

if [ -f "$APP_PREV" ]; then
  echo "Restoring binary $APP_PREV -> $APP_BIN"
  cp -a "$APP_PREV" "$APP_BIN"
else
  echo "warning: no previous binary at $APP_PREV" >&2
fi

systemctl restart "$SERVICE"
sleep 3
curl -fsS --max-time 5 http://127.0.0.1:5001/health >/dev/null \
  && echo "Rollback OK — service healthy." \
  || { echo "Rollback healthcheck FAILED" >&2; exit 1; }
