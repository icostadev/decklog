---
type: task
title: "Bundle schema model"
description: "A BundleSchema value type describing the status vocabulary, with a default that reproduces today's built-in enums."
status: in_review
assignee: agents/backend-impl
priority: p1
parent: projects/decklog/milestones/iteration-7
timestamp: 2026-07-10T00:00:00Z
---

The foundation for configurable statuses: model the vocabulary as data instead of hardcoded
enums, keeping the enums as the source of the built-in default and the fixed set of semantic
roles.

## Acceptance criteria

- [ ] `BundleSchema`, `StatusDef` (id, label, isColumn, optional role), and a `TaskRole`
      enum (ready, in_progress, in_review, done, cancelled) exist in OKFKit
- [ ] `BundleSchema.default` reproduces `Status.swift` exactly (task, milestone/project,
      objective vocabularies, including `cancelled` off-board)
- [ ] Lookups: `allowedStatuses(for kind:)`, `taskStatus(for role:)`, `taskColumns` (ordered),
      `taskLabel(_:)`
- [ ] A default `StatusDef.label` derives from the id (`in_progress` → "In progress")
- [ ] Unit tests assert `.default` matches the current `TaskStatus`/`WorkStatus`/`ObjectiveStatus`

## Context

New file `OKFKit/Sources/OKFKit/BundleSchema.swift`. The built-in vocabulary and the role
meanings live today in `OKFKit/Sources/OKFKit/Status.swift` (`TaskStatus`, `WorkStatus`,
`ObjectiveStatus`, `StatusVocabulary`). See [Decklog architecture](/knowledge/decklog-architecture.md).
