# AI Ops Starter Kit

Starter monorepo to bootstrap an AI operations stack (OpenClaw + Vikunja + Mattermost + automation workers).

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

## Quickstart (one bootstrap flow)
```bash
make bootstrap
make status
```

Bootstrap does:
1. Generates `.env` (if missing)
2. Starts compose profile (`COMPOSE_PROFILES`, default `minimal`)
3. Seeds baseline Vikunja project + labels
4. Seeds baseline Mattermost team + channels
5. Loads default OpenClaw cron jobs
6. Writes default automation seed artifacts

Default local URLs:
- Mattermost: `http://localhost:8080`
- Vikunja: `http://localhost:8080/vikunja`
