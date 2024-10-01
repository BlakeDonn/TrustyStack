![Rust Tests](https://github.com/BlakeDonn/trustystack-rust/actions/workflows/rust-tests.yml/badge.svg)

# TrustyStack

TrustyStack is a hardware benchmarking platform, designed to provide professionals with insights into how various hardware configurations perform in real-world industry software environments.

## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Submodules](#submodules)
- [Contributing](#contributing)
- [License](#license)

## Features
- **Rust Backend**: Efficient API built in Rust.
- **Database**: PostgreSQL backend for storing benchmarking data.
- **Modular Submodules**: Easily extendable architecture using Git submodules.
- **CI/CD Pipelines**: Automated deployment using GitHub Actions.

## Architecture
TrustyStack is structured into different modules:
- **Backend (Rust)**: Manages benchmarking jobs and integrates with the database.
- **Frontend (React)**: Upcoming user interface.
- **Database**: PostgreSQL for data persistence.

## Setup Instructions

1. **Clone the repository and initialize submodules**:
    
    ```bash
    git clone --recursive git@github.com:BlakeDonn/TrustyStack.git
    git submodule update --init --recursive
    ```

2. **Start Docker and build the services**:
    
    ```bash
    docker-compose up --build
    ```

3. **Apply database migrations**:
    
    ```bash
    ./entrypoint.sh
    ```

4. **Environment Variables**:
    Ensure your `.env` file contains the following:

    ```bash
    DATABASE_URL=postgres://username:password@localhost/database_name
    TEST_DATABASE_URL=postgres://username:password@localhost/test_database_name
    RUST_LOG=info
    ```

## Usage
You can interact with the Rust backend API at:
`http://localhost:8080`

## Submodules
To update submodules:

```bash
git submodule update --remote --merge
``````
