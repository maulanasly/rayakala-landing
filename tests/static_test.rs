use rayakala_landing::routes::create_router;
use tower::ServiceExt;

async fn get(path: &str) -> axum::http::Response<axum::body::Body> {
    create_router()
        .oneshot(
            axum::http::Request::builder()
                .uri(path)
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap()
}

#[tokio::test]
async fn root_serves_html() {
    let res = get("/").await;
    assert_eq!(res.status(), axum::http::StatusCode::OK);
    let ct = res
        .headers()
        .get("content-type")
        .unwrap()
        .to_str()
        .unwrap()
        .to_owned();
    assert!(ct.contains("text/html"), "ct={ct}");
    let body = axum::body::to_bytes(res.into_body(), 128 * 1024)
        .await
        .unwrap();
    let html = String::from_utf8(body.to_vec()).unwrap();
    assert!(html.contains("Rayakala"), "missing brand");
    assert!(html.contains("/css/site.css"), "missing css link");
}

#[tokio::test]
async fn css_and_js_served_with_immutable_cache() {
    for path in ["/css/site.css", "/js/site.js"] {
        let res = get(path).await;
        assert_eq!(res.status(), axum::http::StatusCode::OK, "{path}");
        let cc = res
            .headers()
            .get("cache-control")
            .unwrap()
            .to_str()
            .unwrap()
            .to_owned();
        assert!(cc.contains("immutable"), "cc={cc} for {path}");
    }
}

#[tokio::test]
async fn unknown_file_path_is_404_but_clean_route_falls_back() {
    let res = get("/css/nope.css").await;
    assert_eq!(res.status(), axum::http::StatusCode::NOT_FOUND);

    // Clean routes (no extension) fall back to index.html for anchor nav.
    let res = get("/about").await;
    assert_eq!(res.status(), axum::http::StatusCode::OK);
}
