# Rayakala Landing

Personal homepage for **rayakala.ink** + **rayakala.id** — intentionally light.

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

## Editing copy

All page copy lives in `static/index.html`. Contact email is
`socionomad@gmail.com`; live tools are `https://money.rayakala.ink/` and
`https://kalkulator.rayakala.ink/`.

## Development

```bash
make verify   # clippy + fmt + tests (run before every commit)
make build    # release binary
```

Live app: `https://rayakala.ink/` + `https://rayakala.id/` (same binary, both apex+www behind nginx), money app stays at `https://money.rayakala.ink/`, investment calculators (Beruang) at `https://kalkulator.rayakala.ink/`.

## License

MIT — see [LICENSE](./LICENSE).
