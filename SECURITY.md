# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.0.x   | Yes       |

Only the latest release on `main` receives security updates.

## Reporting a Vulnerability

### GitHub Private Vulnerability Reporting (preferred)

Report vulnerabilities through [GitHub's private vulnerability reporting](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/security/advisories/new).

### Email

Send an email to `hello@verygood.ventures` with a `[SECURITY]` subject prefix.

### What to Include

- A description of the vulnerability
- Steps to reproduce the issue
- Affected files or components

### Response Timeline

- **Acknowledgment** — within 5 business days
- **Assessment** — within 10 business days
- **Notification** — you will be notified when a fix is released

## Scope

This is a documentation-only plugin with no Dart/Flutter source code. The security-relevant surface areas are:

### Skill Files (`skills/*/SKILL.md`, `skills/*/reference.md`)

- Insecure code examples that developers may copy into production
- Outdated or misleading security guidance (especially the `static-security` skill)
- Recommendations that contradict current best practices

### Hook Shell Scripts (`hooks/scripts/`)

- Command injection vulnerabilities
- Unsafe path handling
- Unintended code execution

### Plugin Manifest & MCP Config (`.claude-plugin/plugin.json`, `.mcp.json`)

- Excessive permissions
- Exploitable MCP server definitions

## Recognition

We are happy to acknowledge reporters in the fix PR upon request.
