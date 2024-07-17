# Project Setup Documentation

## Project Overview

We are building a modern web application using the following stack:
- **Frontend**: Angular with Angular Material for styling.
- **Backend**: Rust with GraphQL using the Actix framework.
- **Databases**: Hybrid setup with PostgreSQL and MongoDB.
- **DevOps**: Continuous Integration using GitHub Actions, containerization with Docker, and orchestration with Kubernetes.

## Frontend

### Angular Frontend Setup

1. **Install Angular CLI**:
    ```bash
    npm install -g @angular/cli
    ```

2. **Create a New Angular Project**:
    ```bash
    ng new angular-frontend
    cd angular-frontend
    ```

3. **Add Angular Material**:
    ```bash
    ng add @angular/material
    ```

4. **Enable Server-Side Rendering (SSR)**:
    ```bash
    ng add @nguniversal/express-engine
    ```

5. **Update Project Structure**:
    - Ensure the following files and configurations:
        - `src/app/app.module.ts`: Configure Angular modules.
        - `src/app/app.config.ts`: Define application configuration.
        - `src/main.ts`: Bootstraps the Angular application.
        - `server.ts`: Set up Express server for SSR.
        - `src/main.server.ts`: Entry point for the server-side app.

6. **Serve the Angular Application**:
    - Development Mode:
        ```bash
        ng serve
        ```
    - SSR Mode:
        ```bash
        npm run build:ssr
        npm run serve:ssr
        ```

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

## Databases

### PostgreSQL Setup

1. **Install PostgreSQL**:
    ```bash
    sudo apt update
    sudo apt install postgresql postgresql-contrib
    ```

2. **Start PostgreSQL Service**:
    ```bash
    sudo service postgresql start
    ```

3. **Create a Database and User**:
    ```bash
    sudo -i -u postgres
    psql
    CREATE DATABASE mydb;
    CREATE USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
    GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;
    \q
    exit
    ```

### MongoDB Setup

1. **Install MongoDB**:
    ```bash
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    sudo apt update
    sudo apt install -y mongodb-org
    ```

2. **Start MongoDB Service**:
    ```bash
    sudo systemctl start mongod
    sudo systemctl enable mongod
    ```

3. **Configure Rust Backend to Connect to Databases**:
    - Create Database Connection Module in `db.rs`:
        ```rust
        use tokio_postgres::{NoTls, Client};
        use mongodb::{Client as MongoClient, options::ClientOptions};

        pub async fn connect_postgres() -> Client {
            let (client, connection) =
                tokio_postgres::connect("host=localhost user=myuser password=mypassword dbname=mydb", NoTls)
                    .await
                    .unwrap();

            tokio::spawn(async move {
                if let Err(e) = connection.await {
                    eprintln!("connection error: {}", e);
                }
            });

            client
        }

        pub async fn connect_mongodb() -> MongoClient {
            let mut client_options = ClientOptions::parse("mongodb://localhost:27017").await.unwrap();
            client_options.app_name = Some("My App".to_string());
            MongoClient::with_options(client_options).unwrap()
        }
        ```

## CI/CD

### GitHub Actions Setup

1. **Create a GitHub Actions Workflow File in `.github/workflows/ci.yml`**:
    ```yaml
    name: CI

    on:
      push:
        branches: [ main ]
      pull_request:
        branches: [ main ]

    jobs:
      build:
        runs-on: ubuntu-latest

        steps:
        - uses: actions/checkout@v2

        - name: Set up Rust
          uses: actions-rs/toolchain@v1
          with:
            toolchain: stable

        - name: Build
          run: cargo build --verbose

        - name: Run tests
          run: cargo test --verbose

      frontend:
        runs-on: ubuntu-latest

        steps:
        - uses: actions/checkout@v2

        - name: Set up Node.js
          uses: actions/setup-node@v2
          with:
            node-version: '14'

        - name: Install dependencies
          run: npm install

        - name: Run tests
          run: npm test
    ```

### Docker Setup

1. **Create Dockerfile for Rust Backend**:
    ```dockerfile
    FROM rust:latest AS builder
    WORKDIR /usr/src/app
    COPY . .
    RUN cargo build --release

    FROM debian:buster-slim
    COPY --from=builder /usr/src/app/target/release/rust-backend /usr/local/bin/rust-backend
    CMD ["rust-backend"]
    ```

2. **Create Dockerfile for Angular Frontend**:
    ```dockerfile
    FROM node:14 AS builder
    WORKDIR /usr/src/app
    COPY package*.json ./
    RUN npm install
    COPY . .
    RUN npm run build --prod

    FROM nginx:alpine
    COPY --from=builder /usr/src/app/dist/angular-frontend /usr/share/nginx/html
    ```

3. **Build Docker Images**:
    ```bash
    docker build -t rust-backend .
    docker build -t angular-frontend .
    ```

### Kubernetes Setup

1. **Create Kubernetes Deployment and Service Files**:

    - **rust-backend-deployment.yaml**:
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: rust-backend
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: rust-backend
          template:
            metadata:
              labels:
                app: rust-backend
            spec:
              containers:
              - name: rust-backend
                image: rust-backend:latest
                ports:
                - containerPort: 8080
        ```

    - **rust-backend-service.yaml**:
        ```yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: rust-backend
        spec:
          selector:
            app: rust-backend
          ports:
            - protocol: TCP
              port: 80
              targetPort: 8080
        ```

    - **angular-frontend-deployment.yaml**:
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: angular-frontend
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: angular-frontend
          template:
            metadata:
              labels:
                app: angular-frontend
            spec:
              containers:
              - name: angular-frontend
                image: angular-frontend:latest
                ports:
                - containerPort: 80
        ```

    - **angular-frontend-service.yaml**:
        ```yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: angular-frontend
        spec:
          selector:
            app: angular-frontend
          ports:
            - protocol: TCP
              port: 80
              targetPort: 80
        ```

2. **Deploy to Kubernetes**:
    ```bash
    kubectl apply -f rust-backend-deployment.yaml
    kubectl apply -f rust-backend-service.yaml
    kubectl apply -f angular-frontend-deployment.yaml
    kubectl apply -f angular-frontend-service.yaml
    ```

## Development Setup

### Angular Development

1. **Serve the Angular Application**:
    - Development Mode:
        ```bash
        ng serve
        ```
    - SSR Mode:
        ```bash
        npm run build:ssr
        npm run serve:ssr
        ```

### Rust Development

1. **Run the Rust Backend**:
    ```bash
    cargo run
    ```

2. **Test the GraphQL Endpoint**:
    - Access the GraphQL endpoint at `http://localhost:8080/graphql`.
