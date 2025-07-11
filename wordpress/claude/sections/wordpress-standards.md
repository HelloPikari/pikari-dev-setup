### PHP Coding Standards
- Follow WordPress Coding Standards with **4 spaces indentation (NOT TABS)**
- This project's phpcs.xml enforces space-based indentation
- Use meaningful function and variable names with underscores (not camelCase)
- Prefix all global functions with your plugin/theme prefix
- Document all functions with proper PHPDoc blocks
- Use WordPress functions when available (e.g., `wp_remote_get()` instead of `curl`)

### JavaScript Standards
- Use WordPress ESLint configuration
- Single quotes for strings
- Space indentation as configured in .eslintrc.cjs
- Meaningful variable names in camelCase
- Use `wp` global for WordPress JavaScript APIs

### CSS/SCSS Standards
- Follow WordPress CSS coding standards
- Use semantic, descriptive class names
- Prefix all CSS classes with your plugin/theme prefix
- Mobile-first responsive design
- Use CSS custom properties for theme compatibility

### HTML Standards
- Use semantic HTML5 elements
- Ensure proper accessibility (ARIA labels, alt text, etc.)
- Follow WordPress HTML coding standards
- Validate HTML output

### Database Queries
- Use WordPress database APIs (`$wpdb`)
- Always prepare SQL queries to prevent injection
- Cache expensive queries using transients
- Follow WordPress database schema conventions