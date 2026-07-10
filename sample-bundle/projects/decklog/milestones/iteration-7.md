---
type: milestone
title: "Iteration 7 — Configurable schema"
description: "A per-bundle decklog.yaml lets a bundle declare its own status vocabulary; the board, validation, dispatch, executor, and PM charter derive from it."
status: done
project: projects/decklog/project
timestamp: 2026-07-10T00:00:00Z
---

Bundles authored elsewhere use their own status words (the control-plane bundle tripped a
"status dialect mismatch" in the PM diagnosis). Rather than force every bundle onto Decklog's
built-in vocabulary, let the bundle be the source of truth: declare task / milestone /
objective statuses in a root `decklog.yaml`. Concept `type` stays built-in for v1.
