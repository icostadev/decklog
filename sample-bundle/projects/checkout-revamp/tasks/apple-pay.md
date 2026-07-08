---
type: task
title: "Add Apple Pay to checkout"
description: "Enable Apple Pay as a one-tap option at checkout."
tags: [payments, mobile]
timestamp: 2026-07-08T10:32:00Z
status: in_progress
assignee: agents/backend-impl
priority: p1
order: "0|hzzzzz:"
start: 2026-07-06
due: 2026-07-14
parent: projects/checkout-revamp/milestones/beta
blocked_by: [projects/checkout-revamp/tasks/pci-review]
relates_to: [knowledge/checkout-flow]
cycle: cycles/2026-q3-s2
---

Add Apple Pay as a one-tap payment option in the checkout flow.

## Acceptance criteria

- [ ] Apple Pay button appears on the payment step for eligible devices
- [ ] A successful payment creates an order and shows confirmation
- [ ] Failures surface a retryable error

## Context

The current checkout is described in [checkout flow](/knowledge/checkout-flow.md).
We chose Apple Pay per [this decision](/knowledge/decisions/apple-pay-over-stripe-link.md).
