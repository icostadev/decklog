---
type: task
title: "Worktree cleanup"
description: "Remove a run's worktree after it commits; prune stale worktrees."
status: in_review
assignee: agents/backend-impl
priority: p1
parent: projects/decklog/milestones/iteration-4
timestamp: 2026-07-09T00:00:00Z
---

Executor worktrees currently linger in a temp dir (they show as `prunable`). Clean them
up so the repo stays tidy; the branch preserves the work.

## Acceptance criteria

- [ ] After a run commits its branch, its worktree is removed (the branch remains)
- [ ] Stale/orphaned worktrees can be pruned
- [ ] Cleanup failures are logged, never crash the run

## Context

See `WorktreeManager` in OKFKit and `ExecutorSession` in the app.
