---
type: task
title: "Equity & bond price feed (Stooq/Yahoo)"
description: "Daily EOD prices for US, Europe, and Asia listed assets."
tags: [market-data]
status: ready
priority: p1
order: "0|i00006:"
parent: projects/financial-assets/milestones/market-data
blocked_by: [projects/financial-assets/tasks/provider-abstraction]
timestamp: 2026-07-09T00:00:00Z
---

Implement the `PriceProvider` for globally listed equities, ETFs, and bonds
across the target exchanges, using Stooq EOD CSV (no key) with Yahoo Finance as
an alternate. Daily/EOD granularity is enough.

## Acceptance criteria

- [ ] Fetches latest EOD close for a ticker on NYSE, NASDAQ, XETRA, LSE, Euronext, TSE, HKEX, and SSE
- [ ] Maps each market's ticker convention to the feed's symbol format (e.g. Stooq suffixes) via a documented table
- [ ] Returns price with its native currency and the quote date, conforming to `PriceProvider`
- [ ] Results are written through the cache; an unknown/unsupported symbol yields a clear typed error, not a crash
- [ ] HTTP/parse failures surface as provider errors and fall back to cache
- [ ] A small fixture-based test covers CSV parsing for at least one ticker per region

## Context

Implements the protocol from
[provider abstraction](/projects/financial-assets/tasks/provider-abstraction.md).
Symbol-format mapping is the main risk — keep it in one table so it's easy to
correct. Brazil is handled separately by the
[Brazil feed](/projects/financial-assets/tasks/brazil-feed.md). See
[scope & data sources](/knowledge/wealth-app.md).
