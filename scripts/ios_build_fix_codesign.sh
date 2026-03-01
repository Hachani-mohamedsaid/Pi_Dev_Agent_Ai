#!/bin/bash
# iOS build helper for macOS Sequoia+ "resource fork / detritus" codesign errors.
# Grant Terminal (and Xcode if you build from Xcode) Full Disk Access:
#   System Settings → Privacy & Security → Full Disk Access
# Then run: ./scripts/ios_build_fix_codesign.sh
# Or: flutter build ios --debug (from Terminal with FDA)

set -e
cd "$(dirname "$0")/.."
PROJECT_ROOT="$PWD"
FLUTTER_ROOT="${FLUTTER_ROOT:-$(which flutter | xargs dirname | xargs dirname)}"

echo "Stripping extended attributes (com.apple.provenance) from build and Flutter cache..."
xattr -cr "$PROJECT_ROOT/build/ios" 2>/dev/null || true
xattr -cr "$PROJECT_ROOT/.dart_tool" 2>/dev/null || true
[ -d "$FLUTTER_ROOT/bin/cache/artifacts/engine" ] && xattr -cr "$FLUTTER_ROOT/bin/cache/artifacts/engine" 2>/dev/null || true

echo "Running flutter build ios --debug..."
flutter build ios --debug

echo "Build finished. You can run the app from Xcode on your device."
