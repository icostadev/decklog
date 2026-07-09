---
type: project
title: "Financial assets management"
description: "A native macOS app for tracking a multi-region, multi-asset portfolio and managing wealth over time."
status: active
start: 2026-07-09
timestamp: 2026-07-09T00:00:00Z
---

A native macOS (SwiftUI + SwiftData) application for tracking personal wealth
across a heterogeneous, multi-region portfolio and analysing it over time.

**Assets** split into two kinds: *market-priced* (stocks, bonds, ETFs, Tesouro
Direto — refreshed from a daily price feed) and *manually-valued* (real estate,
cars, boats — valuations entered by the user). Everything is stored in its
native currency and rolled up to a user-selected **base currency (default USD)**
via FX conversion.

**Regions & markets:** Brazil (B3, Tesouro Direto), US (NYSE, NASDAQ), Europe
(XETRA, LSE, Euronext), Asia (Tokyo TSE, Hong Kong HKEX, Shanghai SSE).

**Capabilities**, delivered by milestone: net-worth tracking, daily price &
dividend fetching, ROI (per-asset and portfolio) and wealth-over-time analytics,
future projections (optimistic + pessimistic), and region-aware tax on dividends
and capital gains.

See [scope & data sources](/knowledge/wealth-app.md) for the decisions behind
this plan.
