# Makefile for Development Workflow Management

# Default environment variables
RUST_BACKEND_DIR := backend/rust
DEV_COMPOSE_FILE := infra/cicd/pipelines/docker-compose.dev.yml
DOCKER_COMPOSE_CMD := docker-compose -f $(DEV_COMPOSE_FILE)

# Default target
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make dev                 - Start the development database"
	@echo "  make dev-down            - Stop the development database"
	@echo "  make migrate             - Run database migrations"
	@echo "  make clean               - Stop the database and remove Docker volumes"
	@echo "  make tmux-dev            - Run tmux-based development environment"
	@echo "  make submodule-init      - Initialize Git submodules"
	@echo "  make submodule-update    - Update Git submodules to the latest commit"
	@echo "  make submodule-sync      - Sync submodules with remote repositories"
	@echo "  make prepare-pr          - Prepare repository and submodules for a Pull Request"

# Start development database
.PHONY: dev
dev:
	$(DOCKER_COMPOSE_CMD) up -d db

# Stop development database
.PHONY: dev-down
dev-down:
	$(DOCKER_COMPOSE_CMD) down

# Clean up all containers and volumes
.PHONY: clean
clean:
	$(DOCKER_COMPOSE_CMD) down -v

# Run database migrations
.PHONY: migrate
migrate:
	cd $(RUST_BACKEND_DIR) && cargo run --bin migrate

# Start the tmux-based development environment
.PHONY: tmux-dev
tmux-dev:
	./dev_workflow/dev_run_tmux.sh

# Initialize Git submodules
.PHONY: submodule-init
submodule-init:
	@echo "Initializing Git submodules..."
	git submodule init
	@echo "Updating Git submodules..."
	git submodule update

# Update Git submodules to the latest commit on their respective branches
.PHONY: submodule-update
submodule-update:
	@echo "Fetching latest changes for all submodules..."
	git submodule update --remote --merge

# Sync submodules with their remote repositories
.PHONY: submodule-sync
submodule-sync:
	@echo "Synchronizing submodules with remote repositories..."
	git submodule sync --recursive
	@echo "Updating submodules..."
	git submodule update --init --recursive

# Prepare repository and submodules for a Pull Request
.PHONY: prepare-pr
prepare-pr: submodule-sync submodule-update
	@echo "Pulling latest changes for the main repository..."
	git pull origin $(shell git rev-parse --abbrev-ref HEAD)
	@echo "Ensuring all submodules are up-to-date..."
	git submodule update --remote --merge
	@echo "All submodules and the main repository are up-to-date and ready for a Pull Request."

