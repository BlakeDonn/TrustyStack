# Makefile for Development Workflow Management
MAKEFILE_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))


# Development Environment Variables
RUST_BACKEND_DIR := $(MAKEFILE_DIR)/backend/rust
DEV_COMPOSE_FILE := $(MAKEFILE_DIR)/infra/cicd/pipelines/docker-compose.dev.yml
DEV_ENV_FILE := $(MAKEFILE_DIR)/infra/cicd/pipelines/dev.env
DEV_DOCKER_COMPOSE_CMD := docker-compose -f $(DEV_COMPOSE_FILE) --env-file $(DEV_ENV_FILE)

# Production Environment Variables
PROD_COMPOSE_FILE := $(MAKEFILE_DIR)/infra/cicd/pipelines/docker-compose.prod.yml
PROD_ENV_FILE := $(MAKEFILE_DIR)/infra/cicd/pipelines/prod.env
PROD_DOCKER_COMPOSE_CMD := docker-compose -f $(PROD_COMPOSE_FILE) --env-file $(PROD_ENV_FILE)

# Load environment variables from .env files
ifneq (,$(wildcard $(DEV_ENV_FILE)))
    include $(DEV_ENV_FILE)
    export $(shell sed 's/=.*//' $(DEV_ENV_FILE))
endif

ifneq (,$(wildcard $(PROD_ENV_FILE)))
    include $(PROD_ENV_FILE)
    export $(shell sed 's/=.*//' $(PROD_ENV_FILE))
endif

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
	@echo "  make prod-up             - Start the production database and services"
	@echo "  make prod-down           - Stop the production database and services"
	@echo "  make prod-clean          - Clean production containers and volumes"

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
	# Start production services
.PHONY: prod-up
prod-up:
	$(PROD_DOCKER_COMPOSE_CMD) up -d

# Stop production services
.PHONY: prod-down
prod-down:
	$(PROD_DOCKER_COMPOSE_CMD) down

# Clean up production containers and volumes
.PHONY: prod-clean
prod-clean:
	$(PROD_DOCKER_COMPOSE_CMD) down -v


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

