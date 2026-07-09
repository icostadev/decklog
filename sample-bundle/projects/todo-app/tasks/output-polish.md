---
type: task
title: "Output formatting & UX polish"
description: "Make the CLI output readable and the errors friendly."
tags: [cli, ux]
status: ready
priority: p2
order: "0|i00003:"
parent: projects/todo-app/milestones/mvp
blocked_by: [projects/todo-app/tasks/core-commands]
timestamp: 2026-07-09T00:00:00Z
---

Turn the working commands into something pleasant to use day to day.

## Acceptance criteria

- [ ] `list` output is aligned and shows a clear done/pending marker
- [ ] `list` on an empty list prints a friendly hint, not a blank line
- [ ] Error messages are actionable (what went wrong + how to fix), no stack traces
- [ ] README documents install and each command with an example

## Context

Depends on the [core commands](/projects/todo-app/tasks/core-commands.md). This
is the final MVP task — after it, a user can install and run the app end to end.
Keep output plain text and terminal-friendly; no color dependency required.
