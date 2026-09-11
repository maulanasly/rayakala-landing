use rayakala_landing::routes::create_router;
use tower::ServiceExt;

#[tokio::test]
async fn health_returns_ok() {
    let app = create_router();
    let res = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/health")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), axum::http::StatusCode::OK);
    let body = axum::body::to_bytes(res.into_body(), 1024).await.unwrap();
    let v: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert_eq!(v, serde_json::json!({ "status": "ok" }));
}
