---
type: task
title: "Concurrent executors"
description: "Run multiple tasks at once, each in its own worktree; active-run list."
status: ready
priority: p2
parent: projects/decklog/milestones/iteration-4
timestamp: 2026-07-09T00:00:00Z
---

The dispatcher already keys runs by task id, so several can run at once — this adds the
UI to see and control them.

## Acceptance criteria

- [ ] Multiple tasks can run concurrently, each in its own worktree
- [ ] An "active runs" view lists in-flight executors with their phase
- [ ] A running executor can be cancelled
