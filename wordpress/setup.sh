#!/bin/bash

# WordPress Development Environment Setup
# This script sets up a complete WordPress development environment

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SHARED_DIR="$SCRIPT_DIR/../shared"

# Function to get project information
get_project_info() {
    # Try to get project name from main PHP file
    local main_file=$(find . -maxdepth 1 -name "*.php" -exec grep -l "Plugin Name:\|Theme Name:" {} \; | head -1)
    
    if [ -n "$main_file" ]; then
        PROJECT_NAME=$(grep -E "Plugin Name:|Theme Name:" "$main_file" | head -1 | sed 's/.*: //' | sed 's/\*//' | xargs)
        MAIN_FILE=$(basename "$main_file")
        
        # Determine if it's a plugin or theme
        if grep -q "Plugin Name:" "$main_file"; then
            PROJECT_SUBTYPE="plugin"
        else
            PROJECT_SUBTYPE="theme"
        fi
    else
        # Fallback to directory name
        PROJECT_NAME=$(basename "$(pwd)")
        MAIN_FILE="${PROJECT_NAME}.php"
        PROJECT_SUBTYPE="plugin"
    fi
    
    # Get plugin slug from directory name
    PLUGIN_SLUG=$(basename "$(pwd)")
    
    # Get GitHub info from git remote
    if git remote get-url origin 2>/dev/null | grep -q github.com; then
        GITHUB_URL=$(git remote get-url origin | sed 's/\.git$//')
        GITHUB_ORG=$(echo "$GITHUB_URL" | sed 's/.*github.com[:/]//' | cut -d'/' -f1)
        GITHUB_REPO=$(echo "$GITHUB_URL" | sed 's/.*github.com[:/]//' | cut -d'/' -f2)
    else
        GITHUB_ORG="[YOUR_GITHUB_ORG]"
        GITHUB_REPO="[YOUR_GITHUB_REPO]"
    fi
}

# Start setup
print_header "WordPress Development Environment Setup"

# Check if we're in a WordPress project
php_files=$(ls *.php 2>/dev/null | wc -l)
if [ "$php_files" -eq 0 ] && [ ! -f "style.css" ]; then
    print_warning "This doesn't appear to be a WordPress plugin or theme directory."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get project information
get_project_info

print_info "Detected project: $PROJECT_NAME ($PROJECT_SUBTYPE)"
print_info "Main file: $MAIN_FILE"
print_info "Plugin slug: $PLUGIN_SLUG"

# Step 1: Setup Linting
print_header "Setting up Linting"

# Copy linting files
cp "$SCRIPT_DIR/linting/.eslintrc.cjs" .
cp "$SCRIPT_DIR/linting/.prettierrc" .
cp "$SCRIPT_DIR/linting/.stylelintrc.json" .
cp "$SCRIPT_DIR/linting/phpcs.xml" .

# Copy VS Code settings
mkdir -p .vscode
cp "$SCRIPT_DIR/vscode/settings.json" .vscode/

print_info "✓ Linting configuration files copied"

# Step 2: Setup Husky
print_header "Setting up Husky Pre-commit Hooks"

# Run shared Husky setup
bash "$SHARED_DIR/husky/setup.sh"

# Step 3: Setup GitHub Workflows
print_header "Setting up GitHub Workflows"

mkdir -p .github/workflows

