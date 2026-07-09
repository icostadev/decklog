---
type: task
title: "Projection engine (optimistic + pessimistic)"
description: "Extrapolate future net worth from historical performance in two scenarios."
tags: [projections]
status: draft
priority: p1
order: "0|i00014:"
parent: projects/financial-assets/milestones/projections
blocked_by: [projects/financial-assets/tasks/wealth-history]
timestamp: 2026-07-09T00:00:00Z
---

Derive a historical growth rate from the wealth-over-time series and project
future net worth in two scenarios.

## Acceptance criteria

- [ ] Historical CAGR computed from the net-worth time series over a selectable lookback window (e.g. all / 5Y / 3Y)
- [ ] **Optimistic** scenario projects forward at the historical average CAGR
- [ ] **Pessimistic** scenario projects at CAGR minus a spread, defaulting to 3 percentage points
- [ ] The pessimistic spread is a user setting on the Settings screen, editable and persisted
- [ ] Projects annual net-worth values over a configurable horizon (e.g. 1–30 years), in the base currency
- [ ] Output is a pure, testable series (given a CAGR + spread + horizon → yearly values), independent of any view
- [ ] Insufficient history (too few points to compute a CAGR) is reported clearly instead of projecting from noise

## Context

Extrapolates the series from
[wealth-over-time history](/projects/financial-assets/tasks/wealth-history.md).
Keep the math a pure function so it's trivially unit-testable and so the
[projection view](/projects/financial-assets/tasks/projection-view.md) is a thin
render on top. This is deliberately simple extrapolation, not Monte-Carlo — see
[scope & data sources](/knowledge/wealth-app.md).
