#!/bin/bash

# Husky Setup Script
# This script sets up Husky and lint-staged for any project type

set -e

# Get project type from argument
PROJECT_TYPE=${1:-generic}

echo "🐶 Setting up Husky pre-commit hooks..."

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "Error: No package.json found. Please run from project root."
    exit 1
fi

# Check if git repo
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
fi

# Install husky if not already in devDependencies
if ! grep -q "\"husky\":" package.json; then
    echo "Installing Husky..."
    npm install --save-dev husky
fi

# Install lint-staged if not already in devDependencies
if ! grep -q "\"lint-staged\":" package.json; then
    echo "Installing lint-staged..."
    npm install --save-dev lint-staged
fi

# Initialize husky
echo "Initializing Husky..."
npx husky init

# Copy pre-commit hook
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp "$SCRIPT_DIR/pre-commit" .husky/pre-commit
chmod +x .husky/pre-commit

# Add lint-staged config based on project type
echo "Configuring lint-staged for $PROJECT_TYPE project..."

case $PROJECT_TYPE in
    wordpress)
        # Add WordPress-specific lint-staged config
        if command -v jq &> /dev/null; then
            jq '."lint-staged" = {
                "*.php": ["composer run lint"],
                "*.js": ["wp-scripts lint-js", "prettier --write"],
                "*.{scss,css}": ["wp-scripts lint-style", "prettier --write"],
                "*.{json,md}": ["prettier --write"]
            }' package.json > package.json.tmp && mv package.json.tmp package.json
            echo "✅ Added WordPress lint-staged configuration"
        else
            echo "⚠️  jq not found. Please add this to your package.json:"
            echo '"lint-staged": {'
            echo '  "*.php": ["composer run lint"],'
            echo '  "*.js": ["wp-scripts lint-js", "prettier --write"],'
            echo '  "*.{scss,css}": ["wp-scripts lint-style", "prettier --write"],'
            echo '  "*.{json,md}": ["prettier --write"]'
            echo '}'
        fi
        ;;
    react)
        # React configuration (for future use)
        echo "React lint-staged config will be added in future version"
        ;;
    *)
        # Generic configuration
        if command -v jq &> /dev/null; then
            jq '."lint-staged" = {
                "*.js": ["eslint", "prettier --write"],
                "*.{json,md}": ["prettier --write"]
            }' package.json > package.json.tmp && mv package.json.tmp package.json
            echo "✅ Added generic lint-staged configuration"
        fi
        ;;
esac

echo ""
echo "✅ Husky setup complete!"
echo ""
echo "Pre-commit hooks will now run automatically before each commit."
echo "To skip hooks temporarily, use: git commit --no-verify"