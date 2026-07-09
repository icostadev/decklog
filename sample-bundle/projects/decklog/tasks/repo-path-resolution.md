---
type: task
title: "Resolve project repo relative to bundle"
description: "Support relative `repo` paths, resolved against the bundle root."
status: ready
priority: p1
parent: projects/decklog/milestones/iteration-3
timestamp: 2026-07-09T00:00:00Z
---

## Acceptance criteria

- [ ] A relative `repo` (e.g. `..`) resolves against the bundle root to an absolute path
- [ ] Absolute paths and git URLs are left unchanged
- [ ] The dispatcher uses the resolved path as the executor working dir

## Context

Needed so the Decklog project's `repo: ..` points at the repo on any machine.
See [Decklog architecture](/knowledge/decklog-architecture.md).
