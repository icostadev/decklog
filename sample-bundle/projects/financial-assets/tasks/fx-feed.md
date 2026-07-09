---
type: task
title: "FX rate feed (Frankfurter/ECB)"
description: "Replace manual FX rates with a daily feed."
tags: [market-data, fx]
status: draft
priority: p1
order: "0|i00008:"
parent: projects/financial-assets/milestones/market-data
blocked_by: [projects/financial-assets/tasks/provider-abstraction]
timestamp: 2026-07-09T00:00:00Z
---

Implement the `FXRateProvider` using Frankfurter (ECB data, free, no key) to
supply daily rates, replacing the manual FX rates entered in Foundation.

## Acceptance criteria

- [ ] Fetches daily rates covering all in-scope currencies: USD, BRL, EUR, GBP, JPY, HKD, CNY
- [ ] Resolves any currency pair among those, including cross-rates not quoted directly (via a common base)
- [ ] Returns rate + effective date, conforming to `FXRateProvider`, written through the cache
- [ ] The conversion service now prefers fetched rates but still accepts a manual override
- [ ] Weekend/holiday gaps fall back to the most recent published rate, flagged as stale
- [ ] A fixture test covers a direct pair and a computed cross-rate

## Context

Implements the protocol from
[provider abstraction](/projects/financial-assets/tasks/provider-abstraction.md)
and swaps into the conversion service built in
[currency & base-currency conversion](/projects/financial-assets/tasks/currency-conversion.md).
Frankfurter publishes ECB reference rates once per business day — daily
granularity by design. See [scope & data sources](/knowledge/wealth-app.md).
