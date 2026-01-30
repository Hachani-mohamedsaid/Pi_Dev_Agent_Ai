#!/bin/bash
# Fix code signing issue for macOS Sequoia
# This script removes extended attributes from Flutter framework before code signing

set -e

FLUTTER_FRAMEWORK="$1"

if [ -z "$FLUTTER_FRAMEWORK" ]; then
    echo "Usage: $0 <path_to_Flutter.framework/Flutter>"
    exit 1
fi

# Remove all extended attributes
xattr -cr "$FLUTTER_FRAMEWORK" 2>/dev/null || true

# Remove specific Finder attributes
xattr -d com.apple.FinderInfo "$FLUTTER_FRAMEWORK" 2>/dev/null || true
xattr -d com.apple.ResourceFork "$FLUTTER_FRAMEWORK" 2>/dev/null || true

# Use ditto to copy and strip attributes
TEMP_FILE=$(mktemp)
ditto "$FLUTTER_FRAMEWORK" "$TEMP_FILE" 2>/dev/null || cp "$FLUTTER_FRAMEWORK" "$TEMP_FILE"
mv "$TEMP_FILE" "$FLUTTER_FRAMEWORK"

echo "Fixed extended attributes for: $FLUTTER_FRAMEWORK"
