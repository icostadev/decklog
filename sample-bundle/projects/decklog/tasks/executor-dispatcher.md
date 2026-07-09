---
type: task
title: "Executor dispatcher"
description: "Run a task in a worktree, stream output, commit the branch."
status: in_review
priority: p1
parent: projects/decklog/milestones/iteration-3
blocked_by:
  - projects/decklog/tasks/execution-core
timestamp: 2026-07-09T00:00:00Z
---

The app-side of execution — the remaining work for Iteration 3.

## Acceptance criteria

- [ ] "Run" is enabled only when the dispatch gate passes (`ready` + blockers `done`)
- [ ] Resolves the project's `repo` (absolute path, git URL, or relative like `..`) to
      the executor's working directory
- [ ] Running creates a `decklog/<task>` worktree and spawns Claude Code with the executor prompt
- [ ] Output streams live in the task detail; status goes `in_progress → in_review`
- [ ] On completion the worktree branch is committed and recorded in `artifacts`

## Context

Builds on the OKFKit execution core (`WorktreeManager`, `ExecutorPrompt`,
`dispatchDecision`). Resolving the project's `repo` — including relative paths against
the bundle root — is a small detail handled here, not a separate task. See
[Decklog architecture](/knowledge/decklog-architecture.md).
