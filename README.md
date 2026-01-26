# agent-kit

Shared agent tooling and workflow docs for POK-style autonomous development.

## Contents

- scripts/ - Agent orchestration and helper scripts
- docs/ - Shared workflow reference
- agents/ - Generic agent docs (project-agnostic)
- templates/ - Base CLAUDE/HUMAN templates for new projects

## Scripts

Primary orchestration:
- scripts/summon-agent.sh
- scripts/agent-health.sh
- scripts/bootstrap-watcher.sh
- scripts/auto-accept-bypass.exp

Helpers:
- scripts/agent-work-status.sh
- scripts/start-agents.sh
- scripts/run-agent.sh
- scripts/claude-accept-bypass.exp
- scripts/claude-with-bypass.exp

## Recommended Use

- Add this repo as a git subtree under `agent-kit/` in your project.
- Reference scripts as `./agent-kit/scripts/<script>` in docs and automation.
- Keep project-specific agent identity files in the project repo.

## Updating a Project Subtree

Pull updates into a project repo:

  git subtree pull --prefix agent-kit https://github.com/shaneauerbach/agent-kit.git main

