---
type: task
title: "Manual asset & valuation entry UI"
description: "UI to add and edit assets, record holdings, and enter valuations by hand."
tags: [ui, swiftui]
status: in_progress
assignee: agents/backend-impl
priority: p2
order: "0|i00003:"
parent: projects/financial-assets/milestones/foundation
blocked_by: [projects/financial-assets/tasks/asset-data-model]
timestamp: 2026-07-09T00:00:00Z
---

The primary way data gets into the app until feeds land in Market data: forms to
add/edit assets, record holdings, and enter or update valuations.

## Acceptance criteria

- [ ] Add/edit an asset (name, type, region, native currency, ticker if market-priced)
- [ ] Record a holding (quantity, cost basis, acquisition date)
- [ ] Enter a valuation; saving appends to history rather than overwriting
- [ ] Browse assets grouped by region and asset type
- [ ] Delete an asset with confirmation
- [ ] Basic input validation (required fields, positive amounts, valid currency)

## Context

Depends on the [asset data model](/projects/financial-assets/tasks/asset-data-model.md).
Forms must work for both market-priced and manually-valued assets — the former
still need quantity and cost basis even though prices arrive from a feed later.
