.PHONY: dev test lint fmt build verify clean

dev:
	cargo run

test:
	cargo test

lint:
	cargo clippy --all-targets -- -D warnings

fmt:
	cargo fmt

verify: lint fmt test

build:
	cargo build --release

clean:
	cargo clean
