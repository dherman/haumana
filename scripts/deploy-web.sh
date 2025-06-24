#!/bin/bash

# Deploy web content to GitHub Pages
# This script deploys the web/ directory to the gh-pages branch

set -e

echo "Deploying Haumana web content to GitHub Pages..."

# Store current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

# Create temporary directory
TEMP_DIR=$(mktemp -d)

# Copy web content to temp directory
cp -R web/* "$TEMP_DIR/"

# Check if gh-pages branch exists
if git show-ref --quiet refs/heads/gh-pages; then
    echo "gh-pages branch exists, updating..."
    git checkout gh-pages
else
    echo "Creating gh-pages branch..."
    git checkout --orphan gh-pages
    git rm -rf .
fi

# Copy files from temp directory
cp -R "$TEMP_DIR"/* .

# Add all files
git add -A

# Commit if there are changes
if ! git diff --cached --quiet; then
    git commit -m "Update GitHub Pages site"
    echo "Changes committed"
else
    echo "No changes to commit"
fi

# Push to GitHub
echo "Pushing to GitHub..."
git push origin gh-pages

# Switch back to original branch
git checkout "$CURRENT_BRANCH"

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ Deployment complete!"
echo ""
echo "Your site will be available at:"
echo "  https://haumana.app"
echo ""
echo "Legal documents will be at:"
echo "  https://haumana.app/legal/privacy-policy"
echo "  https://haumana.app/legal/terms-of-service"
echo ""
echo "Note: It may take a few minutes for changes to appear."