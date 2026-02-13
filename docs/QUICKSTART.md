# Quickstart

1. Run bootstrap:
   ```bash
   make bootstrap
   ```
2. Verify:
   ```bash
   make status
   make doctor
   ```

Bootstrap flow performs:
- `.env` generation (if missing)
- compose startup (default profile: `minimal`)
- seed loaders (Mattermost/Vikunja/OpenClaw cron/automation)

## Seed-only mode (skip stack startup)
```bash
SKIP_COMPOSE=1 make bootstrap
```

## Profiles
- `minimal`: core collaboration stack only
- `full`: core + automation placeholders
- `prod`: full + extra worker

## URLs (default)
- Mattermost: `http://localhost:8080`
- Vikunja: `http://localhost:8080/vikunja`
- Health: `http://localhost:8080/healthz`
