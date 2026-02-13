# AI Ops Starter Kit

Starter monorepo to bootstrap an AI operations stack (OpenClaw + Vikunja + Mattermost + automation workers).

## Architecture (T1 scaffold)
- `infra/` — docker-compose, networking, persistence primitives
- `openclaw/` — agent, cron, and runtime config templates
- `automation/` — dispatcher/watcher/bridge service modules
- `templates/` — env/config templates for deployments
- `scripts/` — bootstrap, health checks, backup/restore, upgrades
- `docs/` — quickstart, hardening, troubleshooting, runbooks

## Compose profiles
- `minimal` — base core services only
- `full` — core + automation + observability helpers
- `prod` — hardened baseline (resource/restart/logging defaults)

## Command surface
Use Makefile targets:
- `make bootstrap`
- `make status`
- `make doctor`
- `make backup`
- `make restore`
- `make upgrade`

## Quickstart
```bash
cp templates/.env.example .env
make bootstrap
make status
```

> This is T1 architecture scaffold; concrete service wiring and seeders arrive in later tasks.
