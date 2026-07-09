---
type: task
title: "Executor safety ceilings"
description: "Per-dispatch wall-clock (and optional turn) cap; clean failure handling."
status: in_review
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-4
timestamp: 2026-07-09T00:00:00Z
---

Bound unattended executor runs so a stuck run can't run forever.

## Acceptance criteria

- [ ] Each dispatch has a wall-clock timeout that terminates the executor if exceeded
- [ ] A timed-out or failed run surfaces clearly and doesn't leave the task stuck `in_progress`
- [ ] (Optional) pass a max-turns cap to Claude Code
