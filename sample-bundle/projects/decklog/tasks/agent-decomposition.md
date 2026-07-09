---
type: task
title: "PM agent decomposition"
description: "Decompose an objective/project into a proposed task tree, approved before it's written."
status: in_review
assignee: agents/backend-impl
priority: p2
parent: projects/decklog/milestones/iteration-5
timestamp: 2026-07-09T00:00:00Z
---

Turn a high-level goal into structured, dispatchable work — with the human approving
before anything is written.

## Acceptance criteria

- [ ] Asked to plan/break down an objective or project, the PM agent first PROPOSES a
      tree (milestones + tasks, with dependencies and priorities) in chat and waits for approval
- [ ] On approval it creates the concepts with correct frontmatter (`parent`, `blocked_by`)
      and drafts each task's `## Acceptance criteria` and `## Context`
- [ ] A task is `ready` only with acceptance criteria + a context brief; otherwise `draft`
- [ ] It never creates the tree without approval, and never re-plans unprompted

## Context

Realized mainly through the PM agent's charter (`PMCharter`) — the agent already edits the
bundle; this shapes HOW it plans. See [Decklog architecture](/knowledge/decklog-architecture.md).
