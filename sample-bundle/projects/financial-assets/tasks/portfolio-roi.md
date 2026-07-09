---
type: task
title: "Portfolio ROI"
description: "Aggregate ROI across the whole portfolio, with breakdowns."
tags: [analytics]
status: draft
priority: p1
order: "0|i00012:"
parent: projects/financial-assets/milestones/analytics
blocked_by: [projects/financial-assets/tasks/roi-per-asset]
timestamp: 2026-07-09T00:00:00Z
---

Roll per-asset ROI up to the whole portfolio in the base currency, with
breakdowns so the user can see what's driving returns.

## Acceptance criteria

- [ ] Total portfolio ROI shown as absolute gain/loss and percentage, in the base currency
- [ ] Aggregation sums current values, cost bases, and dividends across all assets (not an average of percentages)
- [ ] Breakdowns by region and by asset type, each with its own ROI
- [ ] Portfolio-level annualised return (money-weighted, accounting for different acquisition dates)
- [ ] Assets with incomplete data are excluded from totals and the exclusion is surfaced, not silent
- [ ] Empty-portfolio state handled

## Context

Aggregates the per-asset numbers from
[ROI per asset](/projects/financial-assets/tasks/roi-per-asset.md), reusing that
return service. The money-weighted annualised figure is the non-trivial part —
assets bought at different times can't be combined with a simple average. Feeds
into [capital-gains tax](/projects/financial-assets/tasks/capital-gains-tax.md)
later.
