# Bootstrap + Seeding Flow

Run one command:
```bash
make bootstrap
```

What it does:
1. Generates `.env` from `templates/.env.example` (if missing)
2. Optionally starts compose minimal profile
3. Seeds baseline Vikunja project + labels
4. Seeds baseline Mattermost team + channels
5. Seeds OpenClaw cron jobs
6. Generates default automation seed artifacts

Idempotency:
- Existing resources are detected and skipped.
