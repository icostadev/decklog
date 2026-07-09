---
type: task
title: "Asset data model"
description: "Define SwiftData models for assets, holdings, and valuations, with the market-priced vs manually-valued split."
tags: [data, swiftdata]
status: done
artifacts: ["https://github.com/acme/wealth/pull/5"]
assignee: agents/backend-impl
priority: p1
order: "0|i00001:"
parent: projects/financial-assets/milestones/foundation
blocked_by: [projects/financial-assets/tasks/app-scaffold]
timestamp: 2026-07-09T00:00:00Z
---

Define what an asset is and how holdings and valuations are stored, with a clean
split between market-priced and manually-valued assets. This is the backbone of
the whole app.

## Acceptance criteria

- [ ] An `Asset` has a stable id, name, type (stock/bond/etf/tesouro-direto/real-estate/car/boat/…), region, and native currency
- [ ] Assets distinguish *market-priced* (carry a ticker/symbol) from *manually-valued* (no feed)
- [ ] A `Holding` records quantity and cost basis (amount + currency + acquisition date)
- [ ] A `Valuation` records a value at a point in time as an append-only record, so history is preserved
- [ ] Models persist via SwiftData and survive relaunch
- [ ] Region and market enums cover the targets: B3, NYSE, NASDAQ, XETRA, LSE, Euronext, TSE, HKEX, SSE

## Context

Depends on the [app scaffold](/projects/financial-assets/tasks/app-scaffold.md).
The market-priced vs manually-valued split is what lets the M2 feeds touch only
market-priced assets. Keep valuations append-only so
[wealth-over-time](/projects/financial-assets/tasks/wealth-history.md) can chart
them later. See [scope & data sources](/knowledge/wealth-app.md).
