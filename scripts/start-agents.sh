#!/bin/bash

# Auto-detect project paths from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If script is in agent-kit/scripts/, project root is two levels up
if [[ "$SCRIPT_DIR" == */agent-kit/scripts ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    RUN_AGENT_SCRIPT="$SCRIPT_DIR/run-agent.sh"
else
    # Script is directly in project scripts/
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    RUN_AGENT_SCRIPT="$SCRIPT_DIR/run-agent.sh"
fi
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# Configuration - can be overridden via environment variables
LOG_DIR="${LOG_DIR:-/var/log/${PROJECT_NAME}-agents}"
WORKTREE_BASE="${WORKTREE_BASE:-/opt/${PROJECT_NAME}/worktrees}"

# Agent prompts
declare -A PROMPTS
PROMPTS[architect]="You are the Architect agent. Read agents/architect/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[engineer]="You are the Engineer agent. Read agents/engineer/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[qa]="You are the QA agent. Read agents/qa/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[pm]="You are the Product Manager agent. Read agents/product-manager/identity.md, context.md, feedback.md, received-feedback.md and follow CLAUDE.md workflow."
PROMPTS[researcher]="You are the Researcher agent. Read agents/researcher/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[operator]="You are the Operator agent. Read agents/operator/identity.md, context.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."

ROLES=("architect" "engineer" "qa" "pm" "researcher" "operator")

mkdir -p "$LOG_DIR"

for role in "${ROLES[@]}"; do
    session="agent-${role}"
    worktree="${WORKTREE_BASE}/${PROJECT_NAME}-${role}"
    prompt="${PROMPTS[$role]}"
    logfile="${LOG_DIR}/${role}.log"

    # Kill existing session
    su - "$PROJECT_NAME" -c "tmux kill-session -t $session 2>/dev/null" || true

    # Start new session with logging and sleep fallback
    su - "$PROJECT_NAME" -c "tmux new-session -d -s $session \"$RUN_AGENT_SCRIPT $role \\\"$prompt\\\" 2>&1 | tee $logfile; sleep 600\""

    echo "Started $role in tmux session: $session"
    echo "  Worktree: $worktree"
    echo "  Log: $logfile"
    sleep 3
done

echo ""
echo "All agents started. Use su - $PROJECT_NAME -c tmux ls to see sessions."
echo "Attach: su - $PROJECT_NAME -c tmux attach -t agent-pm"
echo "Logs: $LOG_DIR/*.log"
