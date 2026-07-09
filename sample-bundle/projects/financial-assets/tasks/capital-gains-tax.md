---
type: task
title: "Capital-gains tax"
description: "Apply region/asset-class tax rates to realised capital gains."
tags: [tax]
status: draft
priority: p2
order: "0|i00018:"
parent: projects/financial-assets/milestones/tax
blocked_by: [projects/financial-assets/tasks/tax-rate-config, projects/financial-assets/tasks/portfolio-roi]
timestamp: 2026-07-09T00:00:00Z
---

Estimate tax on realised capital gains using the configured rates, so net
returns reflect the tax drag.

## Acceptance criteria

- [ ] Realised gains are computed on disposals (sale proceeds − cost basis of the units sold), in the base currency
- [ ] The applicable capital-gains rate is resolved from the rate table by the asset's region + class
- [ ] Estimated tax and net realised gain are shown per disposal and aggregated per portfolio
- [ ] Unrealised gains are clearly separated from realised (tax applies only to realised)
- [ ] A documented cost-basis method (e.g. average cost) is used consistently for partial sales
- [ ] Estimates are labelled as estimates (this is not tax advice)

## Context

Reads rates from
[tax rate configuration](/projects/financial-assets/tasks/tax-rate-config.md) and
builds on the return/aggregation work in
[portfolio ROI](/projects/financial-assets/tasks/portfolio-roi.md). Requires a
disposal/sale concept — if holdings don't yet record sales, that's a
prerequisite to surface here. Realised vs unrealised is the key distinction; a
flat rate per cell, no holding-period or loss-carryforward rules.
