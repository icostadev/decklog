---
type: task
title: "Projection view"
description: "Chart projected future net worth for both scenarios."
tags: [projections, ui]
status: draft
priority: p2
order: "0|i00015:"
parent: projects/financial-assets/milestones/projections
blocked_by: [projects/financial-assets/tasks/projection-engine]
timestamp: 2026-07-09T00:00:00Z
---

Chart projected net worth over a chosen horizon, showing both scenarios against
actual history.

## Acceptance criteria

- [ ] Optimistic and pessimistic projections plotted (Swift Charts) as distinct series continuing from the last actual point
- [ ] Historical net worth shown on the same axis so the projection reads as a continuation, not a separate chart
- [ ] Horizon selectable (e.g. 5 / 10 / 20 years); chart updates live
- [ ] Pessimistic spread adjustable from the view (or clearly linked to the setting), with the chart updating on change
- [ ] Projected end-of-horizon values and implied CAGR labelled for both scenarios
- [ ] Empty/insufficient-history state mirrors the engine's reporting

## Context

A thin render over the
[projection engine](/projects/financial-assets/tasks/projection-engine.md) —
no projection math in the view. Reuses the history rendering from
[wealth-over-time](/projects/financial-assets/tasks/wealth-history.md) so actuals
and projections share one visual language.
