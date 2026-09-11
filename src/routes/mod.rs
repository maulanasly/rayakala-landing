pub mod health;
pub mod static_handler;

use axum::Router;
use tower_http::cors::{Any, CorsLayer};

pub fn create_router() -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .route("/health", axum::routing::get(health::handler))
        .fallback(static_handler::handler)
        .layer(cors)
}
