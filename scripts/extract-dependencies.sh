#!/bin/bash

# Extract open source dependencies from Package.resolved
# This script generates a list of dependencies for the AcknowledgmentsView

set -e

echo "Extracting open source dependencies..."

# Path to Package.resolved
PACKAGE_RESOLVED="ios/Haumana.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

if [ ! -f "$PACKAGE_RESOLVED" ]; then
    echo "Error: Package.resolved not found at $PACKAGE_RESOLVED"
    exit 1
fi

echo ""
echo "Current Dependencies:"
echo "===================="

# Extract GoogleSignIn info
if grep -q "googlesignin-ios" "$PACKAGE_RESOLVED"; then
    VERSION=$(grep -A 3 "googlesignin-ios" "$PACKAGE_RESOLVED" | grep "version" | cut -d'"' -f4)
    echo "GoogleSignIn:"
    echo "  Version: $VERSION"
    echo "  License: Apache 2.0"
    echo "  URL: https://github.com/google/GoogleSignIn-iOS"
fi

echo ""
echo "To update AcknowledgmentsView.swift, add these dependencies to the Open Source Software section."
echo ""

# Additional dependencies that come with GoogleSignIn
echo "Transitive Dependencies (included with GoogleSignIn):"
echo "- AppAuth-iOS (Apache 2.0)"
echo "- GTMSessionFetcher (Apache 2.0)"
echo "- GTMAppAuth (Apache 2.0)"