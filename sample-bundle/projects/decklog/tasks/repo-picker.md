---
type: task
title: "Project repo picker"
description: "Link a git repo to a project via a native folder picker."
status: draft
priority: p3
parent: projects/decklog/milestones/iteration-3
timestamp: 2026-07-09T00:00:00Z
---

**Optional / parked** — not on the Iteration-3 critical path. A project's `repo` can
already be set by asking the PM agent in chat; this is just a nicer way to do it.
Revisit after execution works.

## Acceptance criteria

- [ ] A "Set repo…" action on a project opens a native folder picker (NSOpenPanel)
- [ ] The chosen directory is written to the project's `repo` frontmatter via the core
- [ ] The sidebar reflects the linked repo after selection
