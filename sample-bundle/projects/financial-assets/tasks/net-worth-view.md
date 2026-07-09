---
type: task
title: "Net-worth view"
description: "Aggregate all holdings, convert to base currency, and show total net worth with breakdowns."
tags: [ui, reporting]
status: ready
priority: p1
order: "0|i00004:"
parent: projects/financial-assets/milestones/foundation
blocked_by: [projects/financial-assets/tasks/currency-conversion, projects/financial-assets/tasks/manual-asset-entry]
timestamp: 2026-07-09T00:00:00Z
---

The capstone of Foundation: roll up all holdings into a single net-worth figure
in the base currency, with breakdowns.

## Acceptance criteria

- [ ] Total net worth shown in the base currency
- [ ] Breakdown by region and by asset type
- [ ] Each asset's current value (latest valuation × quantity, converted) is visible
- [ ] Figures update when assets, valuations, FX rates, or base currency change
- [ ] Clear empty state when no assets exist yet

## Context

Proves the model, conversion, and entry hang together. Reuses the conversion
service from
[currency & base-currency conversion](/projects/financial-assets/tasks/currency-conversion.md).
Later, [ROI](/projects/financial-assets/tasks/portfolio-roi.md) and
[wealth history](/projects/financial-assets/tasks/wealth-history.md) build on
this aggregation.
