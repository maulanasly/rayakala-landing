#!/usr/bin/env bash
# install-release.sh — install a GitHub-built rayakala-landing binary. Stateless, no DB.
# Usage (run as root via sudo from deploy user):
#   sudo bash /tmp/install-release-landing.sh /tmp/rayakala-landing-new
set -euo pipefail

BIN_SRC="${1:?usage: install-release.sh <path-to-new-binary>}"
APP_BIN="/usr/local/bin/rayakala-landing"
APP_PREV="/usr/local/bin/rayakala-landing.prev"
SERVICE="rayakala-landing"
HEALTH_URL="http://127.0.0.1:5001/health"

if [ ! -f "$BIN_SRC" ]; then
  echo "error: binary not found: $BIN_SRC" >&2
  exit 1
fi

chmod 755 "$BIN_SRC"

if [ -f "$APP_BIN" ]; then
  echo "Saving previous binary -> $APP_PREV"
  cp -a "$APP_BIN" "$APP_PREV"
fi

echo "Installing $BIN_SRC -> $APP_BIN"
install -m 755 "$BIN_SRC" "$APP_BIN"

echo "Restarting $SERVICE"
systemctl daemon-reload || true
systemctl enable "$SERVICE" >/dev/null 2>&1 || true
systemctl restart "$SERVICE"

echo "Healthchecking $HEALTH_URL"
for i in $(seq 1 20); do
  if curl -fsS --max-time 5 "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Healthy."
    break
  fi
  if [ "$i" -eq 20 ]; then
    echo "Healthcheck FAILED after 20 tries — see: journalctl -u $SERVICE" >&2
    systemctl status "$SERVICE" --no-pager || true
    exit 1
  fi
  sleep 3
done

echo "Deploy OK: $(basename "$BIN_SRC") active."
