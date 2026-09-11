#!/usr/bin/env bash
# bootstrap-landing.sh — one-time VPS setup for rayakala-landing. Run as root.
# Co-exists with monthly-logs (port 5000). This app uses port 5001, no DB.
# Usage:
#   scp scripts/bootstrap-landing.sh deploy/rayakala-landing.service deploy/nginx-rayakala-landing.conf scripts/setup-nginx.sh root@43.173.12.145:/tmp/
#   ssh root@43.173.12.145 "bash /tmp/bootstrap-landing.sh"
set -euo pipefail

echo "==> Installing runtime deps (no Rust toolchain needed — GitHub builds)"
apt-get update -y
apt-get install -y ca-certificates curl openssh-server

echo "==> Creating runtime user"
id rayakala-landing >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d /var/lib/rayakala-landing rayakala-landing

echo "==> Creating dirs"
mkdir -p /var/lib/rayakala-landing /opt/rayakala-landing/scripts
chown -R rayakala-landing:rayakala-landing /var/lib/rayakala-landing
chmod 750 /var/lib/rayakala-landing

echo "==> Sudoers for deploy (least privilege, landing only)"
cat > /etc/sudoers.d/deploy-rayakala-landing <<'EOF'
deploy ALL=(root) NOPASSWD: /bin/bash /tmp/install-release-landing.sh *, /usr/bin/bash /tmp/install-release-landing.sh *, /bin/systemctl * rayakala-landing*, /usr/bin/systemctl * rayakala-landing*, /usr/bin/install * /usr/local/bin/rayakala-landing*
EOF
chmod 440 /etc/sudoers.d/deploy-rayakala-landing
visudo -c

echo "==> Installing systemd unit"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UNIT_SRC=""
for cand in "$SCRIPT_DIR/rayakala-landing.service" "$SCRIPT_DIR/../deploy/rayakala-landing.service" /tmp/rayakala-landing.service; do
  if [ -f "$cand" ]; then UNIT_SRC="$cand"; break; fi
done
if [ -n "$UNIT_SRC" ]; then
  cp "$UNIT_SRC" /etc/systemd/system/rayakala-landing.service
  systemctl daemon-reload
  systemctl enable rayakala-landing || true
  echo "Unit installed from $UNIT_SRC"
else
  echo "warning: rayakala-landing.service not found — install it manually" >&2
fi

echo "==> nginx second site (apex+www -> 127.0.0.1:5001, keeps money site)"
NGINX_SETUP=""
for cand in "$SCRIPT_DIR/setup-nginx.sh" "$SCRIPT_DIR/../scripts/setup-nginx.sh" /tmp/setup-nginx.sh; do
  if [ -f "$cand" ]; then NGINX_SETUP="$cand"; break; fi
done
if [ -n "$NGINX_SETUP" ]; then
  bash "$NGINX_SETUP" || echo "warning: nginx setup failed — re-run $NGINX_SETUP later" >&2
else
  echo "warning: setup-nginx.sh not found — run it manually" >&2
fi

echo "Bootstrap OK. Next: push to main (CD installs), then curl http://rayakala.ink/health"
