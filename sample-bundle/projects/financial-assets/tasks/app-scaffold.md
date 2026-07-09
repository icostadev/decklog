---
type: task
title: "macOS app scaffold & SwiftData stack"
description: "Set up the SwiftUI macOS app skeleton with a SwiftData persistence stack and main navigation."
tags: [setup, swiftui, swiftdata]
status: done
artifacts: ["https://github.com/acme/wealth/pull/2"]
assignee: agents/backend-impl
priority: p1
order: "0|i00000:"
parent: projects/financial-assets/milestones/foundation
timestamp: 2026-07-09T00:00:00Z
---

Create the project skeleton: a runnable SwiftUI macOS app with a SwiftData model
container wired up and the main window/navigation shell everything else hangs
off. No asset logic yet — just the frame.

## Acceptance criteria

- [ ] SwiftUI macOS app target builds and launches to an empty main window
- [ ] A SwiftData `ModelContainer` is configured and injected into the environment
- [ ] Navigation shell (sidebar + detail) with placeholder sections for Portfolio, Net worth, and Settings
- [ ] A Settings screen stub exists (base currency will live here)
- [ ] App launches on the current macOS release with no console errors

## Context

Native macOS, SwiftUI + SwiftData, single-user, local storage. This establishes
the shell the [asset data model](/projects/financial-assets/tasks/asset-data-model.md)
and every view build on. See [scope & data sources](/knowledge/wealth-app.md).
