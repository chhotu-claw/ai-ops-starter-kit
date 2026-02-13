# Security Policy

## Reporting a vulnerability
Please do **not** open public issues for security vulnerabilities.

Report privately to maintainers with:
- affected component/path
- impact
- reproduction steps
- suggested remediation (if available)

## Secrets handling
- Never commit `.env`, tokens, credentials, or private keys
- Rotate credentials if accidental exposure occurs

## Scope
Security policy applies to:
- bootstrap scripts
- config-as-code loaders
- compose/deployment baseline
- automation integrations
