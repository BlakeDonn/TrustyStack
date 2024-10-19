#!/bin/bash

SESSION="dev_session"

# Determine the directory of the script (dev_workflow directory)
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Determine the Rust backend directory
RUST_BACKEND_DIR="$SCRIPT_DIR/../backend/rust"

# Determine the Docker Compose directory
DOCKER_COMPOSE_DIR="$SCRIPT_DIR/../infra/cicd/pipelines"

# Path to the help tips file
HELP_FILE="$SCRIPT_DIR/tmux_help.txt"

# Path to the minimal Neovim configuration
MINIMAL_INIT_VIM="$SCRIPT_DIR/minimal_init.vim"

# Function to create the help tips file
create_help_file() {
    cat <<EOL > "$HELP_FILE"
Tmux Commands

| Switch pane:       Prefix + h/j/k/l | Create window:       Prefix + c       |
| Detach session:    Prefix + d          | Next window:         Prefix + L     |
| Kill pane:         Prefix + x          | Previous window:     Prefix + H     |
| Resize pane:       Prefix + Alt+h/j/k/l | Split pane (vert):   Prefix + -     |
| Split pane (horiz):Prefix + |          | View help:           Prefix + ?     |
| Exit tmux: Type exit or Ctrl+d in each pane                  |
EOL
}

# Function to create the minimal Neovim configuration
create_minimal_init_vim() {
    cat <<EOL > "$MINIMAL_INIT_VIM"
set nolist
set nonumber
set norelativenumber
set cursorline
set nowrap
set noswapfile
set nobackup
set noundofile
set nohlsearch
set scrolloff=0
set sidescrolloff=0
set signcolumn=no
set colorcolumn=
set background=dark
set termguicolors
syntax off
filetype off

" Disable auto commenting
autocmd BufRead,BufNewFile *.txt setlocal formatoptions-=c formatoptions-=r formatoptions-=o
EOL
}

# Load environment variables from .env files
load_env() {
    # Load infra/cicd/.env
    if [ -f "$SCRIPT_DIR/../backend/rust/.env" ]; then
        export $(grep -v '^#' "$SCRIPT_DIR/../backend/rust/.env" | xargs)
    else
        echo "Warning: infra/cicd/.env not found."
    fi

    # Load backend/rust/.env
    if [ -f "$SCRIPT_DIR/../infra/cicd/.env" ]; then
        export $(grep -v '^#' "$SCRIPT_DIR/../infra/cicd/.env" | xargs)
    else
        echo "Warning: backend/rust/.env not found."
    fi
}

# Load the environment variables
load_env

# Create help tips and Neovim config if they don't exist
if [ ! -f "$HELP_FILE" ]; then
    create_help_file
fi

if [ ! -f "$MINIMAL_INIT_VIM" ]; then
    create_minimal_init_vim
fi

# Start the tmux session and configure panes if it doesn't already exist
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    # Session doesn't exist; create it and set up panes
    tmux new-session -d -s $SESSION -c "$DOCKER_COMPOSE_DIR" -n 'DevSession'

    # Get the main pane ID (the one that was just created)
    MAIN_PANE=$(tmux list-panes -t $SESSION:0 -F '#{pane_id}' | head -n1)

    # Split the main pane vertically into top (80%) and bottom (20%) panes
    tmux split-window -v -p 20 -t $SESSION:0

    # Get the bottom pane ID
    BOTTOM_PANE=$(tmux list-panes -t $SESSION:0 -F '#{pane_id}' | tail -n1)

    # Split the main (top) pane horizontally into left and right panes
    tmux select-pane -t $MAIN_PANE
    tmux split-window -h -p 50 -t $MAIN_PANE

    # Get the pane IDs
    PANE_IDS=($(tmux list-panes -t $SESSION:0 -F '#{pane_id}'))
    TOP_LEFT_PANE=${PANE_IDS[0]}
    TOP_RIGHT_PANE=${PANE_IDS[1]}
    BOTTOM_LEFT_PANE=${PANE_IDS[2]}
    BOTTOM_RIGHT_PANE=${PANE_IDS[3]}

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

    # Split the bottom pane horizontally into left (blank) and right (help) panes
    tmux select-pane -t $BOTTOM_PANE
    tmux split-window -h -p 50 -t $BOTTOM_PANE

    # Get the help pane ID
    HELP_PANE=$(tmux list-panes -t $SESSION:0 -F '#{pane_id}' | tail -n1)

    # Send commands to the help pane to open Neovim with the help file
    tmux send-keys -t "$HELP_PANE" "clear" C-m
    tmux send-keys -t "$HELP_PANE" "nvim -u '$MINIMAL_INIT_VIM' -R '$HELP_FILE'" C-m
fi

# Function to gracefully kill the tmux session and all running processes
cleanup() {
    echo "Killing tmux session and all running processes..."
    tmux kill-session -t $SESSION
    exit
}

# Trap SIGINT and SIGTERM to run cleanup
trap cleanup SIGINT SIGTERM

# Attach to the session in the current terminal
tmux attach-session -t $SESSION

