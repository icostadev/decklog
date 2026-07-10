---
type: task
title: "Tolerant bundle load"
description: "Load a bundle even when some files don't parse — quarantine the bad ones and report them."
status: in_review
assignee: agents/backend-impl
priority: p2
timestamp: 2026-07-10T00:00:00Z
---

One malformed file (e.g. unquoted YAML with an inner `: `) used to fail the whole bundle
open. Now it loads the rest and reports the offender.

## Acceptance criteria

- [ ] `OKFBundle.load` no longer throws on a per-file parse error; it loads the good concepts
- [ ] Unparseable files are collected as `loadErrors` (path + reason)
- [ ] The app surfaces load errors in the validation panel (copyable), alongside validation issues
