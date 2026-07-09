---
type: task
title: "ROI per asset"
description: "Return on investment for each asset: appreciation + dividends vs cost basis."
tags: [analytics]
status: draft
priority: p1
order: "0|i00011:"
parent: projects/financial-assets/milestones/analytics
blocked_by: [projects/financial-assets/tasks/net-worth-view]
timestamp: 2026-07-09T00:00:00Z
---

Compute return on investment for each asset from current value plus dividends
received against cost basis, all in the base currency.

## Acceptance criteria

- [ ] ROI shown per asset as both absolute gain/loss and percentage return
- [ ] Return = (current value − cost basis + dividends received) ÷ cost basis, in the base currency
- [ ] Dividends are included when present; the calc still works (appreciation only) when they aren't
- [ ] An annualised return (CAGR from acquisition date to today) is shown alongside total return
- [ ] Currency conversion uses the shared conversion service; cost basis and current value are converted consistently
- [ ] Missing price or FX data yields a clearly-flagged "incomplete" ROI rather than a wrong number
- [ ] Gracefully handles zero/absent cost basis (no divide-by-zero)

## Context

Builds on the aggregation from the
[net-worth view](/projects/financial-assets/tasks/net-worth-view.md) and consumes
dividends from
[dividend tracking](/projects/financial-assets/tasks/dividend-tracking.md) when
available. Keep the return math in a service so
[portfolio ROI](/projects/financial-assets/tasks/portfolio-roi.md) and, later,
tax can reuse it. Returns here are pre-tax — the
[Tax milestone](/projects/financial-assets/milestones/tax.md) layers net returns
on top.
