#!/bin/bash
# /opt/pok/agent-kit/scripts/bootstrap-watcher.sh
# Runs hourly via cron to catch any orphaned work

set -euo pipefail

PID_DIR="/var/run/pok-agents"
LOG_DIR="/var/log/pok-agents"
SUMMON_SCRIPT="/opt/pok/agent-kit/scripts/summon-agent.sh"
REPO_DIR="/opt/pok"
ROLES=("engineer" "qa" "architect" "pm" "operator" "researcher")

mkdir -p "$PID_DIR" "$LOG_DIR"

# Change to repo directory for gh commands
cd "$REPO_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Bootstrap: $1" >> "$LOG_DIR/bootstrap.log"
}

check_work_for_role() {
    local role=$1

    # Count issues assigned to this role
    local issues=$(gh issue list --label "agent:$role" --state open --json number --jq 'length' 2>/dev/null || echo "0")

    # Count PRs needing review from this role
    local reviews=$(gh pr list --label "needs-review:$role" --state open --json number --jq 'length' 2>/dev/null || echo "0")

    # Count PRs authored by this role with requested changes
    local changes=$(gh pr list --state open --json headRefName,labels \
        --jq "[.[] | select(.headRefName | startswith(\"$role/\")) | select(.labels[].name == \"status:needs-changes\")] | length" 2>/dev/null || echo "0")

    echo $((issues + reviews + changes))
}

is_agent_running() {
    local role=$1
    local pid_file="$PID_DIR/$role.pid"

    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$pid_file"
        fi
    fi
    return 1
}

log "Starting bootstrap check"

for role in "${ROLES[@]}"; do
    # Skip if agent running
    if is_agent_running "$role"; then
        continue
    fi

    # Check for work
    work_count=$(check_work_for_role "$role")

    if [[ "$work_count" -gt 0 ]]; then
        log "Found $work_count orphaned work items for $role, summoning"
        "$SUMMON_SCRIPT" "$role" "Bootstrap: Found $work_count pending work items"
    fi
done

log "Bootstrap check complete"
