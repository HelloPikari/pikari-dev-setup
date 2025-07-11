#!/bin/bash

# WordPress Development Environment Setup
# This script sets up a complete WordPress development environment

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SHARED_DIR="$SCRIPT_DIR/../shared"

# Source shared functions
source "$SHARED_DIR/functions.sh"

# Function to get WordPress-specific project information
get_wordpress_info() {
    # Use environment variables if available from main setup
    if [ -n "$PIKARI_PROJECT_NAME" ]; then
        PROJECT_NAME="$PIKARI_PROJECT_NAME"
    else
        # Fallback to auto-detection
        local main_file=$(find . -maxdepth 1 -name "*.php" -exec grep -l "Plugin Name:\|Theme Name:" {} \; | head -1)
        if [ -n "$main_file" ]; then
            PROJECT_NAME=$(grep -E "Plugin Name:|Theme Name:" "$main_file" | head -1 | sed 's/.*: //' | sed 's/\*//' | xargs)
        else
            PROJECT_NAME=$(basename "$(pwd)")
        fi
    fi
    
    # Auto-detect main file and subtype
    local main_file=$(find . -maxdepth 1 -name "*.php" -exec grep -l "Plugin Name:\|Theme Name:" {} \; | head -1)
    if [ -n "$main_file" ]; then
        MAIN_FILE=$(basename "$main_file")
        # Determine if it's a plugin or theme
        if grep -q "Plugin Name:" "$main_file"; then
            PROJECT_SUBTYPE="plugin"
        else
            PROJECT_SUBTYPE="theme"
        fi
    else
        MAIN_FILE="${PROJECT_NAME}.php"
        PROJECT_SUBTYPE="plugin"
    fi
    
    # Get plugin slug from directory name
    PLUGIN_SLUG=$(basename "$(pwd)")
    
    # Use GitHub info from environment or fallback
    GITHUB_ORG="${PIKARI_GITHUB_ORG:-[YOUR_GITHUB_ORG]}"
    GITHUB_REPO="${PIKARI_GITHUB_REPO:-[YOUR_GITHUB_REPO]}"
    
    # Use other environment variables
    PROJECT_DESCRIPTION="${PIKARI_PROJECT_DESCRIPTION:-WordPress $PROJECT_SUBTYPE}"
    AUTHOR_NAME="${PIKARI_AUTHOR_NAME:-Your Name}"
    AUTHOR_EMAIL="${PIKARI_AUTHOR_EMAIL:-your@email.com}"
    PROJECT_HOMEPAGE="${PIKARI_PROJECT_HOMEPAGE:-}"
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

# Get WordPress-specific project information
get_wordpress_info

print_info "Detected project: $PROJECT_NAME ($PROJECT_SUBTYPE)"
print_info "Main file: $MAIN_FILE"
print_info "Plugin slug: $PLUGIN_SLUG"

# Step 1: Setup Linting
print_header "Setting up Linting"

# Copy linting files
cp "$SCRIPT_DIR/linting/.eslintrc.cjs" .
cp "$SCRIPT_DIR/linting/.prettierrc" .
cp "$SHARED_DIR/linting/.stylelintrc.json" .
cp "$SCRIPT_DIR/linting/phpcs.xml" .

# Copy VS Code settings
mkdir -p .vscode
cp "$SCRIPT_DIR/vscode/settings.json" .vscode/

print_info "✓ Linting configuration files copied"

# Step 2: Ensure package.json exists
print_header "Setting up package.json"

if [ ! -f "package.json" ]; then
    print_info "Creating package.json from template..."
    
    sed -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
        -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
        -e "s/\[PROJECT_DESCRIPTION\]/$PROJECT_DESCRIPTION/g" \
        -e "s/\[PROJECT_SUBTYPE\]/$PROJECT_SUBTYPE/g" \
        -e "s/\[AUTHOR_NAME\]/$AUTHOR_NAME/g" \
        -e "s/\[AUTHOR_EMAIL\]/$AUTHOR_EMAIL/g" \
        -e "s/\[PROJECT_HOMEPAGE\]/$PROJECT_HOMEPAGE/g" \
        "$SCRIPT_DIR/package-scripts/package.json" > package.json
    
    print_info "✓ package.json created"
    PACKAGE_JSON_CREATED=true
else
    print_info "package.json already exists"
    PACKAGE_JSON_CREATED=false
fi

# Step 3: Setup Husky
print_header "Setting up Husky Pre-commit Hooks"

# Run shared Husky setup
bash "$SHARED_DIR/husky/setup.sh" wordpress

# Step 4: Setup GitHub Workflows
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

# Step 5: Setup WordPress Playground
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

# Step 6: Setup Release Scripts
print_header "Setting up Release Automation"

if [ ! -d "bin" ]; then
    mkdir -p bin
    cp "$SCRIPT_DIR/release/release.sh" bin/
    chmod +x bin/release.sh
    print_info "✓ Release script created in bin/release.sh"
else
    print_warning "⚠ bin directory already exists, skipping release script"
fi

# Step 7: Update package.json and composer.json
print_header "Updating Configuration Files"

# Update existing package.json if needed
if [ "$PACKAGE_JSON_CREATED" = "false" ] && command -v jq &> /dev/null; then
    read -p "Would you like to update the existing package.json with WordPress scripts? (y/N) " -n 1 -r
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

# Handle composer.json
if [ ! -f "composer.json" ]; then
    read -p "No composer.json found. Would you like to create one for PHP linting? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Create composer.json from template
        # Generate author slug from author name (lowercase, replace spaces with hyphens)
        AUTHOR_SLUG=$(echo "$AUTHOR_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        
        sed -e "s/\[AUTHOR_SLUG\]/$AUTHOR_SLUG/g" \
            -e "s/\[PLUGIN_SLUG\]/$PLUGIN_SLUG/g" \
            -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
            -e "s/\[PROJECT_DESCRIPTION\]/$PROJECT_DESCRIPTION/g" \
            -e "s/\[AUTHOR_NAME\]/$AUTHOR_NAME/g" \
            -e "s/\[AUTHOR_EMAIL\]/$AUTHOR_EMAIL/g" \
            -e "s/\[PROJECT_HOMEPAGE\]/$PROJECT_HOMEPAGE/g" \
            "$SCRIPT_DIR/package-scripts/composer.json" > composer.json
        
        # Set type based on project subtype
        if [ "$PROJECT_SUBTYPE" = "theme" ]; then
            sed -i.bak 's/"type": "wordpress-plugin"/"type": "wordpress-theme"/' composer.json && rm composer.json.bak
        fi
        
        print_info "✓ composer.json created"
    fi
elif command -v jq &> /dev/null; then
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

# Step 8: Create CLAUDE.md
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
            -e "s/\[PROJECT_DESCRIPTION\]/$PROJECT_DESCRIPTION/g" \
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
        
        mv CLAUDE.md.tmp CLAUDE.md
        print_info "✓ CLAUDE.md created"
    fi
else
    # Create new CLAUDE.md
    cp "$SCRIPT_DIR/claude/template.md" CLAUDE.md
    
    # Replace placeholders (same as above)
    sed -i.bak -e "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" \
        -e "s/\[PROJECT_DESCRIPTION\]/$PROJECT_DESCRIPTION/g" \
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
    sed -i.bak -e "s/\[RELEASE_PROCESS\]/See bin\/release.sh for automated release process/g" \
        -e "s/\[CUSTOM_SECTIONS\]//g" CLAUDE.md.tmp && rm CLAUDE.md.tmp.bak
    
    mv CLAUDE.md.tmp CLAUDE.md
    print_info "✓ CLAUDE.md created"
fi

# Step 9: Install dependencies
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

# Step 10: Cleanup
print_header "Cleanup"

# Get the actual setup folder name (handles downloaded zips with different names)
SETUP_FOLDER=$(dirname "$SCRIPT_DIR")
SETUP_FOLDER_NAME=$(basename "$SETUP_FOLDER")

read -p "Remove the setup folder '$SETUP_FOLDER_NAME'? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Change to parent directory first
    cd "$SETUP_FOLDER/.."
    rm -rf "$SETUP_FOLDER"
    print_info "✓ Setup folder '$SETUP_FOLDER_NAME' removed"
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