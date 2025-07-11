#!/bin/bash

# Shared functions for Pikari Development Environment Setup

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

# Function to collect project information
collect_project_info() {
    print_header "Project Information"
    
    # Try to auto-detect project name from directory
    local suggested_name=$(basename "$(pwd)")
    
    # For WordPress projects, try to get name from PHP files
    if [ "$PROJECT_TYPE" = "wordpress" ]; then
        local main_file=$(find . -maxdepth 1 -name "*.php" -exec grep -l "Plugin Name:\|Theme Name:" {} \; | head -1)
        if [ -n "$main_file" ]; then
            suggested_name=$(grep -E "Plugin Name:|Theme Name:" "$main_file" | head -1 | sed 's/.*: //' | sed 's/\*//' | xargs)
        fi
    fi
    
    # Project Name
    echo "Project Name (press Enter to use: $suggested_name)"
    read -p "> " project_name_input
    PIKARI_PROJECT_NAME=${project_name_input:-$suggested_name}
    
    # Project Description
    echo ""
    echo "Project Description (brief description of what your project does):"
    read -p "> " PIKARI_PROJECT_DESCRIPTION
    while [ -z "$PIKARI_PROJECT_DESCRIPTION" ]; do
        print_warning "Project description is required"
        read -p "> " PIKARI_PROJECT_DESCRIPTION
    done
    
    # Author Name
    echo ""
    # Try to get from git config
    local suggested_author=$(git config user.name 2>/dev/null || echo "")
    if [ -n "$suggested_author" ]; then
        echo "Author Name (press Enter to use: $suggested_author)"
        read -p "> " author_input
        PIKARI_AUTHOR_NAME=${author_input:-$suggested_author}
    else
        echo "Author Name:"
        read -p "> " PIKARI_AUTHOR_NAME
        while [ -z "$PIKARI_AUTHOR_NAME" ]; do
            print_warning "Author name is required"
            read -p "> " PIKARI_AUTHOR_NAME
        done
    fi
    
    # Author Email
    echo ""
    # Try to get from git config
    local suggested_email=$(git config user.email 2>/dev/null || echo "")
    if [ -n "$suggested_email" ]; then
        echo "Author Email (press Enter to use: $suggested_email)"
        read -p "> " email_input
        PIKARI_AUTHOR_EMAIL=${email_input:-$suggested_email}
    else
        echo "Author Email:"
        read -p "> " PIKARI_AUTHOR_EMAIL
        while [ -z "$PIKARI_AUTHOR_EMAIL" ]; do
            print_warning "Author email is required"
            read -p "> " PIKARI_AUTHOR_EMAIL
        done
    fi
    
    # Project Homepage (optional)
    echo ""
    echo "Project Homepage (optional, e.g., https://example.com):"
    read -p "> " PIKARI_PROJECT_HOMEPAGE
    
    # Get GitHub info from git remote if available
    if git remote get-url origin 2>/dev/null | grep -q github.com; then
        GITHUB_URL=$(git remote get-url origin | sed 's/\.git$//')
        PIKARI_GITHUB_ORG=$(echo "$GITHUB_URL" | sed 's/.*github.com[:/]//' | cut -d'/' -f1)
        PIKARI_GITHUB_REPO=$(echo "$GITHUB_URL" | sed 's/.*github.com[:/]//' | cut -d'/' -f2)
    else
        PIKARI_GITHUB_ORG=""
        PIKARI_GITHUB_REPO=""
    fi
    
    # Export all variables for use in sub-scripts
    export PIKARI_PROJECT_NAME
    export PIKARI_PROJECT_DESCRIPTION
    export PIKARI_AUTHOR_NAME
    export PIKARI_AUTHOR_EMAIL
    export PIKARI_PROJECT_HOMEPAGE
    export PIKARI_GITHUB_ORG
    export PIKARI_GITHUB_REPO
    export PROJECT_TYPE
    
    # Display summary
    print_header "Project Information Summary"
    echo "Project Name: $PIKARI_PROJECT_NAME"
    echo "Description: $PIKARI_PROJECT_DESCRIPTION"
    echo "Author: $PIKARI_AUTHOR_NAME <$PIKARI_AUTHOR_EMAIL>"
    if [ -n "$PIKARI_PROJECT_HOMEPAGE" ]; then
        echo "Homepage: $PIKARI_PROJECT_HOMEPAGE"
    fi
    if [ -n "$PIKARI_GITHUB_ORG" ] && [ -n "$PIKARI_GITHUB_REPO" ]; then
        echo "GitHub: $PIKARI_GITHUB_ORG/$PIKARI_GITHUB_REPO"
    fi
    echo ""
    
    read -p "Is this information correct? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        # Recursively call to re-collect info
        collect_project_info
    fi
}

# Function to replace placeholders in a file
replace_placeholders() {
    local file="$1"
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Replace placeholders
    sed -i.tmp \
        -e "s/\[PROJECT_NAME\]/$PIKARI_PROJECT_NAME/g" \
        -e "s/\[PROJECT_DESCRIPTION\]/$PIKARI_PROJECT_DESCRIPTION/g" \
        -e "s/\[AUTHOR_NAME\]/$PIKARI_AUTHOR_NAME/g" \
        -e "s/\[AUTHOR_EMAIL\]/$PIKARI_AUTHOR_EMAIL/g" \
        -e "s/\[PROJECT_HOMEPAGE\]/$PIKARI_PROJECT_HOMEPAGE/g" \
        -e "s/\[GITHUB_ORG\]/$PIKARI_GITHUB_ORG/g" \
        -e "s/\[GITHUB_REPO\]/$PIKARI_GITHUB_REPO/g" \
        "$file" && rm "$file.tmp"
    
    # Remove backup if successful
    if [ $? -eq 0 ]; then
        rm "$file.bak"
    else
        print_error "Failed to replace placeholders in $file"
        mv "$file.bak" "$file"
        return 1
    fi
}