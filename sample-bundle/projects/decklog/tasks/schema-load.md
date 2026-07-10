---
type: task
title: "Load decklog.yaml (tolerant)"
description: "Read a root decklog.yaml into the BundleSchema on open; absent uses the default, malformed falls back and reports."
status: in_review
assignee: agents/backend-impl
priority: p1
parent: projects/decklog/milestones/iteration-7
blocked_by: [projects/decklog/tasks/schema-model]
timestamp: 2026-07-10T00:00:00Z
---

Load the declared vocabulary at bundle open, in the same tolerant spirit as the rest of the
loader: a bad config degrades to the default and is reported, never fails the open.

## Acceptance criteria

- [ ] `OKFBundle.load(at:)` reads `decklog.yaml` at the bundle root and parses it into a
      `BundleSchema` stored on `OKFBundle` (default it in the memberwise init and `inMemory`)
- [ ] Missing `decklog.yaml` → `BundleSchema.default`; existing callers/tests unaffected
- [ ] Malformed `decklog.yaml` → `.default` **plus** a `BundleLoadError` (path `decklog.yaml`)
      so it surfaces in the existing load-error banner / validation panel
- [ ] Parser accepts the full form (`{ id, label, column, role }`) and a bare-string shorthand;
      a status whose `id` matches a default role auto-binds that role
- [ ] Round-trips through Yams (reuse the approach in `Frontmatter`)

## Context

`OKFKit/Sources/OKFKit/OKFBundle.swift` (`load`, `rootOKFVersion` shows the pattern for
reading a root file). `BundleLoadError` and the tolerant-load flow already exist. YAML via
`Yams` as in `OKFKit/Sources/OKFKit/Frontmatter.swift`. `decklog.yaml` is not `.md`, so the
concept enumerator already skips it. See [Decklog architecture](/knowledge/decklog-architecture.md).
