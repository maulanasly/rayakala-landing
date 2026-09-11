mod routes;

use routes::create_router;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let app = create_router();

    let listener = tokio::net::TcpListener::bind("0.0.0.0:5001")
        .await
        .expect("Failed to bind to port 5001");

    println!("rayakala-landing running on http://0.0.0.0:5001");

    axum::serve(listener, app).await.expect("Server failed");
}
