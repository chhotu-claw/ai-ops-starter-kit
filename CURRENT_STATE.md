# CURRENT_STATE

## 2026-02-13 (T2 complete)
- Replaced placeholder compose with real stack wiring:
  - postgres (shared)
  - redis
  - mattermost
  - vikunja
  - caddy reverse proxy
  - optional automation services (dispatcher, bridge, openclaw-worker)
- Added profile behavior:
  - `minimal`: core stack only
  - `full`: core + automation-dispatcher + webhook-bridge
  - `prod`: full + openclaw-worker
- Added Caddy config (`infra/Caddyfile`) with:
  - `/` -> Mattermost
  - `/vikunja` -> Vikunja
  - `/healthz` probe endpoint
- Added Postgres bootstrap init script (`infra/initdb/10-create-app-dbs.sh`) to create separate Mattermost and Vikunja DB/users.
- Updated bootstrap/status/doctor scripts to execute real compose actions and checks.

## 2026-02-13 (T3 complete)
- Added one-flow bootstrap orchestration (`scripts/bootstrap.sh`) for:
  - env generation
  - optional compose startup
  - idempotent seed execution
- Added seed templates under `templates/seeds/` for:
  - Mattermost team/channels
  - Vikunja project/labels
  - OpenClaw cron jobs
  - automation defaults
- Added seed scripts:
  - `scripts/seed-mattermost.sh`
  - `scripts/seed-vikunja.sh`
  - `scripts/seed-openclaw-cron.sh`
  - `scripts/seed-automations.sh`
- Added shared script helpers in `scripts/lib.sh` with safer `.env` parsing.

## 2026-02-13 (T4 complete)
- Added declarative config-as-code sample: `templates/org.sample.json`
- Added idempotent unified apply loader: `scripts/apply-config.sh`
  - Mattermost: team/channel/webhook
  - Vikunja: project/labels/template stubs
  - OpenClaw: cron jobs
- Added Make target `apply-config`.
- Verified idempotent apply behavior (dry-run and rerun-safe checks).

## 2026-02-13 (OSS T1 complete)
- Added MIT `LICENSE`
- Added OSS community and security docs:
  - `CONTRIBUTING.md`
  - `CODE_OF_CONDUCT.md`
  - `SECURITY.md`
- Added GitHub templates:
  - issue templates (bug + feature + config)
  - PR template
- Added release readiness checklist:
  - `docs/RELEASE_READINESS_CHECKLIST.md`

## 2026-02-13 (OSS T2 complete)
- Built showcase website under `website/` with sections:
  - Hero
  - What it includes
  - Architecture
  - Presets
  - Quickstart
  - CTA
- Implemented dark minimal technical aesthetic with mono labels and bracket accents.
- Added responsive static styling and deployment notes in `docs/SHOWCASE_WEBSITE.md`.

## 2026-02-13 (Installer T1 complete)
- Added one-command installer core: `scripts/install.sh`
  - interactive + `--yes` non-interactive mode
  - prereq checks
  - prompt flow (domain/preset/timezone/port/admin email)
  - release tarball + checksum download/verification
  - extract + env generation + preset apply + bootstrap
  - post-install health checks + summary output
- Added installer docs: `docs/INSTALLER.md`

## 2026-02-13 (Installer T2 complete)
- Added release packaging script: `scripts/package-release.sh`
  - builds versioned tar.gz (excludes .git/.env/node_modules)
  - generates SHA256SUMS
  - creates `latest.json` manifest with version, tarball_url, checksum_url, released_at
  - supports `--publish` to copy artifacts to webroot
  - auto-detects version from VERSION file
- Added VERSION file (`0.1.0`)

