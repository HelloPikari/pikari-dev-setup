### Code Style and Linting

**IMPORTANT**: All generated code MUST follow the linting configurations defined in this project:

- **PHP**: Use 4 spaces for indentation (NO TABS) - see phpcs.xml
- **JavaScript**: Follow ESLint + Prettier configuration
- **CSS/SCSS**: Follow Stylelint configuration
- Generated code must pass all linting checks without modifications

### General Principles
- Write clean, readable, and maintainable code
- Follow the principle of least surprise
- Prefer clarity over cleverness
- Use meaningful variable and function names
- Keep functions small and focused on a single responsibility
- Comment complex logic, not obvious code
- Maintain consistent formatting (enforced by linters)

### Documentation
- Document all public APIs
- Include examples in documentation
- Keep documentation up-to-date with code changes
- Use inline comments sparingly and only when necessary

### Error Handling
- Always handle errors appropriately
- Provide meaningful error messages
- Log errors for debugging but don't expose sensitive info
- Fail fast and fail clearly

### Performance
- Optimize for readability first, performance second
- Profile before optimizing
- Avoid premature optimization
- Consider caching for expensive operations