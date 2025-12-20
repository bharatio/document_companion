# Security Policy

## Supported Versions

We provide security updates for the following versions of Document Companion:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Document Companion seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please do NOT:

- Open a public GitHub issue
- Discuss the vulnerability publicly
- Share the vulnerability with others until it has been resolved

### Please DO:

1. **Email us directly** at [INSERT SECURITY EMAIL] with:
   - A clear description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Any suggested fixes (if you have them)

2. **Include the following information:**
   - Affected version(s)
   - Platform (Android/iOS/Web/etc.)
   - Any relevant code snippets or screenshots

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 7 days
- **Updates**: We will keep you informed of our progress
- **Resolution**: We will work to resolve the issue as quickly as possible

### Disclosure Policy

- We will credit you for the discovery (unless you prefer to remain anonymous)
- We will work with you to coordinate public disclosure after the fix is released
- We will not take legal action against security researchers who act in good faith

## Security Best Practices

When using Document Companion:

1. **Keep the app updated** - Always use the latest version
2. **Review permissions** - Only grant necessary permissions
3. **Secure your device** - Use device-level security features
4. **Be cautious with sensitive documents** - Don't store highly sensitive documents in the app
5. **Use strong device passwords** - Protect your device with a strong password/biometric

## Known Security Considerations

### Data Storage

- Documents are stored locally on your device
- Images are stored in SQLite database as BLOBs
- No data is transmitted to external servers (unless you explicitly share documents)

### Permissions

The app requires the following permissions:

- **Camera**: For scanning documents
- **Storage/Photos**: For saving and accessing scanned documents
- **Internet** (optional): For sharing documents (if implemented)

### Recommendations

- Regularly backup your documents
- Use device encryption when available
- Be cautious when sharing documents externally

## Security Updates

Security updates will be released as patch versions (e.g., 1.0.1, 1.0.2) and will be clearly marked in release notes.

## Questions?

If you have questions about security, please open a [GitHub Discussion](https://github.com/yourusername/document_companion/discussions) (for general questions) or email us directly (for security-specific concerns).

Thank you for helping keep Document Companion secure! 🔒

