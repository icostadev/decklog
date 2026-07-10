---
type: task
title: "Schema-aware PM charter"
description: "The PM agent's charter reflects the bundle's actual vocabulary, so it stops correcting custom statuses back to the defaults."
status: in_review
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-7
blocked_by: [projects/decklog/tasks/schema-model, projects/decklog/tasks/schema-load]
timestamp: 2026-07-10T00:00:00Z
---

The linchpin that makes configuration coherent: if the charter still hardcodes
"status is one of draft, ready, …", the PM will keep rewriting the bundle's real statuses back
to the defaults, fighting the config.

## Acceptance criteria

- [ ] `PMCharter.text` becomes `PMCharter.text(for: schema)`, emitting the bundle's actual
      task/milestone/objective statuses and what each role means
- [ ] `PMAgentSession` receives the schema (from `BundleStore.load`, which has `loaded.schema`)
      and uses it where it builds `--append-system-prompt`
- [ ] With a custom `decklog.yaml`, the PM proposes/writes the bundle's statuses, not the defaults
- [ ] The auto-diagnosis can offer "declare these statuses in `decklog.yaml`" as an alternative
      to renaming files for a genuine dialect

## Context

`app/Sources/Decklog/PMCharter.swift` and `app/Sources/Decklog/PMAgentSession.swift`
(`--append-system-prompt`, currently `PMCharter.text`). Builds on the auto-diagnosis added in
iteration 6-era work. See [Decklog architecture](/knowledge/decklog-architecture.md).
