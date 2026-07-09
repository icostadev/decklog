---
type: task
title: "Core commands: add / list / done / delete"
description: "Implement the four MVP subcommands against the persisted list."
tags: [cli, commands]
status: in_review
artifacts: ["https://github.com/acme/todo/pull/6"]
assignee: agents/backend-impl
priority: p1
order: "0|i00002:"
parent: projects/todo-app/milestones/mvp
blocked_by: [projects/todo-app/tasks/data-model-persistence]
timestamp: 2026-07-09T00:00:00Z
---

Wire the four subcommands to the storage layer so a user can manage their list.

## Acceptance criteria

- [ ] `todo add <text>` appends a new todo and confirms it
- [ ] `todo list` shows all todos with their id and done state
- [ ] `todo done <id>` marks a todo complete; unknown id errors clearly
- [ ] `todo delete <id>` removes a todo; unknown id errors clearly
- [ ] Every command persists its change and exits with a correct status code

## Context

Depends on the [data model & persistence](/projects/todo-app/tasks/data-model-persistence.md)
layer and the [scaffold](/projects/todo-app/tasks/scaffold-cli.md). Commands
call the storage module — they should not read or write the file directly.
Output formatting is deliberately minimal here; polish lands in
[output & UX polish](/projects/todo-app/tasks/output-polish.md).
