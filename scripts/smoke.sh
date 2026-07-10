#!/usr/bin/env bash
#
# Run the OKFKit smoke check — a no-XCTest verification of the core schema logic that runs
# with only the Command Line Tools (no full Xcode needed). For the full XCTest suite use
# scripts/test.sh (requires Xcode or a swift.org toolchain).
#
# Usage:
#   scripts/smoke.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v swift >/dev/null 2>&1; then
  echo "error: 'swift' not found. Install Xcode or the command-line tools." >&2
  exit 1
fi

echo "==> swift run OKFKitSmoke  (in OKFKit)"
cd "$ROOT/OKFKit"
exec swift run OKFKitSmoke
