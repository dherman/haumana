#!/bin/bash
# Deploy AWS infrastructure for Haumana
# This script builds Lambda functions and deploys the CDK stack

set -e

# Google OAuth Client ID (public, not a secret)
export GOOGLE_CLIENT_ID=872799888201-clt1m5ovtoonn7gg6o0738i9alrnnhih.apps.googleusercontent.com

ROOT_DIR="$( (cd $(dirname $0)/.. && pwd) )"
echo "Root directory: $ROOT_DIR"

echo "Building Lambda functions..."
cd "$ROOT_DIR/aws/lambdas"
npm install
npm run build

echo "Deploying CDK stack..."
cd "$ROOT_DIR/aws/infrastructure/cdk"
npm install
# Pass any additional arguments to cdk deploy (e.g., --require-approval never)
npx cdk deploy "$@"
