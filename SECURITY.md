# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 2.x | ✅ |
| 1.x | ❌ (end of life) |

## API Key Safety

Documentum stores all API keys in the OS secure keychain via `flutter_secure_storage`. Keys are **never** written to plain text files, logged, or transmitted anywhere other than the respective AI provider's HTTPS endpoint.

If you believe a key has been exposed, rotate it immediately in the provider's dashboard.

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, email **arsalankaleem.dev@gmail.com** with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix (optional)

You will receive a response within 72 hours. If the vulnerability is confirmed, a patch will be released as soon as possible and you will be credited in the changelog (unless you prefer to remain anonymous).
