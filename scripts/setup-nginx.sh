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

echo "==> Healthchecks via nginx (Host: rayakala.ink + rayakala.id)"
for HOST in rayakala.ink rayakala.id; do
  for i in $(seq 1 10); do
    if curl -fsS --max-time 5 -H "Host: $HOST" http://127.0.0.1/health >/dev/null 2>&1; then
      echo "nginx proxy healthy for $HOST."
      break
    fi
    if [ "$i" -eq 10 ]; then
      echo "Healthcheck FAILED for $HOST — app may not be running yet (deploy first), see: journalctl -u rayakala-landing; nginx -T" >&2
      exit 1
    fi
    sleep 2
  done
done

DOMAINS="${DOMAINS:-rayakala.ink www.rayakala.ink rayakala.id www.rayakala.id}"
echo "==> Domain checks (warning-only before DNS/TLS is live): $DOMAINS"
for DOMAIN in $DOMAINS; do
  if getent hosts "$DOMAIN" >/dev/null 2>&1; then
    curl -fsS --max-time 5 -H "Host: $DOMAIN" http://127.0.0.1/health >/dev/null 2>&1 \
      && echo "Host $DOMAIN serves via nginx." \
      || echo "warning: Host $DOMAIN not served yet (check server_name / app)" >&2
  else
    echo "warning: $DOMAIN does not resolve — add an A record to 43.173.12.145" >&2
  fi
done

echo "Nginx OK for landing. Money site untouched."
