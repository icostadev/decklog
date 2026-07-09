---
type: task
title: "Data model & persistence"
description: "Define the todo model and load/save it to a local file."
tags: [data, persistence]
status: done
artifacts: ["https://github.com/acme/todo/pull/3"]
assignee: agents/backend-impl
priority: p1
order: "0|i00001:"
parent: projects/todo-app/milestones/mvp
blocked_by: [projects/todo-app/tasks/scaffold-cli]
timestamp: 2026-07-09T00:00:00Z
---

Define what a todo is and how the list is stored on disk, so state survives
between runs.

## Acceptance criteria

- [ ] A todo has a stable id, text, and done flag
- [ ] The list loads from a local file on startup, creating it if absent
- [ ] Changes are saved back to the file atomically (no corruption on crash)
- [ ] A missing or malformed file is handled gracefully (clear error, no stack trace)

## Context

Depends on [the scaffold](/projects/todo-app/tasks/scaffold-cli.md). Store the
list as JSON in a file under the user's home/config directory. Keep the storage
layer isolated behind a small module so the
[core commands](/projects/todo-app/tasks/core-commands.md) don't touch the file
format directly.
