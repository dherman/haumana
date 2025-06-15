#!/bin/bash

# Test build script for Lambda functions
# This verifies that TypeScript compiles correctly before deployment

set -e

echo "🔨 Testing Lambda function builds..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf dist/

# TypeScript compilation
echo "Compiling TypeScript..."
npm run build

# Check if files were created
if [ ! -f "dist/sync-pieces-lambda.js" ]; then
    echo "❌ sync-pieces-lambda.js not found after build"
    exit 1
fi

if [ ! -f "dist/sync-sessions-lambda.js" ]; then
    echo "❌ sync-sessions-lambda.js not found after build"
    exit 1
fi

echo "✅ TypeScript compilation successful"

# Bundle for production
echo "Creating production bundles..."
npm run bundle

# Check bundle sizes
echo ""
echo "📦 Bundle sizes:"
ls -lh dist/*.js | grep -E "(sync-pieces|sync-sessions)"

# Verify exports
echo ""
echo "🔍 Verifying Lambda handler exports..."

# Check for handler export in sync-pieces
if grep -q "exports.handler" dist/sync-pieces-lambda.js; then
    echo "✅ sync-pieces-lambda has handler export"
else
    echo "❌ sync-pieces-lambda missing handler export"
    exit 1
fi

# Check for handler export in sync-sessions
if grep -q "exports.handler" dist/sync-sessions-lambda.js; then
    echo "✅ sync-sessions-lambda has handler export"
else
    echo "❌ sync-sessions-lambda missing handler export"
    exit 1
fi

echo ""
echo "✅ All Lambda functions built successfully!"
echo ""
echo "Next steps:"
echo "1. Run 'cd .. && ./deploy.sh' to deploy to AWS"
echo "2. Configure API Gateway endpoints"
echo "3. Update iOS app configuration"