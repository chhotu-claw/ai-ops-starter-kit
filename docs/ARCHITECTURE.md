# Architecture Notes (T2)

Compose services:
- `postgres` (shared DB)
- `redis`
- `mattermost`
- `vikunja`
- `caddy` reverse proxy
- optional automation workers (`automation-dispatcher`, `webhook-bridge`, `openclaw-worker`)

Profiles:
- `minimal`: postgres + redis + mattermost + vikunja + caddy
- `full`: minimal + automation-dispatcher + webhook-bridge
- `prod`: full + openclaw-worker

Default local endpoints:
- Mattermost: `http://localhost:8080`
- Vikunja: `http://localhost:8080/vikunja`
- Health: `http://localhost:8080/healthz`
