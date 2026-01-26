#!/bin/bash
# Report which agents have pending work
# Run this before snoozing to provide visibility to the human team lead

set -e

echo ""
echo "=== Agents with pending work ==="
echo ""

# List of known agent roles
AGENTS=("engineer" "researcher" "qa" "pm" "architect")

agents_with_work=0

for agent in "${AGENTS[@]}"; do
    # Count issues assigned to this agent
    issue_count=$(gh issue list --label "agent:$agent" --state open --json number --jq 'length')

    # Count PRs needing review by this agent
    review_count=$(gh pr list --label "needs-review:$agent" --state open --json number --jq 'length')

    # Build status string (only if there's work)
    status_parts=()
    if [ "$issue_count" -gt 0 ]; then
        status_parts+=("$issue_count issue(s)")
    fi
    if [ "$review_count" -gt 0 ]; then
        status_parts+=("$review_count PR(s) to review")
    fi

    # Only print agents that have work
    if [ ${#status_parts[@]} -gt 0 ]; then
        IFS=', '; echo "agent:$agent - ${status_parts[*]}"
        agents_with_work=$((agents_with_work + 1))
    fi
done

if [ "$agents_with_work" -eq 0 ]; then
    echo "(none)"
fi

# Also show PRs needing changes (across all authors)
needs_changes_count=$(gh pr list --label "status:needs-changes" --state open --json number --jq 'length')
if [ "$needs_changes_count" -gt 0 ]; then
    echo ""
    echo "PRs with status:needs-changes: $needs_changes_count"
    gh pr list --label "status:needs-changes" --state open --json number,title,author --jq '.[] | "  #\(.number) by \(.author.login): \(.title)"'
fi

echo ""
