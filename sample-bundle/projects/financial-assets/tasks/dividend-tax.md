---
type: task
title: "Dividend tax"
description: "Apply region/asset-class tax rates to dividends."
tags: [tax, dividends]
status: cancelled
priority: p2
order: "0|i00017:"
parent: projects/financial-assets/milestones/tax
blocked_by: [projects/financial-assets/tasks/tax-rate-config, projects/financial-assets/tasks/dividend-tracking]
timestamp: 2026-07-09T00:00:00Z
---

Apply the configured dividend rates to recorded dividends to show gross vs net
income, and feed net dividends into returns.

## Acceptance criteria

- [ ] For each dividend, the applicable rate is resolved from the rate table by the asset's region + class
- [ ] Gross dividend, tax withheld, and net dividend are shown per holding and per portfolio, in the base currency
- [ ] ROI calculations can use net (post-tax) dividends, with pre-tax still available
- [ ] Currency conversion applies consistently to gross, tax, and net
- [ ] Assets with no configured rate fall back to the table's default and are flagged
- [ ] Estimates are labelled as estimates (this is not tax advice)

## Context

Reads rates from
[tax rate configuration](/projects/financial-assets/tasks/tax-rate-config.md) and
the events from
[dividend tracking](/projects/financial-assets/tasks/dividend-tracking.md). Net
figures flow into
[ROI per asset](/projects/financial-assets/tasks/roi-per-asset.md). A simple
flat-rate-per-cell model — no withholding-treaty or bracket logic.
