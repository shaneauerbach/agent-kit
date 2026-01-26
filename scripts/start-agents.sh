#!/bin/bash

# Agent prompts
declare -A PROMPTS
PROMPTS[architect]="You are the Architect agent. Read agents/architect/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[engineer]="You are the Engineer agent. Read agents/engineer/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[qa]="You are the QA agent. Read agents/qa/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[pm]="You are the Product Manager agent. Read agents/product-manager/identity.md, context.md, feedback.md, received-feedback.md and follow CLAUDE.md workflow."
PROMPTS[researcher]="You are the Researcher agent. Read agents/researcher/identity.md, context.md, feedback.md, received-feedback.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."
PROMPTS[operator]="You are the Operator agent. Read agents/operator/identity.md, context.md then IMMEDIATELY start the autonomous work loop from CLAUDE.md. Do NOT wait for instructions - check GitHub for work and execute autonomously."

ROLES=("architect" "engineer" "qa" "pm" "researcher" "operator")

mkdir -p /var/log/pok-agents

for role in "${ROLES[@]}"; do
    session="agent-${role}"
    worktree="/opt/pok/worktrees/pok-${role}"
    prompt="${PROMPTS[$role]}"
    logfile="/var/log/pok-agents/${role}.log"
    
    # Kill existing session
    su - pok -c "tmux kill-session -t $session 2>/dev/null" || true
    
    # Start new session with logging and sleep fallback
    su - pok -c "tmux new-session -d -s $session \"/opt/pok/scripts/run-agent.sh $role \\\"$prompt\\\" 2>&1 | tee $logfile; sleep 600\""
    
    echo "Started $role in tmux session: $session"
    echo "  Worktree: $worktree"
    echo "  Log: $logfile"
    sleep 3
done

echo ""
echo "All agents started. Use su - pok -c tmux ls to see sessions."
echo "Attach: su - pok -c tmux attach -t agent-pm"
echo "Logs: /var/log/pok-agents/*.log"
