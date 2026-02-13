# AI Ops Starter Kit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Starter monorepo to bootstrap an AI operations stack (OpenClaw + Vikunja + Mattermost + deterministic automation workers).

## Website
- Showcase site source: `website/`
- Local preview:
  ```bash
  cd website
  python3 -m http.server 8088
  # open http://localhost:8088
  ```
- Public URL: **TBD** (deploy target not set in this repo yet)

## Architecture
- `infra/` — reverse proxy and infra wiring
- `openclaw/` — agent, cron, and runtime config templates
- `automation/` — dispatcher/watcher/bridge service modules
- `templates/` — env/config templates for deployments
- `scripts/` — bootstrap, health checks, backup/restore, upgrades
- `docs/` — quickstart, hardening, troubleshooting, runbooks

## Compose Profiles
- `minimal` — postgres + redis + mattermost + vikunja + caddy
- `full` — minimal + automation-dispatcher + webhook-bridge
- `prod` — full + openclaw-worker

## Commands
Use Makefile targets:
- `make bootstrap`
- `make apply-config`
- `make status`
- `make doctor`
- `make backup`
- `make restore`
- `make upgrade`

## One-command installer
See `docs/INSTALLER.md`.

Expected hosted UX:
```bash
bash <(curl -fsSL https://aiops.chhotu.online/install.sh)
```

## Config-as-code
Declarative org config file:
- `templates/org.sample.json`

Supported sections:
- Mattermost: team/channel/webhook
- Vikunja: project/labels/templates
- OpenClaw: cron jobs

Apply idempotently:
```bash
./scripts/apply-config.sh templates/org.sample.json
```
Dry-run:
```bash
DRY_RUN=1 ./scripts/apply-config.sh templates/org.sample.json
```

## Open Source Docs
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
- [SECURITY.md](./SECURITY.md)
- [Release Readiness Checklist](./docs/RELEASE_READINESS_CHECKLIST.md)
- [Showcase Website Notes](./docs/SHOWCASE_WEBSITE.md)

## Quickstart (one bootstrap flow)
```bash
make bootstrap
make status
make doctor
```

Bootstrap does:
1. Generates `.env` (if missing)
2. Starts compose profile (`COMPOSE_PROFILES`, default `minimal`)
3. (Optional) Seeds baseline Vikunja project + labels (requires `VIKUNJA_TOKEN`)
4. (Optional) Seeds baseline Mattermost team + channels (requires `MATTERMOST_BOT_TOKEN`)
5. Loads default OpenClaw cron jobs
6. Writes default automation seed artifacts

Default local URLs (override port with `CADDY_HTTP_PORT`):
- Mattermost: `http://localhost:${CADDY_HTTP_PORT:-8080}`
- Vikunja: `http://localhost:${CADDY_HTTP_PORT:-8080}/vikunja`
- Health: `http://localhost:${CADDY_HTTP_PORT:-8080}/healthz`
