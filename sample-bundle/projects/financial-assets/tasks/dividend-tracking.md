---
type: task
title: "Dividend tracking"
description: "Fetch and record dividends per holding."
tags: [market-data, dividends]
status: draft
priority: p2
order: "0|i00009:"
parent: projects/financial-assets/milestones/market-data
blocked_by: [projects/financial-assets/tasks/equity-price-feed]
timestamp: 2026-07-09T00:00:00Z
---

Fetch dividend events for market-priced holdings and record them so ROI and
(later) dividend tax can use them.

## Acceptance criteria

- [ ] Fetches dividend events (amount per share, currency, ex-date, pay-date) via the `DividendProvider`
- [ ] Records dividends against the relevant holding, scaled by quantity held on the ex-date
- [ ] Dividends are stored as append-only records (like valuations) and survive relaunch
- [ ] Duplicate events are de-duplicated on re-fetch (idempotent by symbol + ex-date)
- [ ] Manual entry of a dividend is supported for assets/markets the feed doesn't cover
- [ ] Total dividends received per holding and per portfolio are queryable in the base currency

## Context

Depends on the
[equity/bond feed](/projects/financial-assets/tasks/equity-price-feed.md) for the
provider plumbing. Feed dividend coverage is uneven across exchanges — hence the
manual-entry fallback. Consumed by
[ROI per asset](/projects/financial-assets/tasks/roi-per-asset.md) and
[dividend tax](/projects/financial-assets/tasks/dividend-tax.md).
