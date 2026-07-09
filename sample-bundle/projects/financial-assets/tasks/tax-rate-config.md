---
type: task
title: "Tax rate configuration"
description: "Configurable tax rate table keyed by region and asset class."
tags: [tax]
status: ready
priority: p2
order: "0|i00016:"
parent: projects/financial-assets/milestones/tax
timestamp: 2026-07-09T00:00:00Z
---

A settings surface and store for a simple tax rate table — the data the dividend
and capital-gains calculations read from. Deliberately not a full tax engine.

## Acceptance criteria

- [ ] A rate table holds a dividend rate and a capital-gains rate per (region, asset class)
- [ ] Shipped with editable defaults for the four regions; the user can override any cell
- [ ] Rates persist via SwiftData and survive relaunch
- [ ] A lookup service resolves the applicable rate for a given asset (by its region + type), with a sensible default when unset
- [ ] Settings UI to view and edit the table
- [ ] Rates validated (0–100%); invalid input rejected with a clear message

## Context

The foundation for the Tax milestone — no calculations here, just the
configurable inputs that
[dividend tax](/projects/financial-assets/tasks/dividend-tax.md) and
[capital-gains tax](/projects/financial-assets/tasks/capital-gains-tax.md) read.
Kept simple on purpose: "Europe" and "Asia" span many regimes, so this is a
user-owned rate table, not modelled law. See
[scope & data sources](/knowledge/wealth-app.md).
