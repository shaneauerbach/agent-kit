# CLAUDE.md - Agent Instructions

You are an autonomous agent on the POK project. Follow these rules.

---

## CRITICAL RULES

**1. EXIT WHEN DONE. You are on-demand.**
```bash
# ALWAYS pull before checking for work
git pull origin main
# Check for work (steps 1-4 in work loop)
# If no work remains: exit cleanly (code 0)
# The bootstrap watcher will restart you when new work appears
```

**2. Activate venv before Python commands.**
```bash
source .venv/bin/activate  # Do this FIRST
pytest / ruff / python     # Now these work
```

**3. Never push to another agent's branch.** Only the PR author touches their branch.

**4. Read PR comments before merging.** Check for concerns, not just labels.

**5. Work only on issues assigned to your role.**
- Check for `agent:<your-role>` label before starting work

---

## FORBIDDEN ACTIONS

Never do these:
- **Snooze and retry** - Exit cleanly instead; the bootstrap watcher restarts you
- **Create artificial work** - Only work on real issues/PRs
- **Wait for work to appear** - Exit and let the system restart you when needed

---

## WORK LOOP

Run this loop until no work remains:

0. **ALWAYS PULL FIRST** - `git pull origin main` (get latest work/labels)
1. **Merge your approved PRs** - `gh pr list --author @me --state open`
2. **Fix your PRs with requested changes** - `gh pr list --author @me --label "status:needs-changes"`
3. **Review others' PRs** - `gh pr list --label "needs-review:<your-role>"`
4. **Find new work** - `gh issue list --label "agent:<your-role>"`
5. **No work? EXIT CLEANLY** - Summon agents who need to continue, then exit (code 0)

**Priority:** Merge ready PRs → Review others → New work → Exit

---

## TDD WORKFLOW (Test-Driven Development)

For projects using TDD, the workflow is:

1. **QA writes tests first** - QA creates failing tests based on spec
2. **Engineer implements** - Engineer writes code to pass QA's tests
3. **QA reviews** - QA verifies implementation passes tests

### TDD Issue Pattern
- Each feature has a **QA test issue** (e.g., "QA: tests for feature X") and an **Engineer implementation issue** (e.g., "Implement feature X")
- Engineer issue depends on QA issue (tests must exist first)
- Engineer **must not modify tests** without QA sign-off
- "Done" means all tests from the linked QA issue pass

### TDD Dispute Process
If engineer believes a test is incorrect:
1. Create dispute issue with labels `agent:qa` + `status:blocked`
2. Include counterexample and relevant spec section
3. Add `status:blocked` to engineer issue
4. QA reviews and either fixes test or explains validity
5. If unresolved, create `needs-human` issue

---

## WORKFLOW BASICS

### Starting an Issue
```bash
# 1. Create branch
git checkout -b <your-role>/<issue-num>-short-description

# 2. Work on it
```

### Creating a PR
```bash
# 1. Sync with main first
git fetch origin main && git merge origin/main

# 2. Run checks
source .venv/bin/activate
pytest && ruff check .

# 3. Create PR
gh pr create --title "[#<issue>] Description" --body "Summary...\n\nCloses #<issue>"

# 4. Request reviews (you decide who)
gh pr edit <num> --add-label "needs-review:qa"
```

### Merging Your PR
```bash
# 1. Check ready (no needs-review labels remaining)
gh pr view <num> --json labels --jq '[.labels[].name] | any(startswith("needs-review:"))'

# 2. Read comments for any concerns
gh pr view <num> --comments

# 3. Merge
gh pr merge <num> --squash
```

### Reviewing Others' PRs

> **Do NOT use `gh pr checkout`.** The branch is in the author's worktree. Review remotely with `gh pr diff <num>`.

```bash
# View the diff
gh pr diff <num>

# Approve
gh pr review <num> --comment --body "LGTM - [your feedback]"
gh pr edit <num> --add-label "approved:<your-role>" --remove-label "needs-review:<your-role>"

# Request changes
gh pr review <num> --comment --body "Changes needed: [feedback]"
gh pr edit <num> --add-label "status:needs-changes"
```

---

## LABELS

| Label | Use On | Meaning |
|-------|--------|---------|
| `agent:<role>` | Issues | Assigned to this agent |
| `needs-review:<role>` | PRs | Waiting for this agent's review |
| `approved:<role>` | PRs | This agent approved |
| `status:needs-changes` | PRs | Author must fix issues |
| `needs-human-merge` | PRs | Requires human approval |

---

## RISK PHILOSOPHY

This is a proof-of-concept with real money. Be conservative:
- Small positions ($10-30 per trade)
- Never risk more than $100 total exposure
- When uncertain, choose the safer option
- No YOLO trades

---

## SUMMONING OTHER AGENTS

When you create work for another agent, **summon them directly**:

```bash
# After creating a PR that needs review:
summon-agent.sh qa "Review PR #123 - [brief description]"

# After finding an issue that needs another role:
summon-agent.sh architect "Design input needed for #456"
```

**When to summon vs label:**
| Situation | Action |
|-----------|--------|
| Created a PR that needs review NOW | Summon: `summon-agent.sh qa "Review PR #123"` |
| Found issue that needs design | Summon: `summon-agent.sh architect "Design #456"` |
| Finished implementation, ready for QA | Summon: `summon-agent.sh qa "Verify #123"` |
| Noticed potential improvement | Label: Create issue with `agent:researcher` |

**Heuristic:** If you're blocked waiting for the output, summon. If it's async work, label.

If summon fails (concurrency limit), a fallback label is added automatically.

---

## WHEN BLOCKED OR DISCOVERING GAPS

1. **Need another agent?** Summon them: `summon-agent.sh <role> "context"`
2. **Need human decision?** Create issue with `needs-human` label, add to `asks/human.md`
3. **Found missing docs/research/work?** Don't work around it silently - create an issue for the responsible role
4. **Keep working** on other tasks - don't wait

---

## PROJECT SETUP

**If your worktree is missing `.venv`:**
```bash
./scripts/setup-venv.sh
source .venv/bin/activate
```

**Code standards:** Python 3.11+, type hints, pydantic models, pytest for tests.

---

## REFERENCE DOCS

For detailed information, see:
- `docs/workflow-reference.md` - Full label tables, gh commands, examples
- `HUMAN.md` - Instructions for the human team lead
- `agents/<role>/identity.md` - Your role-specific instructions
