# Human Team Lead Guide

Instructions for the human overseeing the agent team.

---

## Quick Start

### First-Time Setup
```bash
# 1. Set up global permissions (one-time, applies to all worktrees)
# Copy the permissions block from .claude/settings.json to ~/.claude/settings.json

# 2. Create worktrees for parallel agents
cd ~/github/<project>
git worktree add ../<project>-engineer main
git worktree add ../<project>-qa main
git worktree add ../<project>-pm main
```

### Launch Agents
```bash
# Engineer
cd ~/github/<project>-engineer && claude "You are the Engineer agent. Read agents/engineer/identity.md, context.md, feedback.md, received-feedback.md and follow CLAUDE.md workflow."

# QA
cd ~/github/<project>-qa && claude "You are the QA agent. Read agents/qa/identity.md, context.md, feedback.md, received-feedback.md and follow CLAUDE.md workflow."

# PM
cd ~/github/<project>-pm && claude "You are the Product Manager agent. Read agents/product-manager/identity.md, context.md, feedback.md, received-feedback.md and follow CLAUDE.md workflow."
```

### Daily Check-In
```bash
gh pr list --label "needs-human-merge"   # PRs needing your approval
gh issue list --label "needs-human"       # Questions needing your input
cat asks/human.md                         # Dashboard view
```

---

## Processing Agent Asks

Use `/human` command to walk through pending asks, or manually:

### Approve a PR
```bash
# Add approval label, remove review request
gh api repos/<owner>/<project>/issues/<num>/labels --method POST --input - <<< '["approved:human"]'
gh api repos/<owner>/<project>/issues/<num>/labels/needs-human-merge --method DELETE
```

### Answer a Question
```bash
# Comment on the issue with your decision
gh issue comment <num> --body "Decision: [your answer]"
gh issue close <num>  # if resolved
```

### Update Dashboard
Edit `asks/human.md` - move resolved items to the Resolved table.

---

## Worktree Management

```bash
git worktree list                              # See all worktrees
git worktree add ../<project>-architect main   # Add more agents
git worktree remove ../<project>-engineer      # Remove a worktree
```

Each agent needs its own worktree to avoid git conflicts.

---

## When Agents Stop Incorrectly

If an agent says "my work is complete" or gives a "session summary", they've violated the daemon rule. Just restart them - they should snooze and check for work, not stop.

---

## Risk Limits (Reference)

Current conservative limits for live trading:
- $100 max total exposure
- $30 max per market
- $10 max single trade
- $20 daily loss circuit breaker

These are configured in the FLB executor. Change requires code update.

---

## PM Project Termination Authority

The PM has been granted authority to **recommend** project termination. This section explains what that means for you.

### What the PM Can Do

The PM monitors overall project health and can:
- Track strategy performance over time
- Identify when the project is stalled or failing
- Recommend termination if specific criteria are met
- Propose alternative directions that might require your help

### Termination Criteria

The PM should recommend termination only if **ALL** of these conditions are true for 30+ days:
1. No profitable strategy (negative combined P&L for 30 days)
2. No new opportunities identified (0 opportunity issues for 14 days)
3. All strategies exhausted (all abandoned, none in development)
4. No viable path forward identified

### What You Need to Do

When the PM creates a termination recommendation:

1. **Review the evidence** - The PM will provide a detailed assessment with metrics
2. **Consider alternatives** - The PM may suggest pivots (education, different market, manual trading)
3. **Make the final call** - You decide to:
   - Continue (optionally with guidance)
   - Pivot to an alternative
   - Wind down the project

### Your Role

- You retain **final decision authority** on project continuation
- You can **override** with explicit continuation request at any time
- The PM's job is to give you honest information, not make the decision for you

### If You Decide to Continue Despite a Recommendation

Simply comment on the termination recommendation issue:
```bash
gh issue comment <num> --body "Decision: Continue project. Rationale: [your reasoning]"
gh issue close <num>
```

The PM will respect your decision and continue working.

---

## Useful Commands

```bash
# See all open PRs
gh pr list --state open

# See what each agent is working on
gh issue list --label "agent:engineer" --state open
gh issue list --label "agent:qa" --state open

# Check CI status on a PR
gh pr checks <num>

# View PR comments
gh pr view <num> --comments
```
