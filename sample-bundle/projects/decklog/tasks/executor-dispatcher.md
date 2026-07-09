---
type: task
title: "Executor dispatcher"
description: "Run a task in a worktree, stream output, commit the branch."
status: ready
priority: p1
parent: projects/decklog/milestones/iteration-3
blocked_by:
  - projects/decklog/tasks/execution-core
  - projects/decklog/tasks/repo-path-resolution
timestamp: 2026-07-09T00:00:00Z
---

The app-side of execution.

## Acceptance criteria

- [ ] "Run" is enabled only when the dispatch gate passes (`ready` + blockers `done`)
- [ ] Running creates a `decklog/<task>` worktree and spawns Claude Code with the executor prompt
- [ ] Output streams live in the task detail; status goes `in_progress → in_review`
- [ ] On completion the worktree branch is committed and recorded in `artifacts`

## Context

Builds on the OKFKit execution core. See [Decklog architecture](/knowledge/decklog-architecture.md).
