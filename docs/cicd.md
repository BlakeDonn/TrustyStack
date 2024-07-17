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
