#!/bin/bash
# summon-agent.sh
# Summons an agent to handle specific work. Safe to call multiple times.

set -euo pipefail

ROLE=${1:-}
CONTEXT=${2:-"Work available - check GitHub"}

if [[ -z "$ROLE" ]]; then
    echo "Usage: summon-agent.sh <role> [context]"
    echo "Roles: engineer, qa, architect, pm, operator, researcher"
    exit 1
fi

# Auto-detect project paths from script location (can be overridden via env vars)
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
MAX_CONCURRENT_AGENTS=${MAX_CONCURRENT_AGENTS:-3}
AGENT_TIMEOUT=${AGENT_TIMEOUT:-3600}  # 1 hour max per run
PID_DIR="${PID_DIR:-/var/run/${PROJECT_NAME}-agents}"
LOG_DIR="${LOG_DIR:-/var/log/${PROJECT_NAME}-agents}"
WORKTREE_BASE="${WORKTREE_BASE:-/opt/${PROJECT_NAME}/worktrees}"

mkdir -p "$PID_DIR" "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_DIR/summon.log"
}

# Map role to label name
get_label_role() {
    case $1 in
        product-manager|pm) echo "pm" ;;
        *) echo "$1" ;;
    esac
}

# Atomic lock acquisition using mkdir
LOCK_FILE="$PID_DIR/$ROLE.lock"
if ! mkdir "$LOCK_FILE" 2>/dev/null; then
    log "Agent $ROLE already being summoned, skipping"
    exit 0
fi

# Ensure lock is released on exit
cleanup() {
    rmdir "$LOCK_FILE" 2>/dev/null || true
}
trap cleanup EXIT

# Check if agent already running
if [[ -f "$PID_DIR/$ROLE.pid" ]]; then
    PID=$(cat "$PID_DIR/$ROLE.pid")
    if kill -0 "$PID" 2>/dev/null; then
        log "Agent $ROLE already running (PID $PID), passing context"
        # Could potentially send context to running agent via signal/file
        exit 0
    else
        log "Cleaning up stale PID file for $ROLE"
        rm -f "$PID_DIR/$ROLE.pid"
    fi
fi

# Check concurrency limit
running_count=$(find "$PID_DIR" -maxdepth 1 -name "*.pid" -type f 2>/dev/null | wc -l)
if [[ "$running_count" -ge "$MAX_CONCURRENT_AGENTS" ]]; then
    log "Concurrency limit reached ($MAX_CONCURRENT_AGENTS agents), adding label fallback"
    LABEL_ROLE=$(get_label_role "$ROLE")

    # Add a fallback issue so bootstrap watcher picks it up
    # Only if one doesn't already exist
    existing=$(gh issue list --label "agent:$LABEL_ROLE,summon-fallback" --state open --json number --jq 'length' 2>/dev/null || echo "0")
    if [[ "$existing" -eq 0 ]]; then
        gh issue create \
            --title "[Summon Fallback] $ROLE - $(date +%Y-%m-%d-%H%M)" \
            --label "agent:$LABEL_ROLE,summon-fallback" \
            --body "Summoned but concurrency limit reached. Context: $CONTEXT"
    fi
    exit 0
fi

# Determine worktree path
LABEL_ROLE=$(get_label_role "$ROLE")
WORKTREE="$WORKTREE_BASE/${PROJECT_NAME}-$ROLE"
if [[ ! -d "$WORKTREE" ]]; then
    WORKTREE="$WORKTREE_BASE/${PROJECT_NAME}-$LABEL_ROLE"
fi

if [[ ! -d "$WORKTREE" ]]; then
    log "ERROR: No worktree found for $ROLE"
    exit 1
fi

log "Starting agent: $ROLE (context: $CONTEXT)"

# Start agent in background with timeout
cd "$WORKTREE"
timeout --signal=TERM --kill-after=60 "$AGENT_TIMEOUT" \
    claude --print --dangerously-skip-permissions \
    "You are the $LABEL_ROLE agent. $CONTEXT. Read agents/$LABEL_ROLE/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously." \
    >> "$LOG_DIR/$ROLE.log" 2>&1 &

PID=$!
echo "$PID" > "$PID_DIR/$ROLE.pid"

log "Agent $ROLE started with PID $PID"
