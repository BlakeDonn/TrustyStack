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
