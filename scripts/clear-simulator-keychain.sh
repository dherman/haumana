#!/bin/bash

# Clear the iOS Simulator keychain for Haumana app

echo "Clearing iOS Simulator Keychain for Haumana..."

# Find the booted simulator
BOOTED_DEVICE=$(xcrun simctl list devices | grep -E "Booted" | head -1 | grep -o "[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}")

if [ -z "$BOOTED_DEVICE" ]; then
    echo "No booted simulator found. Please boot a simulator first."
    exit 1
fi

echo "Found booted simulator: $BOOTED_DEVICE"

# The keychain is stored in the simulator's data directory
SIMULATOR_PATH="$HOME/Library/Developer/CoreSimulator/Devices/$BOOTED_DEVICE"

# Find and delete keychain items for Haumana
echo "Clearing Haumana keychain items..."

# Option 1: Delete the entire app's keychain data
find "$SIMULATOR_PATH" -name "keychain-2.db" -exec sqlite3 {} "DELETE FROM genp WHERE agrp LIKE '%haumana%';" \; 2>/dev/null

# Option 2: Reset the entire simulator keychain (more aggressive)
# xcrun simctl spawn $BOOTED_DEVICE defaults delete com.apple.security.keychain

echo "Keychain cleared. You may need to restart the app."