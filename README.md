# Pikari Development Environment Setup

A comprehensive tool for setting up consistent development environments across projects. This tool goes beyond just linting to provide a complete development environment including pre-commit hooks, CI/CD workflows, and project-specific configurations.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/pikari-dev-setup.git

# Navigate to your project directory
cd your-wordpress-project

# Run the setup
../pikari-dev-setup/setup.sh
```

## 📋 What's Included

### WordPress Environment
- **Linting Configuration**
  - ESLint with WordPress standards
  - Stylelint for CSS/SCSS
  - PHPCS with WordPress coding standards
  - Prettier for consistent formatting
  
- **Pre-commit Hooks**
  - Husky + lint-staged
  - Automatic linting on commit
  
- **GitHub Workflows**
  - CI workflow for tests and linting
  - Build branch automation
  - Release automation
  
- **WordPress Playground**
  - Local development blueprint
  - Demo blueprint for GitHub
  
- **Release Automation**
  - Automated version updates
  - Build branch tagging
  - GitHub release creation
  
- **CLAUDE.md**
  - AI assistant context
  - Project-specific guidelines
  - Coding standards documentation

## 🏗️ Project Structure

```
pikari-dev-setup/
├── setup.sh              # Main entry point
├── shared/               # Shared components
│   ├── husky/           # Generic pre-commit hooks
│   └── claude/          # Base CLAUDE.md templates
└── wordpress/           # WordPress-specific setup
    ├── setup.sh         # WordPress setup script
    ├── linting/         # Linting configurations
    ├── github/          # GitHub workflows
    ├── playground/      # WordPress Playground configs
    ├── release/         # Release automation
    ├── claude/          # WordPress CLAUDE.md templates
    └── package-scripts/ # npm/composer scripts
```

## 🔧 Usage

### Initial Setup

1. Run the setup script from your project root:
   ```bash
   path/to/pikari-dev-setup/setup.sh
   ```

2. Select your project type (currently WordPress only)

3. Follow the prompts to:
   - Copy configuration files
   - Set up pre-commit hooks
   - Create GitHub workflows
   - Generate CLAUDE.md
   - Update package.json/composer.json

4. Install dependencies:
   ```bash
   npm install
   composer install
   ```

### After Setup

**Run linting:**
```bash
npm run lint:all     # Run all linters
npm run lint:fix     # Auto-fix issues
```

**Start development:**
```bash
npm start            # Start dev build
npm run playground   # Launch WordPress Playground
```

**Create a release:**
```bash
./bin/release.sh     # Automated release process
```

## 🛠️ Customization

### Adding New Project Types

1. Create a new directory under `pikari-dev-setup/`:
   ```bash
   mkdir react
   ```

2. Add project-specific components:
   - `setup.sh` - Setup script
   - Linting configurations
   - Tool configurations
   - Templates

3. Update main `setup.sh` to include the new option

### Modifying Shared Components

Shared components in the `shared/` directory can be used across all project types:
- Husky configurations
- Base CLAUDE.md sections
- Common workflows

## 📝 Requirements

- **Node.js** 16+ (for JavaScript tooling)
- **PHP** 8.2+ (for WordPress projects)
- **Composer** (for PHP dependencies)
- **jq** (for JSON manipulation in scripts)
- **Git** (for version control)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Adding a New Configuration

1. Create a new directory under `pikari-dev-setup/`
2. Add all necessary config files and setup script
3. Create comprehensive documentation
4. Update the main setup.sh to include your configuration
5. Submit a pull request

## 📄 License

MIT - Feel free to use and modify these configurations for your projects.

## 🙏 Acknowledgments

Built with inspiration from various open-source projects and the WordPress community.