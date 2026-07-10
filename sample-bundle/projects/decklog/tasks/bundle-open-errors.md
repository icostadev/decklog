---
type: task
title: "Surface bundle-open errors in an alert"
description: "Show open/parse failures in a copyable alert, not just in the empty state."
status: in_review
assignee: agents/backend-impl
priority: p3
timestamp: 2026-07-10T00:00:00Z
---

Opening an old/invalid bundle failed quietly when another bundle was already open — the
error only showed via the empty state.

## Acceptance criteria

- [ ] A failed bundle open shows an alert with the error, regardless of prior state
- [ ] The alert has a "Copy Details" button
- [ ] A failed open keeps the currently-open bundle (doesn't discard it)
