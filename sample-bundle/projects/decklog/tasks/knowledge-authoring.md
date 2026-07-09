---
type: task
title: "Knowledge authoring"
description: "PM agent authors knowledge concepts and links them from task context."
status: ready
priority: p2
parent: projects/decklog/milestones/iteration-5
timestamp: 2026-07-09T00:00:00Z
---

Give executors durable context by capturing it as knowledge in the bundle.

## Acceptance criteria

- [ ] When a task needs context that isn't written down, the PM agent authors a
      `knowledge/` concept (spec, decision, or domain note) for it
- [ ] Tasks link those concepts from their `## Context`
- [ ] Executors receive the linked knowledge (already resolved by `ExecutorPrompt`)

## Context

Knowledge concepts are plain OKF concepts under `knowledge/`. See
[Decklog architecture](/knowledge/decklog-architecture.md).
