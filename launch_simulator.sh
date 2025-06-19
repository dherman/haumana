#!/bin/bash

# Build and install the app
echo "Building app..."
xcodebuild -scheme haumana \
  -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' \
  -project ios/Haumana.xcodeproj \
  -derivedDataPath build \
  build

if [ $? -ne 0 ]; then
  echo "Build failed"
  exit 1
fi

# Boot the simulator
echo "Booting simulator..."
xcrun simctl boot "iPhone 16" 2>/dev/null || true

# Install the app
echo "Installing app..."
xcrun simctl install "iPhone 16" build/Build/Products/Debug-iphonesimulator/haumana.app

# Launch the app
echo "Launching app..."
xcrun simctl launch --console "iPhone 16" app.haumana