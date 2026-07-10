---
type: task
title: "Objective hierarchy & rollup queries"
description: "OKFKit queries to navigate objective → project → milestone → task and roll up task status."
status: in_review
assignee: agents/backend-impl
priority: p1
parent: projects/decklog/milestones/iteration-6
timestamp: 2026-07-10T00:00:00Z
---

The data foundation for the objectives and roadmap views: walk the (upward) hierarchy and
roll task status up to an objective. No UI.

## Acceptance criteria

- [ ] `OKFBundle` queries: `objectives()`, `projects(forObjective:)`, `milestones(forProject:)`,
      `tasks(forObjective:)` (tasks under the objective's projects' milestones, plus tasks that
      list the objective directly, deduped)
- [ ] An `ObjectiveRollup` (total, count by status, done count, fraction done) via
      `rollup(forObjective:)`, using `schema.taskStatus(for: .done)` for "done"
- [ ] Smoke checks in OKFKitSmoke covering the hierarchy walk + rollup

## Context

Hierarchy links upward: a project declares `objectives: [...]`, a milestone declares its
`project`, a task declares its `parent` milestone (and may also list `objectives`). See
`OKFKit/Sources/OKFKit/OKFBundle.swift` (queries) and `Concept.swift` (`objectives`,
`project`, `parent`). See [Decklog architecture](/knowledge/decklog-architecture.md).
