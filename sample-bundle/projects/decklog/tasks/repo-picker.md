---
type: task
title: "Project repo picker"
description: "Link a git repo to a project via a native folder picker."
status: ready
priority: p1
parent: projects/decklog/milestones/iteration-3
timestamp: 2026-07-09T00:00:00Z
---

Let the user set a project's `repo` from the UI.

## Acceptance criteria

- [ ] A "Set repo…" action on a project opens a native folder picker (NSOpenPanel)
- [ ] The chosen directory is written to the project's `repo` frontmatter via the core
- [ ] The sidebar reflects the linked repo after selection

## Context

`repo` is a project frontmatter field; store it relative to the bundle when the repo
lives nearby. See [Decklog architecture](/knowledge/decklog-architecture.md).
