---
type: task
title: "Plan (sequence) view"
description: "Tasks in dependency order per project, with the objective each project serves — no dates."
status: done
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-6
blocked_by: [projects/decklog/tasks/objective-rollup]
timestamp: 2026-07-10T00:00:00Z
---

Replaces the date-based roadmap (dropped — dates aren't how this bundle is planned). What
matters is the sequence of tasks, their organization within projects, and the objective they
serve.

## Acceptance criteria

- [ ] A "Plan" scope in the sidebar showing every project's tasks in `blocked_by` dependency
      order (a topological sort; ties by `order` then id), so top-to-bottom is the sequence
- [ ] Each project section header shows the objective(s) the project serves
- [ ] Each task row shows its status and "blocked by …"; rows drill into the task detail
- [ ] Dependency cycles are tolerated (no hang); tasks without dependencies keep a stable order

## Context

Ordering logic in `OKFKit/Sources/OKFKit/Plan.swift` (`tasks(inProject:)`, `planOrder(_:)`),
rendered by `app/Sources/Decklog/PlanView.swift`, wired via a `planScope` in
`ContentView`/`SidebarView`. See [Decklog architecture](/knowledge/decklog-architecture.md).
