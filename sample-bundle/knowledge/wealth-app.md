---
type: knowledge
title: "Wealth app: scope & data sources"
description: "Scoping decisions for the Financial assets management project — platform, markets, currencies, data feeds, and the projection formula."
tags: [wealth, scope, reference]
timestamp: 2026-07-09T00:00:00Z
---

# Financial assets management — scope & data sources

Reference for the [project](/projects/financial-assets/project.md). Captures the
decisions made during scoping so tasks don't re-litigate them.

## Platform
Native macOS app, SwiftUI + SwiftData, single-user, local storage.

## Asset model
Two kinds:
- **Market-priced** — stocks, bonds, ETFs, Tesouro Direto. Carry a ticker/symbol; refreshed from a daily feed.
- **Manually-valued** — real estate, cars, boats. No feed; valuations entered by the user.

## Regions & markets (biggest per region)
- **Brazil:** B3 (São Paulo), Tesouro Direto
- **US:** NYSE, NASDAQ
- **Europe:** XETRA (Frankfurt), LSE (London), Euronext (Paris/Amsterdam)
- **Asia:** Tokyo (TSE), Hong Kong (HKEX), Shanghai (SSE)

## Currencies
Native currency stored per asset; everything rolls up to a **base currency**,
which is a user setting defaulting to **USD**. In scope: USD, BRL, EUR, GBP,
JPY, HKD, CNY.

## Data sources (free, daily/EOD; behind a provider abstraction, cached locally)
- **Global equities / bonds / ETFs:** Stooq (EOD CSV, no key) or Yahoo Finance (unofficial)
- **Brazil (B3) + Tesouro Direto:** brapi.dev (free tier); Tesouro Transparente CSV as a fallback
- **FX rates:** Frankfurter (ECB data, free, no key)

Free/unofficial feeds are rate-limited and can change without notice — hence the
provider protocol and the local cache so the app works offline between refreshes.

## Projections
Extrapolate future net worth from historical performance, in two scenarios:
- **Optimistic:** future annual return = historical average (CAGR)
- **Pessimistic:** historical CAGR minus a spread, **default 3 percentage points** (user-configurable)

## Tax (later milestone)
Region- and asset-class-aware tax on dividends and capital gains, via a simple
configurable rate table — not a full tax engine.
