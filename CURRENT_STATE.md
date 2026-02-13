# Current State — ai-ops-starter-kit

## Status
T1 scaffold complete.

## Implemented
- Repo structure: infra/openclaw/automation/templates/scripts/docs
- Compose scaffold with profiles: minimal/full/prod
- Makefile command surface: status/doctor/backup/restore/upgrade/bootstrap
- Bootstrap + seeding flow (`make bootstrap`) with idempotent loaders
- Seed templates:
  - Mattermost team/channels
  - Vikunja project/labels
  - OpenClaw cron jobs
  - default automation artifacts
- Seed scripts:
  - `scripts/seed-mattermost.sh`
  - `scripts/seed-vikunja.sh`
  - `scripts/seed-openclaw-cron.sh`
  - `scripts/seed-automations.sh`
