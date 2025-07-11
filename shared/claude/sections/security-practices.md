### Input Validation
- Never trust user input
- Validate all input on the server side
- Use allowlists over blocklists when possible
- Validate data type, length, format, and range

### Output Escaping
- Escape all output based on context
- Escape late (right before output)
- Use context-appropriate escaping functions

### Authentication & Authorization
- Check user permissions before any sensitive operation
- Use secure session management
- Implement proper access controls
- Never store passwords in plain text

### Data Protection
- Use HTTPS for all communications
- Encrypt sensitive data at rest
- Follow the principle of least privilege
- Never commit secrets or API keys to version control
- Use environment variables for sensitive configuration

### Dependencies
- Keep all dependencies up to date
- Regularly audit dependencies for vulnerabilities
- Only use trusted packages from reputable sources
- Review dependency licenses for compatibility