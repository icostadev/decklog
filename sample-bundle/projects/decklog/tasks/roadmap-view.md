---
type: task
title: "Roadmap view"
description: "A timeline of milestones (start→due) via Swift Charts, grouped by project/objective."
status: ready
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-6
blocked_by: [projects/decklog/tasks/objective-rollup]
timestamp: 2026-07-10T00:00:00Z
---

A time view of the plan: when milestones start and land, so the roadmap is legible at a
glance.

## Acceptance criteria

- [ ] A roadmap view rendering milestones as bars over a time axis (start → due) with Swift
      Charts, grouped by project (and/or objective)
- [ ] Milestones lacking dates are listed separately, not silently dropped
- [ ] Reachable from the sidebar or toolbar; empty state when nothing is dated

## Context

Milestones/projects carry `start`/`due` (ISO dates). Swift Charts is available on macOS 13.
New app view; grouping can reuse the `objective-rollup` hierarchy queries. See
[Decklog architecture](/knowledge/decklog-architecture.md).
