### WordPress Security Best Practices

#### Output Escaping
- `esc_html()` - For plain text output
- `esc_attr()` - For HTML attribute values
- `esc_url()` - For URLs
- `esc_js()` - For inline JavaScript (deprecated, avoid inline JS)
- `wp_kses_post()` - For content with allowed HTML
- `esc_textarea()` - For textarea content

#### Input Sanitization
- `sanitize_text_field()` - For plain text input
- `sanitize_email()` - For email addresses
- `sanitize_url()` - For URLs
- `sanitize_key()` - For keys and slugs
- `wp_kses_post()` - For content with HTML
- `absint()` - For positive integers
- `intval()` - For integers

#### Nonces
- Always use nonces for forms and AJAX requests
- `wp_nonce_field()` - Add nonce to forms
- `check_admin_referer()` - Verify nonce in admin
- `wp_verify_nonce()` - Verify nonce programmatically

#### Capabilities
- Always check user capabilities before operations
- `current_user_can()` - Check if user has capability
- Use appropriate capabilities (e.g., 'edit_posts', 'manage_options')
- Never check for roles directly, always use capabilities

#### SQL Security
- Use `$wpdb->prepare()` for all queries with variables
- Never concatenate user input into SQL
- Use WordPress query functions when possible
- Validate and sanitize all database inputs