# Config-as-Code Layer

Declarative config file:
- `templates/org.sample.json`

Supported blocks:
- `mattermost.team`
- `mattermost.channels[]`
- `mattermost.webhooks[]`
- `vikunja.project`
- `vikunja.labels[]`
- `vikunja.templates[]`
- `openclaw.cron_jobs[]`

Apply:
```bash
./scripts/apply-config.sh templates/org.sample.json
```

Dry-run:
```bash
DRY_RUN=1 ./scripts/apply-config.sh templates/org.sample.json
```

Idempotency rules:
- Existing Mattermost team/channels/webhooks are detected and skipped.
- Existing Vikunja project/labels/template-stub tasks are detected and skipped.
- Existing OpenClaw cron jobs (by name) are detected and skipped.
