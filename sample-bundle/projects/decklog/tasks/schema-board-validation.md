---
type: task
title: "Schema-drive board & validation"
description: "The board columns/labels and the status validation read the loaded schema instead of the hardcoded enums."
status: ready
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-7
blocked_by: [projects/decklog/tasks/schema-model, projects/decklog/tasks/schema-load]
timestamp: 2026-07-10T00:00:00Z
---

Make the two "read the vocabulary" surfaces honor the bundle's schema, so a bundle with custom
statuses renders correct columns and stops getting flagged for its own words.

## Acceptance criteria

- [ ] `BoardView` columns, column labels, and the `unplaced` predicate derive from
      `bundle.schema.taskColumns` (order + labels from the schema)
- [ ] Declared non-column statuses (e.g. `cancelled`) stay off-board — NOT surfaced as unplaced
- [ ] Truly unknown statuses (not in the schema) still land in the "Unplaced" column
- [ ] `Validation.statusIssue` uses `schema.allowedStatuses(for:)` instead of `StatusVocabulary`
- [ ] The board's blocker check uses `schema.taskStatus(for: .done)`

## Context

`app/Sources/Decklog/BoardView.swift` (`columns`, `columnStatuses`, `label(_:)`,
`unplacedTasks`, blocker check) and `OKFKit/Sources/OKFKit/Validation.swift` (`statusIssue`).
See [Decklog architecture](/knowledge/decklog-architecture.md).
