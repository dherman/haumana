#!/bin/bash

# Deploy web content to GitHub Pages with a clean approach
# This script creates a fresh gh-pages branch with only web content

set -e

echo "Deploying Haumana web content to GitHub Pages..."

# Ensure we're in the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Check if web directory exists
if [ ! -d "web" ]; then
    echo "Error: web/ directory not found"
    exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)

# Function to clean up on exit
cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Copy web content to temp directory
echo "Copying web content..."
cp -R web/* "$TEMP_DIR/"

# Initialize a new git repo in temp directory
cd "$TEMP_DIR"
git init
git checkout -b gh-pages

# Add CNAME file if not present
if [ ! -f "CNAME" ]; then
    echo "haumana.app" > CNAME
fi

# Add .nojekyll file to bypass Jekyll processing
touch .nojekyll

# Add all files
git add -A

# Commit
git commit -m "Deploy GitHub Pages - $(date '+%Y-%m-%d %H:%M:%S')"

# Add the original repo as remote
git remote add origin $(cd "$REPO_ROOT" && git remote get-url origin)

# Force push to gh-pages (this will overwrite the existing branch)
echo "Pushing to GitHub..."
git push -f origin gh-pages

# Return to original directory
cd "$REPO_ROOT"

echo "✅ Deployment complete!"
echo ""
echo "Your site will be available at:"
echo "  https://haumana.app (after DNS configuration)"
echo "  https://dherman.github.io/haumana (immediately)"
echo ""
echo "Legal documents will be at:"
echo "  https://haumana.app/legal/privacy-policy"
echo "  https://haumana.app/legal/terms-of-service"
echo ""
echo "Note: It may take a few minutes for changes to appear."