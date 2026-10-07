mod routes;

use routes::create_router;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let app = create_router();

    let port = server_port();
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await
        .unwrap_or_else(|_| panic!("Failed to bind to port {port}"));

    println!("rayakala-landing running on http://0.0.0.0:{port}");

    axum::serve(listener, app).await.expect("Server failed");
}

/// Listen port from `PORT` (default 5001). Pure parser so the rules are
/// unit-testable without binding a socket.
fn parse_port(raw: Option<&str>) -> Result<u16, String> {
    match raw.map(str::trim) {
        None | Some("") => Ok(DEFAULT_PORT),
        Some(text) => match text.parse::<u16>() {
            Ok(0) | Err(_) => Err(format!("Invalid PORT {text:?}: want 1-65535")),
            Ok(port) => Ok(port),
        },
    }
}

/// Default loopback port; override with `PORT` (required by turaes slot pairs).
const DEFAULT_PORT: u16 = 5001;

fn server_port() -> u16 {
    let raw = std::env::var("PORT").ok();
    parse_port(raw.as_deref()).expect("Invalid PORT")
}

#[cfg(test)]
mod tests {
    use super::parse_port;

    #[test]
    fn port_defaults_when_missing_or_blank() {
        assert_eq!(parse_port(None), Ok(5001));
        assert_eq!(parse_port(Some("")), Ok(5001));
        assert_eq!(parse_port(Some("   ")), Ok(5001));
    }

    #[test]
    fn port_accepts_env_override() {
        assert_eq!(parse_port(Some("8300")), Ok(8300));
        assert_eq!(parse_port(Some(" 8301 ")), Ok(8301));
    }

    #[test]
    fn port_rejects_garbage_and_zero() {
        assert!(parse_port(Some("abc")).is_err());
        assert!(parse_port(Some("0")).is_err());
        assert!(parse_port(Some("-1")).is_err());
        assert!(parse_port(Some("99999")).is_err());
    }
}
