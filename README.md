# Decklog

A personal, macOS-only project-management app where the work lives as an
[OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
bundle (markdown + YAML frontmatter) in a git repo. See [`docs/DESIGN.md`](docs/DESIGN.md)
for the full design and the six-iteration delivery plan.

## Layout

```
OKFKit/         Swift package — the bundle core (parse / validate / round-trip). Cross-platform, unit-tested.
app/            Swift package — the SwiftUI macOS app (Iteration 1: read-only board). macOS only.
sample-bundle/  A hand-authored OKF bundle used by tests and for running the app.
docs/DESIGN.md  Design & data model.
```

## Iteration 1 — status

Read-only board over a real bundle, no agents yet (DESIGN.md §11).

- **`OKFKit` (verified):** OKF frontmatter parsing, order/unknown-key-preserving
  round-trip, bundle loading (reserved files excluded, ids = path minus `.md`), derived
  `blocks` inverse, and the advisory validation pass (dangling refs, cycles, status
  vocabulary, date sanity). **15 XCTest cases pass** on Linux and macOS.
- **`app` (written, not yet compiled):** the SwiftUI board, sidebar scoping by project,
  and task detail. SwiftUI cannot build on Linux, so this must be built on macOS — see
  below. Treat it as unverified until you run it in Xcode.

Known limitation: the YAML round-trip preserves unknown keys and key order but **not
comments** (a later-iteration concern).

## Build & test the core (any platform with a Swift toolchain)

```sh
cd OKFKit
swift test
```

## Build a `.app` (macOS)

```sh
scripts/build-app.sh            # release build → dist/Decklog.app (ad-hoc signed)
scripts/build-app.sh debug      # debug build
```

The script builds via SwiftPM, wraps the binary in a launchable `.app` bundle with an
`Info.plist`, and prints how to run it. It refuses to run off macOS.

## Run the app (macOS + Xcode)

Open the app package in Xcode and run the `Decklog` scheme:

```sh
open app/Package.swift          # opens in Xcode
```

Or from the terminal on macOS:

```sh
cd app
DECKLOG_BUNDLE="$(cd ../sample-bundle && pwd)" swift run Decklog
```

`DECKLOG_BUNDLE` auto-opens that bundle on launch (dev convenience); otherwise use
**Open Bundle…** (⌘O) and pick the `sample-bundle` directory.
