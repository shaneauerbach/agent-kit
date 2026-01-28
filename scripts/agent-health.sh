#!/bin/bash
# agent-health.sh
# Run via cron every 15 minutes to clean up stale state

set -euo pipefail

# Auto-detect project paths from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If script is in agent-kit/scripts/, project root is two levels up
if [[ "$SCRIPT_DIR" == */agent-kit/scripts ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
    # Script is directly in project scripts/
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# Configuration - can be overridden via environment variables
PID_DIR="${PID_DIR:-/var/run/${PROJECT_NAME}-agents}"
LOG_DIR="${LOG_DIR:-/var/log/${PROJECT_NAME}-agents}"
LOG_FILE="$LOG_DIR/health.log"

mkdir -p "$PID_DIR" "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Health: $1" >> "$LOG_FILE"
}

# Clean up stale PID files
for pid_file in "$PID_DIR"/*.pid; do
    [[ -f "$pid_file" ]] || continue
    pid=$(cat "$pid_file")
    if ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$pid_file"
        log "Cleaned up stale PID: $pid_file"
    fi
done

# Clean up stale lock directories
for lock_dir in "$PID_DIR"/*.lock; do
    [[ -d "$lock_dir" ]] || continue
    # If lock is older than 5 minutes, it's probably stale
    if [[ $(find "$lock_dir" -mmin +5 2>/dev/null) ]]; then
        rmdir "$lock_dir" 2>/dev/null && log "Cleaned up stale lock: $lock_dir"
    fi
done

# Kill orphaned Claude processes (running longer than 2 hours)
# This is a safety net - summon-agent.sh uses timeout, but this catches edge cases
MAX_AGE_SECONDS=7200  # 2 hours
while read -r pid etime; do
    [[ -z "$pid" ]] && continue
    if [[ "$etime" -gt "$MAX_AGE_SECONDS" ]]; then
        log "Killing orphaned Claude process $pid (running for ${etime}s)"
        kill "$pid" 2>/dev/null || true
    fi
done < <(pgrep -f "claude" | while read -r p; do
    # Get elapsed time in seconds for each claude process
    age=$(ps -o etimes= -p "$p" 2>/dev/null | tr -d ' ')
    [[ -n "$age" ]] && echo "$p $age"
done)

# Report current state
running=$(ls -1 "$PID_DIR"/*.pid 2>/dev/null | wc -l || echo 0)
log "Health check complete. Running agents: $running"
