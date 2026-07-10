---
type: task
title: "Interactive clarifying questions"
description: "PM agent asks one question at a time; multiple-choice questions render as quick-reply buttons."
status: in_review
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-5
timestamp: 2026-07-10T00:00:00Z
---

Make planning a real back-and-forth instead of a wall of questions.

## Acceptance criteria

- [ ] The PM agent asks one clarifying question at a time, waiting for each answer
- [ ] Discrete-choice questions are emitted as a `decklog:options` block
- [ ] The chat renders those options as quick-reply buttons; clicking sends the choice
- [ ] The raw options block is hidden from the message; the text box still works for custom answers

## Context

Charter (`PMCharter`) + `ChatPanel` parsing. See [Decklog architecture](/knowledge/decklog-architecture.md).
