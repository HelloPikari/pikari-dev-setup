# WordPress Linting Configuration

This configuration provides WordPress coding standards for PHP, JavaScript, and CSS/SCSS files. It ensures your code follows the official WordPress coding standards and integrates seamlessly with VS Code/Cursor for format-on-save functionality.

## What's Included

- **`.eslintrc.cjs`** - ESLint configuration extending WordPress standards
- **`.stylelintrc.json`** - Stylelint configuration for CSS/SCSS files
- **`phpcs.xml`** - PHP CodeSniffer configuration using WordPress standards with spaces
- **`.prettierrc`** - Prettier configuration with explicit WordPress standards
- **`.editorconfig`** - Editor configuration for consistent formatting
- **`.vscode/settings.json`** - VS Code/Cursor workspace settings
- **`setup.sh`** - Automated setup script

## Features

- **WordPress Standards**: Uses official WordPress coding standards
- **Space Indentation**: Configured to use 4 spaces instead of tabs
- **Auto-fixing**: All linters support auto-fix commands
- **Editor Integration**: Works seamlessly with VS Code and other editors

## Installation

### Automated Setup

1. Copy the entire `linting-config` directory to your new project
2. Run the setup script from your project root:
   ```bash
   ./linting-config/setup.sh
   # or to run WordPress config directly:
   ./linting-config/wordpress/setup.sh
   ```
3. The script will:
   - Copy all configuration files
   - Detect and offer to update package.json with linting scripts
   - Detect and offer to update composer.json with linting scripts
   - Prompt to remove the linting-config folder when done
4. Follow any remaining manual steps shown

To keep the folder for reference:
```bash
./linting-config/wordpress/setup.sh --keep-folder
```

**Note**: The automatic script updates require `jq` to be installed. If not available, the scripts will be displayed for manual addition.

### Manual Setup

1. Copy all config files (except this README and setup.sh) to your project root
2. Install PHP dependencies:
   ```bash
   composer require --dev squizlabs/php_codesniffer wp-coding-standards/wpcs dealerdirect/phpcodesniffer-composer-installer
   ```
3. Install Node dependencies:
   ```bash
   npm install --save-dev @wordpress/scripts @wordpress/eslint-plugin @wordpress/stylelint-config @wordpress/prettier-config
   ```

## Usage

### Linting Commands

Add these to your `package.json` scripts:
```json
{
  "scripts": {
    "lint:js": "wp-scripts lint-js src",
    "lint:js:fix": "wp-scripts lint-js src --fix",
    "lint:css": "wp-scripts lint-style",
    "lint:css:fix": "wp-scripts lint-style --fix",
    "lint:php": "composer run lint",
    "lint:php:fix": "composer run lint:fix",
    "lint:all": "npm run lint:js && npm run lint:css && npm run lint:php",
    "lint:fix": "npm run lint:js:fix && npm run lint:css:fix && npm run lint:php:fix"
  }
}
```

Add these to your `composer.json` scripts:
```json
{
  "scripts": {
    "lint": "phpcs",
    "lint:fix": "phpcbf"
  }
}
```

### Editor Integration

#### VS Code / Cursor

The setup script automatically copies VS Code settings. Required extensions:
- ESLint
- Prettier - Code formatter (esbenp.prettier-vscode)
- Stylelint
- PHP Intelephense
- phpcs

The included `.vscode/settings.json` configures:
- Format on save with Prettier for JS/CSS
- Auto-fix ESLint and Stylelint issues on save
- Single quotes for JavaScript
- WordPress coding standards for PHP

## Customization

### JavaScript/ESLint

To add custom rules, modify `.eslintrc.cjs`:
```javascript
module.exports = {
  // ... existing config
  rules: {
    // Add your custom rules here
  }
};
```

### CSS/Stylelint

To add custom rules, modify `.stylelintrc.json`:
```json
{
  "extends": "@wordpress/stylelint-config/scss",
  "rules": {
    // Add your custom rules here
  }
}
```

### PHP/PHPCS

To add custom rules or exclude patterns, modify `phpcs.xml`:
```xml
<rule ref="WordPress">
  <!-- Add exclusions here -->
</rule>
```

## Troubleshooting

### ESLint not finding WordPress config
Make sure `@wordpress/eslint-plugin` is installed:
```bash
npm install --save-dev @wordpress/eslint-plugin
```

### PHPCS not finding WordPress standards
Run the configuration command:
```bash
./vendor/bin/phpcs --config-set installed_paths vendor/wp-coding-standards/wpcs
```

### Conflicts with existing configurations
Remove any existing `.eslintrc.*`, `.stylelintrc.*`, or `phpcs.xml` files before copying the new ones.