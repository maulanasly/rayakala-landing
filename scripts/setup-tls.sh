#!/usr/bin/env bash
# setup-tls.sh — production Let's Encrypt cert for rayakala.ink + www and rayakala.id + www.
# Idempotent. Run as root:
#   DOMAIN=rayakala.ink EMAIL=you@example.com bash scripts/setup-tls.sh
# Prerequisites: A rayakala.ink + A www.rayakala.ink + A rayakala.id + A www.rayakala.id
# -> 43.173.12.145, tcp/80 reachable,
# deploy/nginx-rayakala-landing.conf installed (run scripts/setup-nginx.sh first).
set -euo pipefail

DOMAIN="${DOMAIN:-rayakala.ink}"
EMAIL="${EMAIL:-gi.creatorz@gmail.com}"
EXTRA_DOMAINS="${EXTRA_DOMAINS:-www.rayakala.ink rayakala.id www.rayakala.id}"

echo "==> Installing certbot"
apt-get update -y
apt-get install -y certbot python3-certbot-nginx curl

echo "==> Checking DNS for all domains: ${DOMAIN} ${EXTRA_DOMAINS}"
for d in "$DOMAIN" $EXTRA_DOMAINS; do
  if ! getent hosts "$d" >/dev/null; then
    echo "error: $d does not resolve locally — add an A record to 43.173.12.145 first" >&2
    exit 1
  fi
done

echo "==> Checking HTTP challenge paths (nginx must serve port 80)"
for d in "$DOMAIN" $EXTRA_DOMAINS; do
  if ! curl -fsS --max-time 10 -H "Host: $d" "http://127.0.0.1/health" >/dev/null; then
    echo "error: local http://127.0.0.1/health (Host: $d) failed — fix nginx/app first" >&2
    echo "see: systemctl status nginx rayakala-landing --no-pager; nginx -T" >&2
    exit 1
  fi
done

DOMAINS=("$DOMAIN")
if [ -n "$EXTRA_DOMAINS" ]; then
  # shellcheck disable=SC2206
  DOMAINS+=($EXTRA_DOMAINS)
fi
ARGS=()
for d in "${DOMAINS[@]}"; do ARGS+=(-d "$d"); done

echo "==> Requesting production cert for: ${DOMAINS[*]}"
certbot --nginx "${ARGS[@]}" \
  --agree-tos -m "$EMAIL" --no-eff-email \
  --redirect --non-interactive

echo "==> Verifying"
nginx -t
systemctl reload nginx
certbot certificates
for d in "${DOMAINS[@]}"; do
  curl -fsS --max-time 10 "https://$d/health" >/dev/null \
    && echo "TLS OK: https://$d/health" \
    || { echo "TLS healthcheck FAILED for $d — see: journalctl -u nginx" >&2; exit 1; }
done

echo "==> Renewal dry-run (staging, safe)"
certbot renew --dry-run

echo "TLS done. Renewals via certbot systemd timer: systemctl list-timers | grep -i certbot"
