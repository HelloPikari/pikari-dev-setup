#!/bin/bash

# WordPress Plugin/Theme Release Script
# This script automates the release process, ensuring tags are created from the build branch
# which contains the compiled assets needed for Composer installations.

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get main file from user input or look for common patterns
if [ -z "$MAIN_FILE" ]; then
    # Try to detect main file
    MAIN_FILE=$(find . -maxdepth 1 -name "*.php" -exec grep -l "Plugin Name:\|Theme Name:" {} \; | head -1)
    if [ -z "$MAIN_FILE" ]; then
        print_error "Could not detect main plugin/theme file. Please set MAIN_FILE environment variable."
        exit 1
    fi
    MAIN_FILE=$(basename "$MAIN_FILE")
fi

# Check if we're in the project root
if [ ! -f "$MAIN_FILE" ]; then
    print_error "This script must be run from the plugin/theme root directory"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Ensure we're on main branch
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_error "You must be on the main branch to create a release. Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Please install it first."
    echo "On macOS: brew install jq"
    echo "On Ubuntu/Debian: sudo apt-get install jq"
    exit 1
fi

# Get current version from package.json
CURRENT_VERSION=$(jq -r '.version' package.json)
print_info "Current version: $CURRENT_VERSION"

# Prompt for new version
echo ""
read -p "Enter new version number (current: $CURRENT_VERSION): " NEW_VERSION

# Validate version format (basic semver check)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    print_error "Invalid version format. Please use semantic versioning (e.g., 1.2.3 or 1.2.3-beta)"
    exit 1
fi

# Confirm release
echo ""
print_warning "This will create a new release: v$NEW_VERSION"
print_warning "Make sure all changes are committed and pushed to main branch."
echo ""
read -p "Continue? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    print_info "Release cancelled."
    exit 0
fi

print_info "Starting release process for v$NEW_VERSION..."

# Step 1: Update version numbers in main branch
print_info "Updating version numbers..."

# Update main plugin/theme file
sed -i.bak "s/Version: .*/Version: $NEW_VERSION/" "$MAIN_FILE" && rm "${MAIN_FILE}.bak"

# Update version constant if it exists
if [ -f "includes/plugin.php" ]; then
    CONSTANT_NAME=$(echo "${PWD##*/}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_VERSION
    sed -i.bak "s/define('${CONSTANT_NAME}', '.*');/define('${CONSTANT_NAME}', '$NEW_VERSION');/" includes/plugin.php && rm includes/plugin.php.bak
fi

# Update package.json
jq ".version = \"$NEW_VERSION\"" package.json > package.json.tmp && mv package.json.tmp package.json

# Update CHANGELOG.md if it exists
if [ -f "CHANGELOG.md" ]; then
    print_info "Updating CHANGELOG.md..."
    # Get today's date
    TODAY=$(date +%Y-%m-%d)
    # Replace [Unreleased] with the new version
    sed -i.bak "s/## \[Unreleased\]/## [Unreleased]\n\n## [$NEW_VERSION] - $TODAY/" CHANGELOG.md && rm CHANGELOG.md.bak
    
    # Update comparison links at the bottom of CHANGELOG
    # Get GitHub repo info
    REPO_URL=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's/git@github.com:/https:\/\/github.com\//')
    
    # First, update the Unreleased comparison
    sed -i.bak "s|\[Unreleased\]: .*/compare/.*\.\.\.HEAD|\[Unreleased\]: $REPO_URL/compare/v$NEW_VERSION...HEAD|" CHANGELOG.md && rm CHANGELOG.md.bak
    
    # Add new version comparison link (insert after [Unreleased] line)
    PREV_VERSION=$CURRENT_VERSION
    sed -i.bak "/\[Unreleased\]:/a\\
[$NEW_VERSION]: $REPO_URL/compare/v$PREV_VERSION...v$NEW_VERSION" CHANGELOG.md && rm CHANGELOG.md.bak
fi

# Step 2: Commit version updates
print_info "Committing version updates..."
git add "$MAIN_FILE" package.json
[ -f "includes/plugin.php" ] && git add includes/plugin.php
[ -f "CHANGELOG.md" ] && git add CHANGELOG.md
git commit -m "Prepare release v$NEW_VERSION"

# Step 3: Push to main
print_info "Pushing to main branch..."
git push origin main

# Step 4: Wait for build branch to be updated by GitHub Actions
print_info "Waiting for GitHub Actions to update the build branch..."
print_info "This usually takes 2-3 minutes. Checking build workflow status..."

# Get the latest commit SHA
COMMIT_SHA=$(git rev-parse HEAD)

# Wait for the build workflow to complete
MAX_WAIT=300  # 5 minutes
WAIT_TIME=0
INTERVAL=10

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Check if build branch has been updated with our commit
    # Fetch without creating local branch to avoid conflicts
    git fetch origin >/dev/null 2>&1 || true
    
    # Check if the build branch contains our commit
    if git branch -r --contains $COMMIT_SHA | grep -q "origin/build"; then
        print_info "Build branch has been updated successfully!"
        break
    fi
    
    echo -ne "\rWaiting for build branch update... ${WAIT_TIME}s / ${MAX_WAIT}s"
    sleep $INTERVAL
    WAIT_TIME=$((WAIT_TIME + INTERVAL))
done

echo ""  # New line after the waiting message

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    print_error "Timeout waiting for build branch update. Please check GitHub Actions."
    print_warning "You may need to manually create the tag from the build branch once it's updated."
    exit 1
fi

# Step 5: Create tag from build branch
print_info "Creating tag v$NEW_VERSION from build branch..."

# Fetch the latest build branch (use --force to handle force-pushed branch)
git fetch origin build --force

# Create the tag from the build branch (use origin/build to avoid local branch issues)
git tag -a "v$NEW_VERSION" origin/build -m "Release v$NEW_VERSION"

# Push the tag
print_info "Pushing tag to GitHub..."
git push origin "v$NEW_VERSION"

# Step 6: Success message
echo ""
print_info "🎉 Release v$NEW_VERSION created successfully!"
print_info ""
print_info "The GitHub Actions workflow will now:"
print_info "  1. Run tests"
print_info "  2. Create a GitHub release with changelog"
print_info "  3. Attach the plugin ZIP file"
print_info ""
print_info "Monitor the release progress at:"
print_info "https://github.com/$(git config --get remote.origin.url | sed 's/.*://;s/\.git$//')/actions"
print_info ""
print_info "Once completed, the release will be available at:"
print_info "https://github.com/$(git config --get remote.origin.url | sed 's/.*://;s/\.git$//')/releases/tag/v$NEW_VERSION"