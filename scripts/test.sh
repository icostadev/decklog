#!/usr/bin/env bash
#
# Run the OKFKit test suite (the app target has no tests).
# Requires a Swift toolchain (macOS with Xcode command-line tools, or Linux Swift).
#
# Usage:
#   scripts/test.sh                          # run all OKFKit tests
#   scripts/test.sh SchemaTests              # only a suite
#   scripts/test.sh SchemaTests/testParseFullFormWithRenamedRoleAndLabel   # one test
#   scripts/test.sh -c release               # (any extra flags are passed to `swift test`)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OKFKIT="$ROOT/OKFKit"

# --- preconditions ---------------------------------------------------------
if ! command -v swift >/dev/null 2>&1; then
  echo "error: 'swift' not found. Install Xcode or the command-line tools." >&2
  exit 1
fi

# `swift test` needs XCTest, which ships with full Xcode — NOT the bare Command Line
# Tools. If the active developer dir is the CLT and an Xcode is installed, use it.
if [[ "$(uname -s)" == "Darwin" ]]; then
  DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
  if [[ "$DEV_DIR" == *CommandLineTools* ]]; then
    for xc in /Applications/Xcode.app/Contents/Developer /Applications/Xcode-*.app/Contents/Developer; do
      if [[ -d "$xc" ]]; then
        echo "note: active dev dir is Command Line Tools (no XCTest); using $xc" >&2
        export DEVELOPER_DIR="$xc"
        break
      fi
    done
    if [[ "${DEVELOPER_DIR:-}" != *Xcode* ]]; then
      echo "error: XCTest is unavailable — no full Xcode found. Install Xcode, then run:" >&2
      echo "         sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
      exit 1
    fi
  fi
fi

# --- assemble args ---------------------------------------------------------
# A bare first argument that isn't a flag is treated as a --filter pattern;
# anything else is forwarded to `swift test` untouched.
ARGS=()
if [[ $# -gt 0 && "$1" != -* ]]; then
  ARGS+=(--filter "$1")
  shift
fi
ARGS+=("$@")

# --- run -------------------------------------------------------------------
echo "==> swift test${ARGS:+ ${ARGS[*]}}  (in OKFKit)"
cd "$OKFKIT"
# `${ARGS[@]+...}` guards the empty-array case under `set -u` on macOS's bash 3.2.
exec swift test ${ARGS[@]+"${ARGS[@]}"}
