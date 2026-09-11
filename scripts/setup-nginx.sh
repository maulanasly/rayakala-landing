#!/usr/bin/env bash
# setup-nginx.sh — install rayakala-landing as a SECOND nginx site (80 -> 127.0.0.1:5001).
# Idempotent. Keeps the existing monthly-logs site. Run as root:
#   bash setup-nginx.sh
set -euo pipefail

echo "==> Installing nginx"
apt-get update -y
apt-get install -y nginx curl

echo "==> Installing landing site config (keeping existing sites)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_SRC=""
for cand in "$SCRIPT_DIR/nginx-rayakala-landing.conf" "$SCRIPT_DIR/../deploy/nginx-rayakala-landing.conf" /tmp/nginx-rayakala-landing.conf; do
  if [ -f "$cand" ]; then CONF_SRC="$cand"; break; fi
done
if [ -z "$CONF_SRC" ]; then
  echo "error: nginx-rayakala-landing.conf not found" >&2
  exit 1
fi
cp "$CONF_SRC" /etc/nginx/sites-available/rayakala-landing
ln -sf /etc/nginx/sites-available/rayakala-landing /etc/nginx/sites-enabled/rayakala-landing
# Do NOT remove other sites (monthly-logs must stay).

echo "==> Testing + reloading"
nginx -t
systemctl enable nginx >/dev/null 2>&1 || true
systemctl reload nginx

echo "==> Healthcheck via nginx (Host: rayakala.ink)"
for i in $(seq 1 10); do
  if curl -fsS --max-time 5 -H "Host: rayakala.ink" http://127.0.0.1/health >/dev/null 2>&1; then
    echo "nginx proxy healthy for rayakala.ink."
    break
  fi
  if [ "$i" -eq 10 ]; then
    echo "Healthcheck FAILED — app may not be running yet (deploy first), see: journalctl -u rayakala-landing; nginx -T" >&2
    exit 1
  fi
  sleep 2
done

DOMAIN="${DOMAIN:-rayakala.ink}"
echo "==> Domain check for $DOMAIN (warning-only before DNS/TLS is live)"
if getent hosts "$DOMAIN" >/dev/null 2>&1; then
  curl -fsS --max-time 5 -H "Host: $DOMAIN" http://127.0.0.1/health >/dev/null 2>&1 \
    && echo "Host $DOMAIN serves via nginx." \
    || echo "warning: Host $DOMAIN not served yet (check server_name / app)" >&2
else
  echo "warning: $DOMAIN does not resolve — add an A record to 43.173.12.145" >&2
fi

echo "Nginx OK for landing. Money site untouched."
