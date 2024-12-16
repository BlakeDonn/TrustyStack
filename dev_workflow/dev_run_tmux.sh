#!/bin/bash

SESSION="dev_session"

# Determine the directory of the script (dev_workflow directory)
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Determine the Rust backend directory
RUST_BACKEND_DIR="$SCRIPT_DIR/../backend/rust"

# Determine the Docker Compose directory
DOCKER_COMPOSE_DIR="$SCRIPT_DIR/../infra/cicd/pipelines"

# Determine the Frontend directory
FRONTEND_WEB_DIR="$SCRIPT_DIR/../frontend/web"

# Load environment variables from .env files
load_env() {
    # Load backend/rust/.env
    if [ -f "$SCRIPT_DIR/../backend/rust/.env" ]; then
        export $(grep -v '^#' "$SCRIPT_DIR/../backend/rust/.env" | xargs)
    else
        echo "Warning: backend/rust/.env not found."
    fi

    # Load infra/cicd/.env
    if [ -f "$SCRIPT_DIR/../infra/cicd/.env" ]; then
        export $(grep -v '^#' "$SCRIPT_DIR/../infra/cicd/.env" | xargs)
    else
        echo "Warning: infra/cicd/.env not found."
    fi
}

# Function to attempt to start Docker if it's not running
ensure_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker does not seem to be running. Attempting to start Docker..."

        # Try systemd if available
        if command -v systemctl >/dev/null 2>&1; then
            if sudo systemctl start docker; then
                echo "Docker started successfully via systemctl."
                return
            fi
        fi

        # Try service command if available
        if command -v service >/dev/null 2>&1; then
            if sudo service docker start; then
                echo "Docker started successfully via service command."
                return
            fi
        fi

        # MacOS check: try Docker Desktop if available
        if [[ "$(uname)" == "Darwin" ]]; then
            echo "Attempting to start Docker Desktop on macOS..."
            if open -a Docker; then
                # Wait a bit for Docker to start
                echo "Waiting for Docker Desktop to start..."
                sleep 10
                if docker info >/dev/null 2>&1; then
                    echo "Docker Desktop started successfully."
                    return
                fi
            fi
        fi

        # If we reached here, we couldn't start Docker automatically
        echo "Failed to start Docker automatically. Please start Docker manually and rerun the script."
        exit 1
    fi
}

# Load the environment variables
load_env

# Ensure Docker is running
ensure_docker_running

# Start the tmux session and configure panes if it doesn't already exist
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    # Session doesn't exist; create it
    tmux new-session -d -s $SESSION -c "$DOCKER_COMPOSE_DIR" -n 'DevSession'

    # Get the main pane ID (the one that was just created)
    MAIN_PANE=$(tmux list-panes -t $SESSION:0 -F '#{pane_id}' | head -n1)

    # Split the main pane vertically into top (80%) and bottom (20%) panes
    tmux split-window -v -p 20 -t $SESSION:0

    # Get the bottom pane ID
    BOTTOM_PANE=$(tmux list-panes -t $SESSION:0 -F '#{pane_id}' | tail -n1)

    # Split the top pane horizontally into left and right panes
    tmux select-pane -t $MAIN_PANE
    tmux split-window -h -p 50 -t $MAIN_PANE

    # Get the pane IDs (top-left, top-right, bottom)
    PANE_IDS=($(tmux list-panes -t $SESSION:0 -F '#{pane_id}'))
    TOP_LEFT_PANE=${PANE_IDS[0]}
    TOP_RIGHT_PANE=${PANE_IDS[1]}
    # After the top split, bottom is still a single pane before we split it horizontally
    BOTTOM_SINGLE_PANE=${PANE_IDS[2]}

    # Start the database in the top-left pane
    tmux send-keys -t "$TOP_LEFT_PANE" "cd \"$DOCKER_COMPOSE_DIR\"" C-m
    tmux send-keys -t "$TOP_LEFT_PANE" "docker-compose -f docker-compose.dev.yml up" C-m

    # Run migrations and start the backend in the top-right pane
    tmux send-keys -t "$TOP_RIGHT_PANE" "cd \"$RUST_BACKEND_DIR\"" C-m
    tmux send-keys -t "$TOP_RIGHT_PANE" "echo 'Waiting for the database to be ready...'" C-m
    tmux send-keys -t "$TOP_RIGHT_PANE" "until pg_isready -h localhost -p 5432 -U \$POSTGRES_USER -d \$POSTGRES_DB; do sleep 1; done" C-m
    tmux send-keys -t "$TOP_RIGHT_PANE" "echo 'Database is ready. Running migrations...'" C-m
    tmux send-keys -t "$TOP_RIGHT_PANE" "cargo run --bin migrate" C-m
    tmux send-keys -t "$TOP_RIGHT_PANE" "echo 'Starting the Rust backend with hot reloading...'" C-m
    tmux send-keys -t "$TOP_RIGHT_PANE" "cargo watch -x \"run --bin rust-backend\"" C-m

    # Now split the bottom pane horizontally into two equal panes
    tmux select-pane -t $BOTTOM_SINGLE_PANE
    tmux split-window -h -p 50 -t $BOTTOM_SINGLE_PANE

    # Get the bottom-left and bottom-right pane IDs
    BOTTOM_PANES=($(tmux list-panes -t $SESSION:0 -F '#{pane_id}' | tail -n2))
    BOTTOM_LEFT_PANE=${BOTTOM_PANES[0]}
    BOTTOM_RIGHT_PANE=${BOTTOM_PANES[1]}

    # In the bottom-left pane, run the frontend
    tmux send-keys -t "$BOTTOM_LEFT_PANE" "cd \"$FRONTEND_WEB_DIR\"" C-m
    tmux send-keys -t "$BOTTOM_LEFT_PANE" "yarn dev" C-m

    # Bottom-right pane: leave it as a regular shell (no tmux commands shown)
    tmux send-keys -t "$BOTTOM_RIGHT_PANE" "clear" C-m
fi

# Function to gracefully kill the tmux session and all running processes
cleanup() {
    echo "Killing tmux session and all running processes..."
    tmux kill-session -t $SESSION
    exit
}

# Trap SIGINT and SIGTERM to run cleanup
trap cleanup SIGINT SIGTERM

# Attach to the session
tmux attach-session -t $SESSION

