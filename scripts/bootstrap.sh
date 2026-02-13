#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[ai-ops-starter-kit] bootstrap: ensure .env, then docker compose --profile ${COMPOSE_PROFILES:-minimal} up -d"
