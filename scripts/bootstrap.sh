#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Bootstrap started"

if [[ ! -f "${ROOT_DIR}/.env" ]]; then
  cp "${ROOT_DIR}/templates/.env.example" "${ROOT_DIR}/.env"
  log "Generated .env from template"

  if [[ -t 0 ]]; then
    read -r -p "Mattermost bot token (optional, enter to skip): " mm_token || true
    read -r -p "Vikunja API token (optional, enter to skip): " vk_token || true
    if [[ -n "${mm_token:-}" ]]; then sed -i "s|^MATTERMOST_BOT_TOKEN=.*|MATTERMOST_BOT_TOKEN=${mm_token}|" "${ROOT_DIR}/.env"; fi
    if [[ -n "${vk_token:-}" ]]; then sed -i "s|^VIKUNJA_TOKEN=.*|VIKUNJA_TOKEN=${vk_token}|" "${ROOT_DIR}/.env"; fi
  fi
fi

load_env
PROFILE="${COMPOSE_PROFILES:-minimal}"

if [[ "${SKIP_COMPOSE:-0}" != "1" ]]; then
  log "Starting compose profile=${PROFILE}"
  (cd "$ROOT_DIR" && docker compose --profile "$PROFILE" up -d) || warn "compose up failed; continuing with seed attempts"
else
  warn "SKIP_COMPOSE=1 set; skipping compose startup"
fi

"${ROOT_DIR}/scripts/seed-vikunja.sh" || warn "Vikunja seed failed"
"${ROOT_DIR}/scripts/seed-mattermost.sh" || warn "Mattermost seed failed"
"${ROOT_DIR}/scripts/seed-openclaw-cron.sh" || warn "OpenClaw cron seed failed"
"${ROOT_DIR}/scripts/seed-automations.sh" || warn "Automation seed failed"

log "Bootstrap finished"
