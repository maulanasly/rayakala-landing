# AGENTS.md — rayakala-landing

Personal homepage for `rayakala.id` (canonical, `rayakala.ink` alias). Intentionally light.

## Stack

- **Rust (Axum 0.8) + vanilla HTML/CSS/JS** — no npm, no bundler, no DB.
- Static files embedded into single ~2 MB binary via `rust-embed`.
- Served behind nginx on `:5001` (co-exists with `monthly-logs` on `:5000`).
- Release profile: `opt-level=s, lto=true, codegen-units=1, strip=true, panic=abort` — keep binary small.

## Layout

```
src/main.rs              # binds 0.0.0.0:5001, serve(create_router())
src/lib.rs / src/routes/ # create_router() — /health + fallback static handler
src/routes/health.rs     # GET /health -> {"status":"ok"}
src/routes/static_handler.rs # rust-embed from static/, mime_guess, cache headers
static/index.html        # ALL page copy lives here
static/css/site.css static/js/site.js favicon.svg robots.txt
tests/health_test.rs tests/static_test.rs
deploy/                  # systemd unit + nginx site (apex+www -> 127.0.0.1:5001)
scripts/                 # bootstrap-landing, setup-nginx, setup-tls, install-release, rollback
docs/DEPLOY.md           # full deploy runbook
Dockerfile               # rust:1.75 builder -> debian:bookworm-slim, EXPOSE 5001
```

## Commands

```bash
cargo run                 # dev on http://localhost:5001
make dev / test / lint / fmt / build
make verify               # clippy --all-targets -- -D warnings + fmt + test — run before every commit
cargo build --release
```

CI (`.github/workflows/ci.yml`): fmt + clippy + test + build.
CD (`.github/workflows/deploy.yml`): build on ubuntu-24.04 → SCP → `install-release.sh` → restart + healthcheck.

## Conventions for agents

1. **Copy:** edit only `static/index.html`. Contact `support@rayakala.id`. Live tools: `https://kas.rayakala.id/` (legacy `https://money.rayakala.ink/`), `https://hitung.rayakala.id/`. Canonical URL `https://rayakala.id/` for `og:url`, sitemap, footer.
2. **Routes:** add in `src/routes/` + register in `create_router()` (`src/routes/mod.rs`). Keep `/health` exact JSON shape. CORS is `Any/Any/Any` — don't tighten without reason.
3. **Static serving (`static_handler.rs`):**
   - `/` → `index.html` with `text/html; charset=utf-8`, `cache-control: no-cache`.
   - `css/*, js/*, favicon.svg, robots.txt` → `public, max-age=31536000, immutable`.
   - Other extensionless unknown paths → fallback to `index.html` (anchor nav). Paths containing `.` that miss → `404`.
   - Preserve this behavior; update `tests/static_test.rs` if changing.
4. **No new deps** unless justified — no frontend toolchain, no DB. Prefer std + existing crates (`axum, tokio, serde_json, tower-http, rust-embed, mime_guess, tracing`).
5. **Tests:** use `create_router()` + `tower::ServiceExt::oneshot` pattern (see `tests/`). Don't spin up real TCP servers.
6. **Formatting/lints:** `cargo fmt` clean, `clippy -D warnings` clean.
7. **Port:** always `:5001`. Don't change without updating `main.rs`, `Dockerfile`, `deploy/*`, `docs/DEPLOY.md`.
8. **Deploy:** never commit secrets/keys. VPS `43.173.12.145`, user `deploy`. See `docs/DEPLOY.md` for secrets, nginx, TLS (4 hosts: `rayakala.ink, www.rayakala.ink, rayakala.id, www.rayakala.id`), rollback (`/opt/rayakala-landing/scripts/rollback.sh`).
