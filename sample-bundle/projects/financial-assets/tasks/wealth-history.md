---
type: task
title: "Wealth-over-time history & chart"
description: "Chart net worth over time from the append-only valuation records."
tags: [analytics, ui]
status: draft
priority: p2
order: "0|i00013:"
parent: projects/financial-assets/milestones/analytics
blocked_by: [projects/financial-assets/tasks/net-worth-view]
timestamp: 2026-07-09T00:00:00Z
---

Reconstruct net worth at points in the past from the append-only valuation and
holding history, and chart it so wealth increase across years is visible.

## Acceptance criteria

- [ ] A net-worth time series is computed in the base currency from historical valuations and holdings as they were on each date
- [ ] Charted with Swift Charts, with selectable ranges (1Y / 5Y / all)
- [ ] Uses the FX rate effective on each historical date, not today's rate, when converting past values
- [ ] Points with no valuation carry forward the last known value rather than dropping to zero
- [ ] Shows total change and CAGR over the selected range
- [ ] Sparse history renders sensibly (few points, or a single point)

## Context

Reads the append-only records established in the
[asset data model](/projects/financial-assets/tasks/asset-data-model.md) and
reuses the aggregation from the
[net-worth view](/projects/financial-assets/tasks/net-worth-view.md). Point-in-time
FX is the subtle requirement — converting old values at today's rate would
distort the trend. This time series is also the input the
[projection engine](/projects/financial-assets/tasks/projection-engine.md)
extrapolates from.
