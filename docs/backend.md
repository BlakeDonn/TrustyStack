## Backend

### Rust Backend with GraphQL Setup

1. **Install Rust**:
    ```bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    ```

2. **Create a New Rust Project**:
    ```bash
    cargo new rust-backend
    cd rust-backend
    ```

3. **Add Dependencies in `Cargo.toml`**:
    ```toml
    [dependencies]
    actix-web = "4"
    juniper = "0.15"
    juniper_actix = "0.5"
    serde = { version = "1.0", features = ["derive"] }
    serde_json = "1.0"
    tokio = { version = "1", features = ["full"] }
    ```

4. **Set Up GraphQL Schema in `schema.rs`**:
    ```rust
    use juniper::{graphql_object, EmptyMutation, EmptySubscription, RootNode};

    pub struct Query;

    #[graphql_object]
    impl Query {
        fn api_version() -> &str {
            "1.0"
        }
    }

    pub type Schema = RootNode<'static, Query, EmptyMutation<()>, EmptySubscription<()>>;

    pub fn create_schema() -> Schema {
        Schema::new(Query {}, EmptyMutation::new(), EmptySubscription::new())
    }
    ```

5. **Set Up Actix-Web Server in `main.rs`**:
    ```rust
    use actix_web::{web, App, HttpServer};
    use juniper_actix::graphql_handler;
    use std::sync::Arc;

    mod schema;

    #[actix_web::main]
    async fn main() -> std::io::Result<()> {
        let schema = Arc::new(schema::create_schema());

        HttpServer::new(move || {
            App::new()
                .app_data(web::Data::new(schema.clone()))
                .route("/graphql", web::post().to(graphql_handler))
        })
        .bind("127.0.0.1:8080")?
        .run()
        .await
    }
    ```
