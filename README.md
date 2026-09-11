# Rayakala Landing

Personal homepage for **rayakala.ink** — intentionally light.

Stack: **Rust (Axum 0.8) + vanilla HTML/CSS/JS** (no npm, no bundler, no DB).
Static files are embedded into a single ~2 MB binary via `rust-embed`, served behind nginx.

## Quickstart

```bash
cargo run
```

Open http://localhost:5001. `GET /health` → `{"status":"ok"}`.

## Project layout

```
src/          Axum routes (health + embedded static with cache headers)
static/       index.html, css/site.css, js/site.js, favicon.svg, robots.txt
tests/        health + static serving tests
deploy/       systemd unit + nginx site (apex+www -> 127.0.0.1:5001)
scripts/      bootstrap / nginx / TLS / install / rollback
docs/         DEPLOY.md
```

## Customizing copy

All placeholder text in `static/index.html` is marked `<!-- PLACEHOLDER -->`.
Replace name, tagline, bio, projects, links, and `hello@rayakala.ink`.

## Development

```bash
make verify   # clippy + fmt + tests (run before every commit)
make build    # release binary
```

Live app: `https://rayakala.ink/` (after DNS + TLS), money app stays at `https://money.rayakala.ink/`.

## License

MIT — see [LICENSE](./LICENSE).
