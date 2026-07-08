#!/usr/bin/env bash
#
# Build the OKF-PM macOS app and assemble a launchable .app bundle.
# Requires macOS with a Swift toolchain (Xcode command-line tools).
#
# Usage:
#   scripts/build-app.sh [debug|release]     (default: release)
#
set -euo pipefail

CONFIG="${1:-release}"
APP_TARGET="OKFPMApp"        # SwiftPM executable target name
BUNDLE_NAME="OKF-PM"         # user-facing .app name
BUNDLE_ID="com.okfpm.app"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PKG="$ROOT/app"
DIST="$ROOT/dist"

# --- preconditions ---------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: the OKF-PM app is macOS-only (it uses SwiftUI). Run this on a Mac." >&2
  exit 1
fi
if ! command -v swift >/dev/null 2>&1; then
  echo "error: 'swift' not found. Install Xcode or the command-line tools." >&2
  exit 1
fi

# --- build -----------------------------------------------------------------
echo "==> Building $APP_TARGET ($CONFIG)…"
BIN_DIR="$(cd "$APP_PKG" && swift build -c "$CONFIG" --show-bin-path)"
( cd "$APP_PKG" && swift build -c "$CONFIG" )

BIN_PATH="$BIN_DIR/$APP_TARGET"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "error: built binary not found at $BIN_PATH" >&2
  exit 1
fi

# --- assemble .app bundle --------------------------------------------------
echo "==> Assembling $BUNDLE_NAME.app…"
APP_DIR="$DIST/$BUNDLE_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$BUNDLE_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>$BUNDLE_NAME</string>
    <key>CFBundleDisplayName</key>       <string>$BUNDLE_NAME</string>
    <key>CFBundleIdentifier</key>        <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>        <string>$BUNDLE_NAME</string>
    <key>CFBundleVersion</key>           <string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSPrincipalClass</key>          <string>NSApplication</string>
</dict>
</plist>
PLIST

# Ad-hoc code sign so the app launches locally without Gatekeeper complaints.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 \
    || echo "warn: ad-hoc codesign failed; the app may still run locally."
fi

# --- done ------------------------------------------------------------------
echo "==> Done."
echo "    binary: $BIN_PATH"
echo "    app:    $APP_DIR"
echo
echo "Run it:"
echo "    open \"$APP_DIR\""
echo "  or, pointed at the sample bundle:"
echo "    OKFPM_BUNDLE=\"$ROOT/sample-bundle\" \"$APP_DIR/Contents/MacOS/$BUNDLE_NAME\""
