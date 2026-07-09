---
type: task
title: "Currency model & base-currency conversion"
description: "Handle multiple currencies and convert everything to a user-selected base currency for reporting."
tags: [currency, fx]
status: in_review
artifacts: ["https://github.com/acme/wealth/pull/11"]
assignee: agents/backend-impl
priority: p1
order: "0|i00002:"
parent: projects/financial-assets/milestones/foundation
blocked_by: [projects/financial-assets/tasks/asset-data-model]
timestamp: 2026-07-09T00:00:00Z
---

Support multiple currencies and convert every amount to a single base currency
for reporting.

## Acceptance criteria

- [ ] Supported currencies cover the target markets: USD, BRL, EUR, GBP, JPY, HKD, CNY
- [ ] Base currency is a user setting on the Settings screen, defaulting to USD
- [ ] An FX rate store holds a rate per currency pair with a date (entered manually for now)
- [ ] A conversion service converts any amount from its native currency to the base currency
- [ ] Missing or stale FX rates are surfaced clearly, never silently treated as 1:1

## Context

FX rates are manual in Foundation;
[Market data](/projects/financial-assets/milestones/market-data.md) swaps in the
Frankfurter/ECB feed later. Isolate conversion behind a service so views never
do currency math inline. See [scope & data sources](/knowledge/wealth-app.md).
