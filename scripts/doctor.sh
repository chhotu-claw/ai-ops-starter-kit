#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "[doctor] missing .env"; exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "[doctor] docker not installed"; exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[doctor] docker daemon not reachable"; exit 1
fi

echo "[doctor] compose config validation"
docker compose config >/dev/null

echo "[doctor] container status"
docker compose ps

echo "[doctor] health checks"
curl -fsS "http://localhost:${CADDY_HTTP_PORT:-8080}/healthz" >/dev/null && echo "- caddy: ok" || echo "- caddy: fail"
curl -fsS "http://localhost:${CADDY_HTTP_PORT:-8080}/api/v4/system/ping" >/dev/null && echo "- mattermost via caddy: ok" || echo "- mattermost via caddy: fail"
curl -fsS "http://localhost:${CADDY_HTTP_PORT:-8080}/vikunja/api/v1/info" >/dev/null && echo "- vikunja via caddy: ok" || echo "- vikunja via caddy: fail"
