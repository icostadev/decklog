---
type: task
title: "Project scaffold & CLI entrypoint"
description: "Set up the project layout and a working CLI entrypoint with argument parsing."
tags: [cli, setup]
status: done
artifacts: ["https://github.com/acme/todo/pull/1"]
assignee: agents/backend-impl
priority: p1
order: "0|i00000:"
parent: projects/todo-app/milestones/mvp
timestamp: 2026-07-09T00:00:00Z
---

Create the project skeleton and a runnable CLI that parses subcommands and
prints help. No todo logic yet — just the frame everything else hangs off.

## Acceptance criteria

- [ ] Project layout created (package/module, entrypoint, README stub)
- [ ] `todo --help` lists the planned subcommands and exits 0
- [ ] An unknown command prints a usage message and exits non-zero
- [ ] Argument parsing wired for `add`, `list`, `done`, `delete` (handlers may be stubs)

## Context

CLI-only, single-user, Python. This task establishes the command surface that
the [data model](/projects/todo-app/tasks/data-model-persistence.md) and
[core commands](/projects/todo-app/tasks/core-commands.md) build on. Keep the
argument parser in the standard library (argparse) unless there's a reason not to.
