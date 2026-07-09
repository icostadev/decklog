---
type: knowledge
title: "Decklog architecture"
description: "How Decklog is built — the layers and the key decisions."
tags: [decklog, architecture]
timestamp: 2026-07-09T00:00:00Z
---

# Decklog architecture

A digest of `docs/DESIGN.md` for executors working on Decklog.

## Layers
- **OKFKit** (Swift, cross-platform, unit-tested) — the OKF bundle core: parse /
  validate / round-trip markdown+frontmatter, the graph, `BundleGit` (commit),
  `dispatchDecision` (the hard gate), `ExecutorPrompt`, `WorktreeManager`.
- **app** (SwiftUI, macOS, target `Decklog`) — read-only board + PM chat panel;
  `PMAgentSession` drives headless Claude Code; `BundleStore` wires it together.

## Key decisions
- The **OKF bundle is the single source of truth**; the app is a projection over it.
- The **UI is read-only for content** — the PM agent authors everything; edits are commits.
- **Tasks:** `draft → ready → in_progress → in_review → done` (+ `cancelled`); `blocked`
  is derived from unresolved `blocked_by`, not a status.
- **Dispatch is hard-gated:** a task runs only when `ready` and all `blocked_by` are `done`.
- **Executors** run headless Claude Code in a **git worktree per task** on a
  `decklog/<task>` branch; the app never merges — a human does.
