---
type: task
title: "Daily refresh & offline cache"
description: "Refresh prices, dividends, and FX once a day; work offline in between."
tags: [market-data]
status: draft
priority: p2
order: "0|i00010:"
parent: projects/financial-assets/milestones/market-data
blocked_by: [projects/financial-assets/tasks/equity-price-feed, projects/financial-assets/tasks/fx-feed]
timestamp: 2026-07-09T00:00:00Z
---

Orchestrate a once-a-day refresh across every provider, respecting rate limits,
and fall back to the local cache when offline or when a feed fails.

## Acceptance criteria

- [ ] A single refresh action fetches prices, dividends, and FX for all held assets and in-use currency pairs
- [ ] Runs automatically at most once per day, and on demand via a manual "Refresh now" control
- [ ] Respects each provider's declared rate limits (throttles/spaces requests)
- [ ] A per-provider failure is isolated: other feeds still update, and the failed one keeps its cached values
- [ ] Last-updated timestamp shown in the UI, with a clear "offline / stale" indication when data isn't fresh
- [ ] Refresh runs off the main thread and never blocks the UI

## Context

Depends on the
[equity/bond feed](/projects/financial-assets/tasks/equity-price-feed.md) and
[FX feed](/projects/financial-assets/tasks/fx-feed.md); it also drives the
[Brazil feed](/projects/financial-assets/tasks/brazil-feed.md) and
[dividend tracking](/projects/financial-assets/tasks/dividend-tracking.md) when
present. Uses the rate-limit metadata and cache from
[provider abstraction](/projects/financial-assets/tasks/provider-abstraction.md).
Daily/EOD cadence is the design target — no intraday polling.
