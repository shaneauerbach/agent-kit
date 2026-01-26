#!/bin/bash
set -e

ROLE="$1"
PROMPT="$2"
WORKTREE="/opt/pok/worktrees/pok-${ROLE}"

cd "$WORKTREE"
source /opt/pok/.venv/bin/activate

echo "=== Starting $ROLE agent at $(date) ==="
echo "Worktree: $WORKTREE"
echo "Fetching from origin..."

git fetch origin 2>&1 || echo "git fetch failed"

echo "Starting Claude Code..."
claude --dangerously-skip-permissions "$PROMPT"

echo "=== Agent $ROLE exited at $(date) ==="
