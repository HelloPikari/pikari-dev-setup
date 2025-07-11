# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

[PROJECT_NAME] is a WordPress [PROJECT_SUBTYPE] that [PROJECT_DESCRIPTION].

## Development Commands

### Build and Development
```bash
# Install dependencies
npm install
composer install

# Start development build with file watching
npm start

# Production build
npm run build

# Create plugin ZIP for distribution
npm run plugin-zip
```

### Code Quality
```bash
# Run all linting
npm run lint:all

# Auto-fix linting issues
npm run lint:fix

# Run PHP linting only
npm run lint:php

# Run JavaScript linting only
npm run lint:js

# Run CSS linting only
npm run lint:css
```

### Testing
```bash
# Run JavaScript tests
npm test

# Run PHP tests
composer test
```

### WordPress Playground
```bash
# Start local WordPress Playground
npm run playground
```

## Coding Standards

[WORDPRESS_STANDARDS]

[GENERAL_STANDARDS]

## Architecture

### Project Structure
- `[MAIN_FILE]` - Main plugin/theme file with WordPress headers
- `includes/` - PHP classes and core functionality (PSR-4 autoloaded)
- `src/` - JavaScript and SCSS source files
- `build/` - Compiled assets (gitignored, created by build process)
- `languages/` - Translation files (.pot, .po, .mo)
- `tests/` - Unit and integration tests
- `bin/` - Utility scripts (e.g., release automation)
- `_playground/` - WordPress Playground configuration

### Key WordPress Patterns
- Use WordPress hooks: `add_action()`, `add_filter()`, `remove_action()`, `remove_filter()`
- Enqueue scripts and styles properly using `wp_enqueue_script()` and `wp_enqueue_style()`
- Register scripts/styles first with `wp_register_script()` when reusing
- Use WordPress APIs for all operations (database, HTTP requests, filesystem)
- Follow WordPress file naming conventions
- Use WordPress template hierarchy for themes

### Dependencies
- WordPress [WP_VERSION]
- PHP [PHP_VERSION]
- Node.js for build tools
- Composer for PHP dependencies

## Git Workflow

- Main branch: `main`
- Feature branches: `feature/description`
- Bugfix branches: `fix/description`
- Commit format: `type: Brief description`
  - Types: feat, fix, docs, style, refactor, test, chore
- Pre-commit hooks run linting automatically via Husky
- All commits must pass linting

## Testing

- JavaScript tests in `tests/unit/`
- PHP tests in `tests/` following PHPUnit structure
- Run all tests before submitting PR
- Write tests for new features and bug fixes
- Aim for good test coverage

## Security Considerations

[WORDPRESS_SECURITY]

[GENERAL_SECURITY]

## Important Notes

- This project uses Husky for pre-commit hooks
- All PRs must pass CI checks (linting, tests, build)
- The `build/` folder is gitignored but required for the plugin to function
- Releases are created from the `build` branch which includes compiled assets
- Compatible with WordPress [WP_VERSION]+
- Requires PHP [PHP_VERSION]+
- Uses `@wordpress/scripts` for build tooling
- Follow WordPress plugin/theme guidelines for wordpress.org submission

## Release Process

[RELEASE_PROCESS]

## WordPress-Specific Guidelines

### Block Editor (Gutenberg)
- Use `@wordpress/*` packages for block editor functionality
- Register blocks properly with `register_block_type()`
- Provide block.json for block metadata
- Support WordPress core blocks where applicable

### Internationalization
- All user-facing strings must be translatable
- Use proper text domains: `__()`, `_e()`, `_n()`, `_x()`, etc.
- Text domain must match plugin/theme slug
- Generate .pot files for translators

### Performance
- Minimize database queries
- Use object caching when available
- Lazy load assets and functionality
- Follow WordPress performance best practices

### Backwards Compatibility
- Maintain compatibility with supported WordPress versions
- Check for function existence when using newer functions
- Provide graceful degradation

## Quick Reference

### Common WordPress Functions
```php
// Escaping
esc_html( $text )
esc_attr( $text )
esc_url( $url )
wp_kses_post( $content )

// Sanitization
sanitize_text_field( $input )
sanitize_email( $email )
absint( $number )

// Capabilities
current_user_can( 'edit_posts' )
current_user_can( 'manage_options' )

// Nonces
wp_nonce_field( 'action_name' )
wp_verify_nonce( $_POST['_wpnonce'], 'action_name' )
```

### WP-CLI Commands
```bash
# Useful during development
wp cache flush
wp rewrite flush
wp cron run --all
```

[CUSTOM_SECTIONS]