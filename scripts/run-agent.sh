#!/bin/bash
set -e

ROLE="$1"
PROMPT="$2"

# Auto-detect project paths from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If script is in agent-kit/scripts/, project root is two levels up
if [[ "$SCRIPT_DIR" == */agent-kit/scripts ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
    # Script is directly in project scripts/
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
# Use PROJECT_NAME env var if set, otherwise derive from directory
PROJECT_NAME="${PROJECT_NAME:-$(basename "$PROJECT_ROOT")}"

# Configuration - can be overridden via environment variables
WORKTREE_BASE="${WORKTREE_BASE:-/opt/${PROJECT_NAME}/worktrees}"
VENV_PATH="${VENV_PATH:-/opt/${PROJECT_NAME}/.venv}"
WORKTREE="${WORKTREE_BASE}/${PROJECT_NAME}-${ROLE}"

cd "$WORKTREE"
source "$VENV_PATH/bin/activate"

echo "=== Starting $ROLE agent at $(date) ==="
echo "Worktree: $WORKTREE"
echo "Fetching from origin..."

git fetch origin 2>&1 || echo "git fetch failed"

echo "Starting Claude Code..."
claude --dangerously-skip-permissions "$PROMPT"

echo "=== Agent $ROLE exited at $(date) ==="
