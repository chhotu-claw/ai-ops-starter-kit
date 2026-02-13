# One-Command Installer (No Git Clone)

Target UX:
```bash
bash <(curl -fsSL https://aiops.chhotu.online/install.sh)
```

## What installer does
1. Prereq checks (`curl`, `tar`, `sha256sum`, `docker`)
2. Interactive prompt flow (or flags)
3. Resolve latest release tarball + checksum URL
4. Download artifact + checksum verification
5. Extract release into target directory
6. Generate `.env` from template
7. Apply selected preset config
8. Run bootstrap flow
9. Post-install health summary

## Non-interactive mode
```bash
bash <(curl -fsSL https://aiops.chhotu.online/install.sh) --yes \
  --domain aiops.local \
  --preset small-agency \
  --timezone Asia/Dubai \
  --port 8080 \
  --admin-email ops@example.com
```

## Flags
- `--yes`
- `--version <tag>`
- `--install-dir <path>`
- `--domain <domain>`
- `--preset <name>`
- `--timezone <iana>`
- `--port <port>`
- `--admin-email <email>`
- `--base-url <url>`
- `--release-url <url>`
- `--checksum-url <url>`
- `--skip-bootstrap`

## Release hosting requirements
Host these files:
- `/install.sh`
- `/releases/latest.json` (with `version`, `tarball_url`, `checksum_url`)
- `/releases/ai-ops-starter-kit-<version>.tar.gz`
- `/releases/ai-ops-starter-kit-<version>.tar.gz.sha256`
