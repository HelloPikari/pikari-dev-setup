# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

[PROJECT_NAME] is a [PROJECT_TYPE] that [PROJECT_DESCRIPTION].

## Development Commands

[DEVELOPMENT_COMMANDS]

## Coding Standards

[CODING_STANDARDS]

## Architecture

[ARCHITECTURE_SECTION]

## Git Workflow

- Main branch: `main`
- Feature branches: `feature/description`
- Bugfix branches: `fix/description`
- Commit format: `type: Brief description`
  - Types: feat, fix, docs, style, refactor, test, chore
- Pre-commit hooks run linting automatically via Husky

## Testing

[TESTING_SECTION]

## Security Considerations

[SECURITY_SECTION]

## Important Notes

- This project uses Husky for pre-commit hooks
- All PRs must pass CI checks
- [ADDITIONAL_NOTES]

## Quick Commands Reference

```bash
# Development
npm start           # Start development mode
npm run build       # Production build

# Code Quality
npm run lint:all    # Run all linters
npm run lint:fix    # Auto-fix linting issues

# Testing
npm test           # Run tests

# Git Hooks
git commit         # Runs pre-commit hooks automatically
git commit --no-verify  # Skip hooks (use sparingly)
```

[CUSTOM_SECTIONS]
