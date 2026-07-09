---
type: milestone
title: "Market data"
description: "Daily price, dividend, and FX fetching behind a provider abstraction."
status: active
project: projects/financial-assets/project
order: "0|i00001:"
timestamp: 2026-07-09T00:00:00Z
---

Replace manual prices and FX rates with free daily feeds, fetched behind a
provider protocol and cached locally so the app works offline between refreshes.

Sources: Stooq/Yahoo (global equities & bonds), brapi.dev (B3 + Tesouro Direto),
Frankfurter/ECB (FX). See [scope & data sources](/knowledge/wealth-app.md).