# Copy and customize workflows
for workflow in "$SCRIPT_DIR/github"/*.yml; do
    filename=$(basename "$workflow")
    target=".github/workflows/$filename"
    
    # Copy and replace placeholders
    sed -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
        -e "s/\[MAIN_FILE\]/$MAIN_FILE/g" \
        -e "s/\[MAIN_JS_FILE\]/$(ls build/*.js 2>/dev/null | head -1 | xargs basename || echo 'index.js')/g" \
        "$workflow" > "$target"
done

print_info "✓ GitHub workflows created"

# Step 4: Setup WordPress Playground
print_header "Setting up WordPress Playground"

if [ ! -d "_playground" ]; then
    mkdir -p _playground
    
    # Copy and customize playground configs
    sed -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
        -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
        -e "s/\[MAIN_FILE\]/$MAIN_FILE/g" \
        -e "s/\[GITHUB_ORG\]/$GITHUB_ORG/g" \
        -e "s/\[GITHUB_REPO\]/$GITHUB_REPO/g" \
        "$SCRIPT_DIR/playground/blueprint.json" > "_playground/blueprint.json"
    
    sed -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
        -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
        -e "s/\[MAIN_FILE\]/$MAIN_FILE/g" \
        "$SCRIPT_DIR/playground/blueprint-local.json" > "_playground/blueprint-local.json"
    
    print_info "✓ WordPress Playground configurations created"
else
    print_warning "⚠ _playground directory already exists, skipping"
fi

# Step 5: Setup Release Scripts
print_header "Setting up Release Automation"

if [ ! -d "bin" ]; then
    mkdir -p bin
    cp "$SCRIPT_DIR/release/release.sh" bin/
    chmod +x bin/release.sh
    print_info "✓ Release script created in bin/release.sh"
else
    print_warning "⚠ bin directory already exists, skipping release script"
fi

# Step 6: Update package.json and composer.json
print_header "Updating Configuration Files"

# Update package.json
if [ -f "package.json" ] && command -v jq &> /dev/null; then
    read -p "Would you like to automatically add scripts to package.json? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup package.json
        cp package.json package.json.bak
        
        # Read scripts from scripts.json
        scripts=$(jq -r '.scripts' "$SCRIPT_DIR/package-scripts/scripts.json")
        lint_staged=$(jq -r '."lint-staged"' "$SCRIPT_DIR/package-scripts/scripts.json")
        
        # Update package.json
        jq ".scripts = .scripts + $scripts" package.json | \
        jq ".\"lint-staged\" = $lint_staged" > package.json.tmp && \
        mv package.json.tmp package.json
        
        print_info "✓ package.json updated with scripts"
    fi
fi

# Update composer.json
if [ -f "composer.json" ] && command -v jq &> /dev/null; then
    read -p "Would you like to automatically add scripts to composer.json? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup composer.json
        cp composer.json composer.json.bak
        
        # Read scripts from composer-scripts.json
        scripts=$(jq -r '.scripts' "$SCRIPT_DIR/package-scripts/composer-scripts.json")
        
        # Update composer.json
        jq ".scripts = .scripts + $scripts" composer.json > composer.json.tmp && \
        mv composer.json.tmp composer.json
        
        print_info "✓ composer.json updated with scripts"
    fi
fi

# Step 7: Create CLAUDE.md
print_header "Creating CLAUDE.md"

# Determine which sections to include based on project type
if [ -f "CLAUDE.md" ]; then
    read -p "CLAUDE.md already exists. Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Keeping existing CLAUDE.md"
    else
        # Create CLAUDE.md from template
        cp "$SCRIPT_DIR/claude/template.md" CLAUDE.md.tmp
        
        # Replace placeholders
        sed -i.bak -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
            -e "s/\[PROJECT_SUBTYPE\]/$PROJECT_SUBTYPE/g" \
            -e "s/\[MAIN_FILE\]/$MAIN_FILE/g" \
            -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
            -e "s/\[WP_VERSION\]/6.0/g" \
            -e "s/\[PHP_VERSION\]/8.2/g" CLAUDE.md.tmp && rm CLAUDE.md.tmp.bak
        
        # Read and insert sections
        wordpress_standards=$(cat "$SCRIPT_DIR/claude/sections/wordpress-standards.md")
        wordpress_security=$(cat "$SCRIPT_DIR/claude/sections/wordpress-security.md")
        general_standards=$(cat "$SHARED_DIR/claude/sections/coding-standards.md")
        general_security=$(cat "$SHARED_DIR/claude/sections/security-practices.md")
        
        # Use awk for multi-line replacements
        awk -v ws="$wordpress_standards" '{ gsub(/\[WORDPRESS_STANDARDS\]/, ws); print }' CLAUDE.md.tmp > CLAUDE.md.tmp2
        mv CLAUDE.md.tmp2 CLAUDE.md.tmp
        
        awk -v ws="$wordpress_security" '{ gsub(/\[WORDPRESS_SECURITY\]/, ws); print }' CLAUDE.md.tmp > CLAUDE.md.tmp2
        mv CLAUDE.md.tmp2 CLAUDE.md.tmp
        
        awk -v gs="$general_standards" '{ gsub(/\[GENERAL_STANDARDS\]/, gs); print }' CLAUDE.md.tmp > CLAUDE.md.tmp2
        mv CLAUDE.md.tmp2 CLAUDE.md.tmp
        
        awk -v gs="$general_security" '{ gsub(/\[GENERAL_SECURITY\]/, gs); print }' CLAUDE.md.tmp > CLAUDE.md.tmp2
        mv CLAUDE.md.tmp2 CLAUDE.md.tmp
        
        # Add project description placeholder
        echo "" >> CLAUDE.md.tmp
        echo "Please update the following in CLAUDE.md:" >> CLAUDE.md.tmp
        echo "- [PROJECT_DESCRIPTION] - Brief description of what your $PROJECT_SUBTYPE does" >> CLAUDE.md.tmp
        echo "- [RELEASE_PROCESS] - Your specific release process" >> CLAUDE.md.tmp
        echo "- [CUSTOM_SECTIONS] - Any project-specific sections" >> CLAUDE.md.tmp
        
        mv CLAUDE.md.tmp CLAUDE.md
        print_info "✓ CLAUDE.md created"
    fi
else
    # Create new CLAUDE.md
    cp "$SCRIPT_DIR/claude/template.md" CLAUDE.md
    
    # Replace placeholders (same as above)
    sed -i.bak -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
        -e "s/\[PROJECT_SUBTYPE\]/$PROJECT_SUBTYPE/g" \
        -e "s/\[MAIN_FILE\]/$MAIN_FILE/g" \
        -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
        -e "s/\[WP_VERSION\]/6.0/g" \
        -e "s/\[PHP_VERSION\]/8.2/g" CLAUDE.md && rm CLAUDE.md.bak
    
    # Read sections
    wordpress_standards=$(cat "$SCRIPT_DIR/claude/sections/wordpress-standards.md")
    wordpress_security=$(cat "$SCRIPT_DIR/claude/sections/wordpress-security.md")
    general_standards=$(cat "$SHARED_DIR/claude/sections/coding-standards.md")
    general_security=$(cat "$SHARED_DIR/claude/sections/security-practices.md")
    
    # Create temporary file for processing
    cp CLAUDE.md CLAUDE.md.tmp
    
    # Replace sections using temporary files
    awk -v content="$wordpress_standards" '
        /\[WORDPRESS_STANDARDS\]/ {
            print content
            next
        }
        { print }
    ' CLAUDE.md.tmp > CLAUDE.md.tmp2 && mv CLAUDE.md.tmp2 CLAUDE.md.tmp
    
    awk -v content="$wordpress_security" '
        /\[WORDPRESS_SECURITY\]/ {
            print content
            next
        }
        { print }
    ' CLAUDE.md.tmp > CLAUDE.md.tmp2 && mv CLAUDE.md.tmp2 CLAUDE.md.tmp
    
    awk -v content="$general_standards" '
        /\[GENERAL_STANDARDS\]/ {
            print content
            next
        }
        { print }
    ' CLAUDE.md.tmp > CLAUDE.md.tmp2 && mv CLAUDE.md.tmp2 CLAUDE.md.tmp
    
    awk -v content="$general_security" '
        /\[GENERAL_SECURITY\]/ {
            print content
            next
        }
        { print }
    ' CLAUDE.md.tmp > CLAUDE.md.tmp2 && mv CLAUDE.md.tmp2 CLAUDE.md.tmp
    
    # Clean up remaining placeholders with defaults
    sed -i.bak -e "s/\[PROJECT_DESCRIPTION\]/[Add your project description here]/g" \
        -e "s/\[RELEASE_PROCESS\]/See bin\/release.sh for automated release process/g" \
        -e "s/\[CUSTOM_SECTIONS\]//g" CLAUDE.md.tmp && rm CLAUDE.md.tmp.bak
    
    mv CLAUDE.md.tmp CLAUDE.md
    print_info "✓ CLAUDE.md created"
fi

# Step 8: Install dependencies
print_header "Installing Dependencies"

if [ -f "package.json" ]; then
    read -p "Install npm dependencies? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npm install
        print_info "✓ npm dependencies installed"
    fi
fi

if [ -f "composer.json" ]; then
    read -p "Install composer dependencies? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        composer install
        print_info "✓ Composer dependencies installed"
    fi
fi

# Step 9: Cleanup
print_header "Cleanup"

read -p "Remove pikari-dev-setup folder? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ..
    rm -rf pikari-dev-setup
    print_info "✓ Setup folder removed"
fi

# Final summary
print_header "Setup Complete! 🎉"

echo "Your WordPress development environment is now configured with:"
echo ""
echo "📝 Linting:"
echo "   - ESLint for JavaScript (WordPress standards)"
echo "   - Stylelint for CSS/SCSS"
echo "   - PHPCS for PHP (WordPress standards)"
echo "   - Prettier for consistent formatting"
echo ""
echo "🪝 Pre-commit Hooks:"
echo "   - Husky + lint-staged for automatic linting"
echo ""
echo "🔄 GitHub Workflows:"
echo "   - CI workflow for testing and linting"
echo "   - Build branch automation"
echo "   - Release automation"
echo ""
echo "🎮 WordPress Playground:"
echo "   - Local development blueprint"
echo "   - Demo blueprint for GitHub"
echo ""
echo "📦 Release Automation:"
echo "   - bin/release.sh for automated releases"
echo ""
echo "🤖 AI Assistant Context:"
echo "   - CLAUDE.md with project guidelines"
echo ""
echo "Next steps:"
echo "1. Review and customize CLAUDE.md"
echo "2. Run 'npm run lint:fix' to fix any existing issues"
echo "3. Commit the new configuration files"
echo "4. Push to GitHub to activate workflows"
echo ""
echo "For local development with WordPress Playground:"
echo "   npm run playground"
echo ""
echo "To create a release:"
echo "   ./bin/release.sh"