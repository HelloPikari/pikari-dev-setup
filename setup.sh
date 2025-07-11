#!/bin/bash

# Pikari Development Environment Setup
# This script helps you choose and install the appropriate development environment

echo ""
echo "██████╗ ██╗██╗  ██╗ █████╗ ██████╗ ██╗"
echo "██╔══██╗██║██║ ██╔╝██╔══██╗██╔══██╗██║"
echo "██████╔╝██║█████╔╝ ███████║██████╔╝██║"
echo "██╔═══╝ ██║██╔═██╗ ██╔══██║██╔══██╗██║"
echo "██║     ██║██║  ██╗██║  ██║██║  ██║██║"
echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
echo ""
echo "======================================"
echo "   Development Environment Setup"
echo "======================================"
echo ""
echo "This tool sets up a complete development environment including:"
echo "  • Linting configuration (ESLint, Stylelint, PHPCS)"
echo "  • Pre-commit hooks with Husky"
echo "  • GitHub workflows for CI/CD"
echo "  • Project-specific tools and configurations"
echo "  • CLAUDE.md for AI assistant context"
echo ""
echo "Available configurations:"
echo "  1) WordPress - Complete WordPress development environment"
echo "  2) [Coming Soon] React - Modern React application setup"
echo "  3) [Coming Soon] Laravel - Laravel application setup"
echo "  4) [Coming Soon] Generic - Language-agnostic setup"
echo ""

# Get user selection
read -p "Select configuration (1-4): " -n 1 -r
echo ""

case $REPLY in
    1)
        echo "Starting WordPress development environment setup..."
        # Pass all arguments to the wordpress setup script
        bash "$(dirname "$0")/wordpress/setup.sh" "$@"
        ;;
    2|3|4)
        echo "This configuration is not available yet."
        echo "Please check back later or contribute at: https://github.com/your-repo"
        exit 1
        ;;
    *)
        echo "Invalid selection. Please run the script again and select 1-4."
        exit 1
        ;;
esac