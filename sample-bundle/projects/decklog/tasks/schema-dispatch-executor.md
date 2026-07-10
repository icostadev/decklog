---
type: task
title: "Schema-drive dispatch & executor"
description: "The dispatch gate and executor lifecycle transitions resolve statuses by role, so custom vocabularies don't break them."
status: in_review
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-7
blocked_by: [projects/decklog/tasks/schema-model, projects/decklog/tasks/schema-load]
timestamp: 2026-07-10T00:00:00Z
---

The statuses that carry *meaning* (dispatchable, in-progress, in-review, done) must be resolved
through the schema's roles, or renaming them in `decklog.yaml` would silently break dispatch and
the executor.

## Acceptance criteria

- [ ] `dispatchDecision(forTask:)` gates on `schema.taskStatus(for: .ready)` and checks blockers
      against `schema.taskStatus(for: .done)` (a nil role degrades gracefully, no crash)
- [ ] `ExecutorSession` writes lifecycle statuses via role lookups
      (`.inProgress` on start, `.inReview` on completion, `.ready` on cancel) rather than literals
- [ ] The schema (or the resolved role strings) is threaded from `BundleStore.dispatch(taskID:)`
      into `ExecutorSession`
- [ ] A task in a custom-vocabulary bundle still dispatches and advances end to end

## Context

`OKFKit/Sources/OKFKit/Dispatch.swift` (`dispatchDecision`) and
`app/Sources/Decklog/ExecutorSession.swift` (the three `TaskStatus.*.rawValue` writes), wired by
`app/Sources/Decklog/BundleStore.swift` (`dispatch`). See [Decklog architecture](/knowledge/decklog-architecture.md).
