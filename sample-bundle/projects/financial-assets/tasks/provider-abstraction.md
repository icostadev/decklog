---
type: task
title: "Provider abstraction & local price cache"
description: "Define provider protocols for price/dividend/FX feeds with a local cache."
tags: [market-data, architecture]
status: in_progress
assignee: agents/backend-impl
priority: p1
order: "0|i00005:"
parent: projects/financial-assets/milestones/market-data
blocked_by: [projects/financial-assets/tasks/asset-data-model]
timestamp: 2026-07-09T00:00:00Z
---

Define the protocols that every feed implements, plus a local cache, so the app
works offline between daily refreshes and survives a feed outage. This is the
seam the concrete feeds plug into — build it before any of them.

## Acceptance criteria

- [ ] `PriceProvider`, `DividendProvider`, and `FXRateProvider` protocols defined, each returning async results with an explicit typed error
- [ ] A provider registry resolves the right provider for a given asset (by region/market) or currency pair
- [ ] Fetched quotes, dividends, and FX rates are persisted to a SwiftData-backed cache keyed by symbol/pair + date
- [ ] Reads go through the cache first; a `staleness`/`asOf` date is exposed so callers know how old data is
- [ ] A feed failure falls back to the last cached value rather than erroring the whole refresh
- [ ] Rate-limit metadata (min interval between calls) is part of the protocol so the [daily refresh](/projects/financial-assets/tasks/daily-refresh.md) can respect it

## Context

Depends on the [asset data model](/projects/financial-assets/tasks/asset-data-model.md)
(providers only touch *market-priced* assets and currency pairs). The three
concrete feeds —
[equity/bond](/projects/financial-assets/tasks/equity-price-feed.md),
[Brazil](/projects/financial-assets/tasks/brazil-feed.md), and
[FX](/projects/financial-assets/tasks/fx-feed.md) — implement these protocols, so
their symbols and units must be nailed down here. Free/unofficial feeds are
rate-limited and can change without notice; the cache is what keeps the app
usable regardless. See [scope & data sources](/knowledge/wealth-app.md).
