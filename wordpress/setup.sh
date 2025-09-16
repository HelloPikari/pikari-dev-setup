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
    
    # Get plugin slug from directory name and sanitize it
    # Ensure it's lowercase, alphanumeric with hyphens only
    PLUGIN_SLUG=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's|[^a-z0-9-]||g' | sed 's|-\+|-|g' | sed 's|^-||' | sed 's|-$||')
    
    # Use GitHub info from environment or fallback
    GITHUB_ORG="${PIKARI_GITHUB_ORG:-[YOUR_GITHUB_ORG]}"
    GITHUB_REPO="${PIKARI_GITHUB_REPO:-[YOUR_GITHUB_REPO]}"
    
    # Use other environment variables
    PROJECT_DESCRIPTION="${PIKARI_PROJECT_DESCRIPTION:-WordPress $PROJECT_SUBTYPE}"
    AUTHOR_NAME="${PIKARI_AUTHOR_NAME:-Your Name}"
    AUTHOR_EMAIL="${PIKARI_AUTHOR_EMAIL:-your@email.com}"
    PROJECT_HOMEPAGE="${PIKARI_PROJECT_HOMEPAGE:-}"
    VERSION="${PIKARI_VERSION:-1.0.0}"
    
    # Generate author slug from author name (lowercase, alphanumeric with hyphens only)
    # Trim spaces, remove non-alphanumeric except spaces, collapse spaces, convert to hyphens
    AUTHOR_SLUG=$(echo "$AUTHOR_NAME" | sed 's|^ *||;s| *$||' | tr '[:upper:]' '[:lower:]' | sed 's|[^a-z0-9 ]||g' | sed 's|  *| |g' | sed 's| |-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
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

# Step 1: Create main plugin file if it doesn't exist
if [ "$PROJECT_SUBTYPE" = "plugin" ] && [ ! -f "$MAIN_FILE" ]; then
    print_header "Creating Plugin Entry Point"
    
    # Generate plugin constant name (uppercase, underscores)
    PLUGIN_CONSTANT=$(echo "$PLUGIN_SLUG" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    # Generate function prefix (lowercase, underscores)
    PLUGIN_FUNCTION_PREFIX=$(echo "$PLUGIN_SLUG" | tr '-' '_')
    
    # Create plugin file from template
    sed -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PROJECT_HOMEPAGE\]|$PROJECT_HOMEPAGE|g" \
        -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
        -e "s|\[VERSION\]|$VERSION|g" \
        -e "s|\[AUTHOR_NAME\]|$AUTHOR_NAME|g" \
        -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
        -e "s|\[PLUGIN_CONSTANT\]|$PLUGIN_CONSTANT|g" \
        -e "s|\[PLUGIN_FUNCTION_PREFIX\]|$PLUGIN_FUNCTION_PREFIX|g" \
        "$SCRIPT_DIR/templates/plugin-main.php" > "$MAIN_FILE"
    
    # Remove empty Plugin URI and Author URI if no homepage
    if [ -z "$PROJECT_HOMEPAGE" ]; then
        sed -i.bak -e '/Plugin URI:  $/d' -e '/Author URI:  $/d' "$MAIN_FILE" && rm "${MAIN_FILE}.bak"
    fi
    
    print_info "✓ Created $MAIN_FILE"
    
    # Create basic plugin directory structure
    mkdir -p assets/css assets/js includes languages src build
    print_info "✓ Created plugin directory structure"
fi

# Step 2: Setup .gitignore
print_header "Setting up .gitignore"

if [ ! -f ".gitignore" ]; then
    cp "$SHARED_DIR/templates/.gitignore" .
    print_info "✓ Created .gitignore with common exclusions"
else
    # Append pikari-dev-setup exclusions if not already present
    if ! grep -q "pikari-dev-setup" .gitignore; then
        echo "" >> .gitignore
        echo "# Pikari Dev Setup" >> .gitignore
        echo "pikari-dev-setup/" >> .gitignore
        echo "pikari-dev-setup-*/" >> .gitignore
        print_info "✓ Added pikari-dev-setup to existing .gitignore"
    else
        print_info "✓ .gitignore already exists with pikari-dev-setup exclusions"
    fi
fi

# Step 3: Create README and CHANGELOG
print_header "Creating Documentation Files"

# Create README.md if it doesn't exist
if [ ! -f "README.md" ]; then
    # Get current date
    CURRENT_DATE=$(date +%Y-%m-%d)
    
    sed -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
        -e "s|\[AUTHOR_NAME\]|$AUTHOR_NAME|g" \
        -e "s|\[AUTHOR_EMAIL\]|$AUTHOR_EMAIL|g" \
        -e "s|\[PROJECT_HOMEPAGE\]|$PROJECT_HOMEPAGE|g" \
        "$SHARED_DIR/templates/README.md" > README.md
    
    # Remove empty homepage line if no homepage
    if [ -z "$PROJECT_HOMEPAGE" ]; then
        sed -i.bak '/- Homepage: $/d' README.md && rm README.md.bak
    fi
    
    print_info "✓ Created README.md"
else
    print_info "✓ README.md already exists"
fi

# Create CHANGELOG.md if it doesn't exist
if [ ! -f "CHANGELOG.md" ]; then
    sed -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[VERSION\]|$VERSION|g" \
        -e "s|\[DATE\]|$CURRENT_DATE|g" \
        -e "s|\[GITHUB_ORG\]|$GITHUB_ORG|g" \
        -e "s|\[GITHUB_REPO\]|$GITHUB_REPO|g" \
        "$SHARED_DIR/templates/CHANGELOG.md" > CHANGELOG.md
    
    # Remove GitHub links if no GitHub info
    if [ -z "$GITHUB_ORG" ] || [ -z "$GITHUB_REPO" ]; then
        sed -i.bak '/\[Unreleased\]:/d' CHANGELOG.md
        sed -i.bak '/\[\[VERSION\]\]:/d' CHANGELOG.md
        rm CHANGELOG.md.bak
    fi
    
    print_info "✓ Created CHANGELOG.md"
else
    print_info "✓ CHANGELOG.md already exists"
fi

# Create LICENSE file
if [ ! -f "LICENSE" ]; then
    cp "$SHARED_DIR/templates/LICENSE" LICENSE
    print_info "✓ Created LICENSE"
else
    print_info "✓ LICENSE already exists"
fi

# Create readme.txt (WordPress plugin/theme readme)
if [ ! -f "readme.txt" ]; then
    sed -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
        -e "s|\[AUTHOR_NAME\]|$AUTHOR_NAME|g" \
        -e "s|\[AUTHOR_EMAIL\]|$AUTHOR_EMAIL|g" \
        -e "s|\[AUTHOR_URI\]|$PROJECT_HOMEPAGE|g" \
        -e "s|\[AUTHOR_SLUG\]|$AUTHOR_SLUG|g" \
        -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
        -e "s|\[VERSION\]|$VERSION|g" \
        -e "s|\[GITHUB_ORG\]|$GITHUB_ORG|g" \
        -e "s|\[GITHUB_REPO\]|$GITHUB_REPO|g" \
        -e "s|\[PROJECT_HOMEPAGE\]|$PROJECT_HOMEPAGE|g" \
        "$SCRIPT_DIR/readme.txt" > readme.txt

    # Remove empty author URI line if no homepage
    if [ -z "$PROJECT_HOMEPAGE" ]; then
        sed -i.bak '/- Website: $/d' readme.txt && rm readme.txt.bak
    fi

    print_info "✓ Created readme.txt"
else
    print_info "✓ readme.txt already exists"
fi

# Create docs directory and copy release documentation
if [ ! -d "docs" ]; then
    mkdir -p docs
fi

if [ ! -f "docs/releases.md" ]; then
    sed -e "s|pikari-gutenberg-accordion|$PLUGIN_SLUG|g" \
        "$SCRIPT_DIR/docs/releases.md" > docs/releases.md
    print_info "✓ Created docs/releases.md"
else
    print_info "✓ docs/releases.md already exists"
fi

# Step 4: Setup Linting
print_header "Setting up Linting"

# Copy linting files
cp "$SCRIPT_DIR/linting/.eslintrc.cjs" .
cp "$SCRIPT_DIR/linting/.prettierrc" .
cp "$SCRIPT_DIR/linting/.prettierignore" .
cp "$SHARED_DIR/linting/.stylelintrc.json" .
cp "$SCRIPT_DIR/linting/phpcs.xml" .

# Copy VS Code settings
mkdir -p .vscode
cp "$SCRIPT_DIR/vscode/settings.json" .vscode/
cp "$SCRIPT_DIR/vscode/extensions.json" .vscode/

print_info "✓ Linting configuration files copied"

# Step 5: Ensure package.json exists
print_header "Setting up package.json"

if [ ! -f "package.json" ]; then
    print_info "Creating package.json from template..."
    
    sed -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
        -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
        -e "s|\[PROJECT_SUBTYPE\]|$PROJECT_SUBTYPE|g" \
        -e "s|\[AUTHOR_NAME\]|$AUTHOR_NAME|g" \
        -e "s|\[AUTHOR_EMAIL\]|$AUTHOR_EMAIL|g" \
        -e "s|\[PROJECT_HOMEPAGE\]|$PROJECT_HOMEPAGE|g" \
        -e "s|\[VERSION\]|$VERSION|g" \
        "$SCRIPT_DIR/package-scripts/package.json" > package.json
    
    # Remove homepage field if empty
    if [ -z "$PROJECT_HOMEPAGE" ]; then
        if command -v jq &> /dev/null; then
            jq 'del(.homepage)' package.json > package.json.tmp && mv package.json.tmp package.json
        else
            # Fallback: remove the line with sed
            sed -i.bak '/"homepage": "",/d' package.json && rm package.json.bak
        fi
    fi
    
    print_info "✓ package.json created"
    PACKAGE_JSON_CREATED=true
else
    print_info "package.json already exists"
    PACKAGE_JSON_CREATED=false
fi

# Step 5: Setup Husky
print_header "Setting up Husky Pre-commit Hooks"

# Run shared Husky setup
bash "$SHARED_DIR/husky/setup.sh" wordpress

# Step 6: Setup GitHub Workflows
print_header "Setting up GitHub Workflows"

mkdir -p .github/workflows

# Copy GitHub config files to .github/
for config in "$SCRIPT_DIR/github"/*.yml; do
    if [ -f "$config" ]; then
        filename=$(basename "$config")
        target=".github/$filename"
        
        # Copy and replace placeholders
        sed -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
            -e "s|\[AUTHOR_SLUG\]|$AUTHOR_SLUG|g" \
            -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
            -e "s|\[MAIN_FILE\]|$MAIN_FILE|g" \
            "$config" > "$target"
    fi
done

# Copy workflow files to .github/workflows/
for workflow in "$SCRIPT_DIR/github/workflows"/*.yml; do
    if [ -f "$workflow" ]; then
        filename=$(basename "$workflow")
        target=".github/workflows/$filename"
        
        # Copy and replace placeholders
        sed -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
            -e "s|\[AUTHOR_SLUG\]|$AUTHOR_SLUG|g" \
            -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
            -e "s|\[MAIN_FILE\]|$MAIN_FILE|g" \
            "$workflow" > "$target"
    fi
done

print_info "✓ GitHub workflows and configuration created"

# Step 7: Setup WordPress Playground
print_header "Setting up WordPress Playground"

if [ ! -d "_playground" ]; then
    mkdir -p _playground
    
    # Copy and customize playground configs
    sed -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
        -e "s|\[MAIN_FILE\]|$MAIN_FILE|g" \
        -e "s|\[GITHUB_ORG\]|$GITHUB_ORG|g" \
        -e "s|\[GITHUB_REPO\]|$GITHUB_REPO|g" \
        "$SCRIPT_DIR/playground/blueprint.json" > "_playground/blueprint.json"
    
    sed -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
        -e "s|\[MAIN_FILE\]|$MAIN_FILE|g" \
        "$SCRIPT_DIR/playground/blueprint-local.json" > "_playground/blueprint-local.json"
    
    print_info "✓ WordPress Playground configurations created"
else
    print_warning "⚠ _playground directory already exists, skipping"
fi

# Step 8: Update package.json and composer.json
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
        # Generate author slug from author name (lowercase, alphanumeric with hyphens only)
        # Trim spaces, remove non-alphanumeric except spaces, collapse spaces, convert to hyphens
        AUTHOR_SLUG=$(echo "$AUTHOR_NAME" | sed 's|^ *||;s| *$||' | tr '[:upper:]' '[:lower:]' | sed 's|[^a-z0-9 ]||g' | sed 's|  *| |g' | sed 's| |-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
        
        sed -e "s|\[AUTHOR_SLUG\]|$AUTHOR_SLUG|g" \
            -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
            -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
            -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
            -e "s|\[AUTHOR_NAME\]|$AUTHOR_NAME|g" \
            -e "s|\[AUTHOR_EMAIL\]|$AUTHOR_EMAIL|g" \
            -e "s|\[PROJECT_HOMEPAGE\]|$PROJECT_HOMEPAGE|g" \
            -e "s|\[VERSION\]|$VERSION|g" \
            "$SCRIPT_DIR/package-scripts/composer.json" > composer.json
        
        # Remove homepage field if empty
        if [ -z "$PROJECT_HOMEPAGE" ]; then
            if command -v jq &> /dev/null; then
                jq 'del(.homepage)' composer.json > composer.json.tmp && mv composer.json.tmp composer.json
            else
                # Fallback: remove the line with sed (less reliable but works without jq)
                sed -i.bak '/"homepage": "",/d' composer.json && rm composer.json.bak
            fi
        fi
        
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

# Step 9: Create CLAUDE.md
print_header "Creating CLAUDE.md"

# Ensure we clean up temp files even if the script fails
trap 'rm -f CLAUDE.md.tmp CLAUDE.md.working CLAUDE.md.working.bak CLAUDE.md.tmp2' EXIT

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
        sed -i.bak -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
            -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
            -e "s|\[PROJECT_SUBTYPE\]|$PROJECT_SUBTYPE|g" \
            -e "s|\[MAIN_FILE\]|$MAIN_FILE|g" \
            -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
            -e "s|\[WP_VERSION\]|6.0|g" \
            -e "s|\[PHP_VERSION\]|8.2|g" CLAUDE.md.tmp && rm CLAUDE.md.tmp.bak
        
        # Use a more robust method to insert sections
        # Create a working copy
        cp CLAUDE.md.tmp CLAUDE.md.working
        
        # Process each placeholder one by one using sed with file input
        if [ -f "$SCRIPT_DIR/claude/sections/wordpress-standards.md" ]; then
            sed -i.bak '/\[WORDPRESS_STANDARDS\]/r '"$SCRIPT_DIR/claude/sections/wordpress-standards.md" CLAUDE.md.working
            sed -i.bak '/\[WORDPRESS_STANDARDS\]/d' CLAUDE.md.working
        fi
        
        if [ -f "$SCRIPT_DIR/claude/sections/wordpress-security.md" ]; then
            sed -i.bak '/\[WORDPRESS_SECURITY\]/r '"$SCRIPT_DIR/claude/sections/wordpress-security.md" CLAUDE.md.working
            sed -i.bak '/\[WORDPRESS_SECURITY\]/d' CLAUDE.md.working
        fi
        
        if [ -f "$SHARED_DIR/claude/sections/coding-standards.md" ]; then
            sed -i.bak '/\[GENERAL_STANDARDS\]/r '"$SHARED_DIR/claude/sections/coding-standards.md" CLAUDE.md.working
            sed -i.bak '/\[GENERAL_STANDARDS\]/d' CLAUDE.md.working
        fi
        
        if [ -f "$SHARED_DIR/claude/sections/security-practices.md" ]; then
            sed -i.bak '/\[GENERAL_SECURITY\]/r '"$SHARED_DIR/claude/sections/security-practices.md" CLAUDE.md.working
            sed -i.bak '/\[GENERAL_SECURITY\]/d' CLAUDE.md.working
        fi
        
        # Final replacements
        sed -e "s|\[RELEASE_PROCESS\]|See GitHub Releases for automated releases via Release Drafter|g" \
            -e "s|\[CUSTOM_SECTIONS\]||g" CLAUDE.md.working > CLAUDE.md
        
        # Clean up ALL temporary files
        rm -f CLAUDE.md.tmp CLAUDE.md.working CLAUDE.md.working.bak
        print_info "✓ CLAUDE.md created"
    fi
else
    # Create new CLAUDE.md
    cp "$SCRIPT_DIR/claude/template.md" CLAUDE.md
    
    # Replace placeholders (same as above)
    sed -i.bak -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[PROJECT_DESCRIPTION\]|$PROJECT_DESCRIPTION|g" \
        -e "s|\[PROJECT_SUBTYPE\]|$PROJECT_SUBTYPE|g" \
        -e "s|\[MAIN_FILE\]|$MAIN_FILE|g" \
        -e "s|\[PLUGIN_SLUG\]|$PLUGIN_SLUG|g" \
        -e "s|\[WP_VERSION\]|6.0|g" \
        -e "s|\[PHP_VERSION\]|8.2|g" CLAUDE.md && rm CLAUDE.md.bak
    
    # Create temporary file for processing
    cp CLAUDE.md CLAUDE.md.working
    
    # Process each placeholder one by one using sed with file input
    if [ -f "$SCRIPT_DIR/claude/sections/wordpress-standards.md" ]; then
        sed -i.bak '/\[WORDPRESS_STANDARDS\]/r '"$SCRIPT_DIR/claude/sections/wordpress-standards.md" CLAUDE.md.working
        sed -i.bak '/\[WORDPRESS_STANDARDS\]/d' CLAUDE.md.working
    fi
    
    if [ -f "$SCRIPT_DIR/claude/sections/wordpress-security.md" ]; then
        sed -i.bak '/\[WORDPRESS_SECURITY\]/r '"$SCRIPT_DIR/claude/sections/wordpress-security.md" CLAUDE.md.working
        sed -i.bak '/\[WORDPRESS_SECURITY\]/d' CLAUDE.md.working
    fi
    
    if [ -f "$SHARED_DIR/claude/sections/coding-standards.md" ]; then
        sed -i.bak '/\[GENERAL_STANDARDS\]/r '"$SHARED_DIR/claude/sections/coding-standards.md" CLAUDE.md.working
        sed -i.bak '/\[GENERAL_STANDARDS\]/d' CLAUDE.md.working
    fi
    
    if [ -f "$SHARED_DIR/claude/sections/security-practices.md" ]; then
        sed -i.bak '/\[GENERAL_SECURITY\]/r '"$SHARED_DIR/claude/sections/security-practices.md" CLAUDE.md.working
        sed -i.bak '/\[GENERAL_SECURITY\]/d' CLAUDE.md.working
    fi
    
    # Final replacements
    sed -e "s|\[RELEASE_PROCESS\]|See GitHub Releases for automated releases via Release Drafter|g" \
        -e "s|\[CUSTOM_SECTIONS\]||g" CLAUDE.md.working > CLAUDE.md
    
    # Clean up ALL temporary files
    rm -f CLAUDE.md.working CLAUDE.md.working.bak
    print_info "✓ CLAUDE.md created"
fi

# Step 10: Install dependencies
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

# Step 11: Cleanup
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
echo "   - GitHub Releases with automated changelog via Release Drafter"
echo "   - Composer distribution via dist branch"
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
echo "   1. Merge PR to main branch"
echo "   2. Publish the draft release on GitHub"
echo "   3. Assets and dist branch are created automatically"