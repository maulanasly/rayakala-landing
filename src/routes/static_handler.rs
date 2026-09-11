use axum::extract::OriginalUri;
use axum::http::{header, StatusCode};
use axum::response::{IntoResponse, Response};
use rust_embed::Embed;

#[derive(Embed)]
#[folder = "static/"]
struct Assets;

fn cache_control(path: &str) -> &'static str {
    if path.is_empty() || path == "index.html" {
        "no-cache"
    } else if path.starts_with("css/")
        || path.starts_with("js/")
        || path == "favicon.svg"
        || path == "robots.txt"
    {
        "public, max-age=31536000, immutable"
    } else {
        "public, max-age=3600"
    }
}

pub async fn handler(uri: OriginalUri) -> Result<Response, StatusCode> {
    let path = uri.path().trim_start_matches('/');

    if path.is_empty() {
        return match Assets::get("index.html") {
            Some(content) => Ok((
                [
                    ("content-type", "text/html; charset=utf-8"),
                    ("cache-control", cache_control("")),
                ],
                content.data,
            )
                .into_response()),
            None => Err(StatusCode::NOT_FOUND),
        };
    }

    // Block query strings leaking into asset lookup is handled by OriginalUri path.
    match Assets::get(path) {
        Some(content) => {
            let mime = mime_guess::from_path(path)
                .first_or_octet_stream()
                .to_string();
            Ok((
                [
                    (header::CONTENT_TYPE.as_str(), mime.as_str()),
                    ("cache-control", cache_control(path)),
                ],
                content.data,
            )
                .into_response())
        }
        None => {
            // Fallback to index.html for unknown routes (single-page anchors).
            // Return 404 for unknown file-like paths to avoid masking typos.
            if path.contains('.') {
                return Err(StatusCode::NOT_FOUND);
            }
            match Assets::get("index.html") {
                Some(content) => Ok((
                    [
                        ("content-type", "text/html; charset=utf-8"),
                        ("cache-control", cache_control("")),
                    ],
                    content.data,
                )
                    .into_response()),
                None => Err(StatusCode::NOT_FOUND),
            }
        }
    }
}
