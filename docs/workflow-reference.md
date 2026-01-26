# Workflow Reference

Detailed reference for agent workflows. See `CLAUDE.md` for the essentials.

## Agent Startup Helpers

- `scripts/auto-accept-bypass.exp` auto-accepts the permissions dialog and boots an agent with the standard startup prompt.

---

## Label Reference

### Issue Labels (assign work)

| Label | Meaning |
|-------|---------|
| `agent:pm` | Assigned to PM |
| `agent:architect` | Assigned to Architect |
| `agent:engineer` | Assigned to Engineer |
| `agent:qa` | Assigned to QA |
| `agent:researcher` | Assigned to Researcher |
| `needs-human` | Needs human team lead input |
| `priority:high` | High priority |
| `priority:medium` | Medium priority |
| `priority:low` | Low priority |
| `type:feature` | New feature |
| `type:bug` | Bug fix |
| `type:research` | Research task |
| `status:blocked` | Blocked on dependency |
| `status:in-progress` | Currently being worked on |

### Milestone Planning Labels (ADR-019)

| Label | Added By | Meaning |
|-------|----------|---------|
| `opportunity:strategy` | Researcher | New trading strategy idea |
| `opportunity:optimization` | Any agent | Performance improvement opportunity |
| `opportunity:infrastructure` | Architect | System improvement opportunity |
| `feasibility:low` | Architect | Easy to implement (days) |
| `feasibility:medium` | Architect | Moderate effort (1-2 weeks) |
| `feasibility:high` | Architect | Significant effort (weeks+) |
| `milestone-proposal` | PM | Proposed milestone for human approval |
| `needs-human-approval` | PM | Requires human sign-off before starting |

**Workflow:** Researcher creates opportunity issues → Architect adds feasibility labels → PM groups into milestone proposals → Human approves.

### PR Labels (reviews)

| Label | Added By | Meaning |
|-------|----------|---------|
| `needs-review:qa` | PR author | QA should review |
| `needs-review:architect` | PR author | Architect should review |
| `needs-review:engineer` | PR author | Engineer should review |
| `needs-review:pm` | PR author | PM should review |
| `needs-review:researcher` | PR author | Researcher should review |
| `needs-human-merge` | PR author | Human must approve before merge |
| `approved:qa` | QA | QA approved |
| `approved:architect` | Architect | Architect approved |
| `approved:engineer` | Engineer | Engineer approved |
| `approved:pm` | PM | PM approved |
| `approved:researcher` | Researcher | Researcher approved |
| `approved:human` | Human | Human approved |
| `status:needs-changes` | Reviewer | Author must address feedback |

---

## GitHub Commands Reference

### Issues

```bash
# List issues assigned to you
gh issue list --label "agent:<role>" --state open

# View issue details
gh issue view <num>

# View issue comments
gh issue view <num> --comments

# Claim an issue
gh issue comment <num> --body "Picking this up"

# Create an issue
gh issue create --title "Title" --body "Body" --label "agent:engineer" --label "priority:high"

# Close an issue
gh issue close <num>
```

### Pull Requests

```bash
# List PRs needing your review
gh pr list --label "needs-review:<role>" --state open

# List your open PRs
gh pr list --author @me --state open

# View PR details
gh pr view <num>

# View PR comments
gh pr view <num> --comments

# View PR diff
gh pr diff <num>

# Check CI status
gh pr checks <num>

# Create PR
gh pr create --title "[#<issue>] Title" --body "Summary..."

# Add labels
gh pr edit <num> --add-label "needs-review:qa"

# Remove labels
gh pr edit <num> --remove-label "needs-review:qa"

# Merge PR (squash)
gh pr merge <num> --squash
```

### Label Management via API

When `gh pr edit` fails (classic projects error), use the API:

```bash
# Add label
gh api repos/OWNER/REPO/issues/<num>/labels --method POST --input - <<< '["label-name"]'

# Remove label
gh api repos/OWNER/REPO/issues/<num>/labels/label-name --method DELETE
```

---

## Branch Naming Convention

```
<agent>/<issue-number>-<short-description>
```

Examples:
- `engineer/42-kalshi-client`
- `qa/55-test-infrastructure`
- `pm/30-roadmap-update`

---

## PR Title Convention

```
[#<issue>] <description>
```

Examples:
- `[#42] Implement Kalshi API client`
- `[#55] Add test fixtures for trading`

---

## Merge Criteria

A PR is ready to merge when:
1. CI passes
2. No `needs-review:*` labels remain
3. If `needs-human-merge` present, `approved:human` must also be present

---

## Review Guidelines

### Who to Request Reviews From

| Change Type | Typically Request |
|-------------|-------------------|
| Implementation code | `needs-review:qa` |
| Architecture changes | `needs-review:architect` |
| Documentation | `needs-review:researcher` |
| Test-only changes | `needs-review:engineer` |
| New features | `needs-review:qa` + `needs-review:architect` |
| Config/auth changes | `needs-human-merge` |

### Completing a Review

**Approve:**
```bash
gh pr review <num> --comment --body "LGTM - [feedback]"
gh pr edit <num> --add-label "approved:<role>" --remove-label "needs-review:<role>"
```

**Request changes:**
```bash
gh pr review <num> --comment --body "Changes needed: [feedback]"
gh pr edit <num> --add-label "status:needs-changes"
# Keep needs-review label so you re-review after fixes
```

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Issues & PRs                          │
│  (Source of truth for all work, communication, and reviews)     │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
    ┌─────────┐          ┌─────────┐          ┌─────────┐
    │Architect│◄────────►│Engineer │◄────────►│   QA    │
    │         │  reviews │         │  reviews │         │
    └─────────┘          └─────────┘          └─────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ▼
                    ┌──────────────────┐
                    │   Shared Repo    │
                    │  (main branch)   │
                    └──────────────────┘
```

---

## Cross-Agent Feedback

When reviewing PRs, you can include process feedback:

```markdown
## QA Review: APPROVED

### Code Review
- [x] Tests pass
- [x] Code follows standards

### Process Feedback (optional)
**What worked well:** Clear commit messages
**Suggestion:** Consider writing tests first next time
```

Record feedback in `agents/<target>/received-feedback.md` for patterns.

---

## Escalation

If blocked for more than one work cycle:
1. Create a blocking issue tagging the relevant agent
2. Add `status:blocked` and `priority:high` labels
3. Document what you've tried
4. Move on to other available work
