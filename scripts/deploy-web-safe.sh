#!/bin/bash

# Deploy web content to GitHub Pages using git worktree
# This script safely deploys the web/ directory to the gh-pages branch
# without affecting the main working directory

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

# Create a temporary directory for the worktree
TEMP_DIR=$(mktemp -d)
WORKTREE_DIR="$TEMP_DIR/gh-pages-worktree"

# Function to clean up on exit
cleanup() {
    echo "Cleaning up..."
    if [ -d "$WORKTREE_DIR" ]; then
        git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    fi
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check if gh-pages branch exists
if git show-ref --quiet refs/heads/gh-pages; then
    echo "gh-pages branch exists, checking out as worktree..."
    git worktree add "$WORKTREE_DIR" gh-pages
else
    echo "Creating gh-pages branch..."
    # Create orphan branch without switching to it
    git worktree add --detach "$WORKTREE_DIR"
    cd "$WORKTREE_DIR"
    git checkout --orphan gh-pages
    git rm -rf . 2>/dev/null || true
    cd "$REPO_ROOT"
fi

# Clear the worktree directory (except .git)
cd "$WORKTREE_DIR"
find . -mindepth 1 -maxdepth 1 -not -name '.git' -exec rm -rf {} +

# Copy web content
cp -R "$REPO_ROOT/web/"* .

# Add CNAME file for custom domain
echo "haumana.app" > CNAME

# Add .nojekyll file to bypass Jekyll processing
touch .nojekyll

# Stage all changes
git add -A

# Commit if there are changes
if ! git diff --cached --quiet; then
    git commit -m "Update GitHub Pages site - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Changes committed"
else
    echo "No changes to commit"
fi

# Push to GitHub
echo "Pushing to GitHub..."
git push origin gh-pages

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