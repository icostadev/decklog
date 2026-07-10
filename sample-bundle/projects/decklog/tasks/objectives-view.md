---
type: task
title: "Objectives view"
description: "Show objectives in the sidebar with rolled-up task progress; drill into contributing projects/tasks."
status: in_review
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-6
blocked_by: [projects/decklog/tasks/objective-rollup]
timestamp: 2026-07-10T00:00:00Z
---

Make objectives visible in the app (today the sidebar shows only projects) and surface how
work rolls up to them.

## Acceptance criteria

- [ ] An "Objectives" section in the sidebar listing each objective (title + status)
- [ ] Selecting an objective shows its rollup: overall progress (fraction done) and a
      breakdown by status, plus the projects that serve it
- [ ] Drill from an objective into its contributing tasks (reuse the task detail nav)
- [ ] Empty/None states handled (an objective with no linked projects/tasks)

## Context

`app/Sources/Decklog/ContentView.swift` (`SidebarView` scope list, `mainContent`) and a new
objectives view; uses the `objective-rollup` queries. See [Decklog architecture](/knowledge/decklog-architecture.md).
