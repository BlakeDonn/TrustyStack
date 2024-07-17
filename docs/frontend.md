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
