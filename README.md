# TrustyStack

TrustyStack is a hardware benchmarking platform, designed to provide professionals with insights into how various hardware configurations perform in real-world industry software environments.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Submodules](#submodules)
- [Development Workflow](#development-workflow)
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

   ```
   git clone --recursive git@github.com:TrustyStack.git
   cd TrustyStack
   git submodule update --init --recursive
   ```

2. **Set up Environment Variables**:
   Ensure your `.env` file contains the following:

   ```
   DATABASE_URL=postgres://username:password@localhost/database_name
   TEST_DATABASE_URL=postgres://username:password@localhost/test_database_name
   RUST_LOG=info
   ```
   Replace `username`, `password`, and `database_name` with the correct values for your PostgreSQL setup.

3. **Start Docker and build the services**:

   ```
   docker-compose up --build
   ```

4. **Apply database migrations** (if not using automated migration):

   ```
   ./backend/rust/entrypoint.sh
   ```

## Usage

You can interact with the Rust backend API at:
`http://localhost:8080`

## Submodules

To update submodules:

```
git submodule update --remote --merge
```

## Development Workflow

### Development Workflow Tools

The `dev_workflow` directory contains tools and scripts to make the development process easier:

- **dev_run_tmux.sh**: A script to set up a tmux session with panes for running the database and Rust backend, along with a help pane.
- **tmux_help.txt**: A text file containing helpful tmux commands.

### Makefile

A `Makefile` is also available in the `dev_workflow` directory. This includes commonly used commands to:

- Start and stop the development database.
- Run database migrations.
- Start the Rust backend.
- Tail logs from the development database.
- Update submodules and pull the latest changes for the entire repository.

### Updating Repository and Submodules

To ensure your repository and submodules are up-to-date before pushing to the main repository, run:

```
make update
```

This command will:

- Update all submodules to the latest commit.
- Pull the latest changes for the repository.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Open a Pull Request.

### Guidelines

- Write clear, concise commit messages.
- Ensure all tests pass before submitting a PR.
- Update documentation and add tests for new features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.


