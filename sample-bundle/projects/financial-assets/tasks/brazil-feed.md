---
type: task
title: "Brazil feed: B3 & Tesouro Direto (brapi.dev)"
description: "Daily prices for B3 tickers and Tesouro Direto via brapi.dev."
tags: [market-data, brazil]
status: draft
priority: p1
order: "0|i00007:"
parent: projects/financial-assets/milestones/market-data
blocked_by: [projects/financial-assets/tasks/provider-abstraction]
timestamp: 2026-07-09T00:00:00Z
---

Implement the `PriceProvider` for Brazilian assets: B3 tickers and Tesouro
Direto bonds, using brapi.dev (free tier), with the Tesouro Transparente open CSV
as a fallback for Tesouro.

## Acceptance criteria

- [ ] Fetches latest quote for a B3 ticker (e.g. `PETR4`) in BRL with the quote date
- [ ] Fetches current Tesouro Direto unit prices by bond name/maturity (e.g. Tesouro Selic 2029)
- [ ] Falls back to the Tesouro Transparente CSV when brapi Tesouro data is unavailable
- [ ] Respects brapi free-tier rate limits (declared via the provider's rate-limit metadata)
- [ ] Results conform to `PriceProvider` and are written through the cache
- [ ] Unknown ticker / bond name yields a clear typed error; a fixture test covers one B3 ticker and one Tesouro bond

## Context

Implements the protocol from
[provider abstraction](/projects/financial-assets/tasks/provider-abstraction.md).
Tesouro Direto is priced per-bond, not per-ticker — model it as a market-priced
asset whose "symbol" is the bond identifier. See
[scope & data sources](/knowledge/wealth-app.md).
