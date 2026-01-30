#!/bin/bash
# Wrapper script for flutter run that fixes code signing issues on macOS Sequoia

set -e

# Get the device ID from arguments or use default
DEVICE_ID=""
if [ "$1" == "-d" ] && [ -n "$2" ]; then
    DEVICE_ID="$2"
fi

# Clean build first
echo "Cleaning build..."
flutter clean > /dev/null 2>&1 || true

# Get dependencies
echo "Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Build through Xcode to avoid code signing issues
echo "Building through Xcode..."
if [ -n "$DEVICE_ID" ]; then
    xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,id=$DEVICE_ID" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        build > /tmp/xcode_build.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "Build successful! Installing app..."
        APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Runner.app" -path "*/Debug-iphonesimulator/*" | head -1)
        if [ -n "$APP_PATH" ]; then
            xcrun simctl install "$DEVICE_ID" "$APP_PATH"
            echo "Launching app..."
            xcrun simctl launch "$DEVICE_ID" com.example.piDevAgentia
            echo "App launched successfully!"
            echo "To see logs, run: flutter logs -d $DEVICE_ID"
        else
            echo "Error: Could not find built app. Trying alternative method..."
            flutter run -d "$DEVICE_ID"
        fi
    else
        echo "Build failed. Check /tmp/xcode_build.log for details."
        tail -30 /tmp/xcode_build.log
        exit 1
    fi
else
    # Fallback to regular flutter run
    flutter run "$@"
fi
