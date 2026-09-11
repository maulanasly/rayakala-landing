# Deploy — GitHub builds, VPS runs (systemd)

Flow: `push to main` → Actions builds `target/release/rayakala-landing` on
`ubuntu-24.04` → SCP to `43.173.12.145` as `deploy` → `install-release.sh`
installs, restarts `rayakala-landing.service`, healthchecks `:5001`.

Co-exists with `monthly-logs` (`money.rayakala.ink` → `:5000`). This app uses
`:5001` and serves `rayakala.ink` + `www.rayakala.ink`. No DB.

## One-time setup

### 1. Create the public repo + push

```bash
cd apps/rayakala-landing
gh repo create maulanasly/rayakala-landing --public --source=. --remote=origin --push
git branch -M main
git push -u origin main
```

### 2. Generate a deploy key (local, never commit)

```bash
ssh-keygen -t ed25519 -f /tmp/github-deploy-rayakala -N "" -C "github-deploy rayakala-landing"
cat /tmp/github-deploy-rayakala.pub   # -> authorize for deploy user (already exists from monthly-logs)
```

If the `deploy` user already exists (it does — monthly-logs bootstrap), just
append the new pubkey to `/home/deploy/.ssh/authorized_keys` instead of
re-running full bootstrap. Otherwise run full landing bootstrap as root:

```bash
scp scripts/bootstrap-landing.sh deploy/rayakala-landing.service deploy/nginx-rayakala-landing.conf scripts/setup-nginx.sh root@43.173.12.145:/tmp/
ssh root@43.173.12.145 "bash /tmp/bootstrap-landing.sh"
```

This creates `rayakala-landing` runtime user, `/var/lib/rayakala-landing`,
sudoers (`/etc/sudoers.d/deploy-rayakala-landing`), systemd unit, and the
second nginx site (`:80` for apex+www → `127.0.0.1:5001`). Keeps money site.

### 3. GitHub secrets (repo → Settings → Secrets → Actions)

| Secret | Value |
|---|---|
| `DEPLOY_HOST` | `43.173.12.145` |
| `DEPLOY_USER` | `deploy` |
| `DEPLOY_KEY` | contents of `/tmp/github-deploy-rayakala` (private) |
| `DEPLOY_PORT` | `22` |
| `KNOWN_HOSTS` | output of `ssh-keyscan -p 22 43.173.12.145` |

```bash
gh secret set DEPLOY_HOST -b "43.173.12.145" -R maulanasly/rayakala-landing
gh secret set DEPLOY_USER -b "deploy" -R maulanasly/rayakala-landing
gh secret set DEPLOY_KEY < /tmp/github-deploy-rayakala -R maulanasly/rayakala-landing
gh secret set DEPLOY_PORT -b "22" -R maulanasly/rayakala-landing
ssh-keyscan -p 22 43.173.12.145 | gh secret set KNOWN_HOSTS -R maulanasly/rayakala-landing
shred -u /tmp/github-deploy-rayakala
```

### 4. First deploy

`git push` to `main` (CD runs automatically).

Verify:

```bash
curl -f http://43.173.12.145/health -H "Host: rayakala.ink"   # via nginx
curl -f http://43.173.12.145:5001/health                      # direct (until closed)
ssh deploy@43.173.12.145 "sudo systemctl status rayakala-landing --no-pager"
```

## nginx (second site)

`deploy/nginx-rayakala-landing.conf` → `/etc/nginx/...` proxies `:80` for
`rayakala.ink + www` to `127.0.0.1:5001`. Refresh with:

```bash
scp scripts/setup-nginx.sh deploy/nginx-rayakala-landing.conf root@43.173.12.145:/tmp/
ssh root@43.173.12.145 "bash /tmp/setup-nginx.sh"
```

## Domain + TLS (apex + www)

DNS: `www.rayakala.ink` → `43.173.12.145` ✅ already; add `A @ -> 43.173.12.145`
for apex (currently missing).

Run once as `root` (needs `tcp/80` + `tcp/443` open):

```bash
scp deploy/nginx-rayakala-landing.conf scripts/setup-nginx.sh scripts/setup-tls.sh root@43.173.12.145:/tmp/
ssh root@43.173.12.145 "bash /tmp/setup-nginx.sh && DOMAIN=rayakala.ink EMAIL=gi.creatorz@gmail.com bash /tmp/setup-tls.sh"
```

`setup-tls.sh` defaults to `-d rayakala.ink -d www.rayakala.ink --redirect`.
Verify:

```bash
curl -f https://rayakala.ink/health
curl -f https://www.rayakala.ink/health
curl -I http://rayakala.ink/   # expect 301 → https
```

Then keep `:5001` on localhost only behind nginx. `money.rayakala.ink` untouched.

## Rollback

```bash
sudo bash /opt/rayakala-landing/scripts/rollback.sh
```

Restores `/usr/local/bin/rayakala-landing.prev`, restarts + healthchecks.

## Files

| Path | Purpose |
|---|---|
| `.github/workflows/deploy.yml` | build (ubuntu-24.04) + SCP + remote install |
| `.github/workflows/ci.yml` | fmt + clippy + test + build |
| `scripts/install-release.sh` | install → restart → healthcheck (no DB) |
| `scripts/rollback.sh` | restore `.prev` binary |
| `scripts/bootstrap-landing.sh` | one-time VPS setup (root) |
| `scripts/setup-nginx.sh` | install second nginx site (root) |
| `scripts/setup-tls.sh` | Let's Encrypt cert for apex+www (root) |
| `deploy/rayakala-landing.service` | systemd unit (`rayakala-landing` user, `:5001`) |
| `deploy/nginx-rayakala-landing.conf` | nginx site: `:80` (+`:443` after TLS) → `127.0.0.1:5001` |
