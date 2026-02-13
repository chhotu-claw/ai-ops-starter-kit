#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

[[ -z "${MATTERMOST_URL:-}" || -z "${MATTERMOST_BOT_TOKEN:-}" ]] && { warn "MATTERMOST_URL or MATTERMOST_BOT_TOKEN missing; skipping Mattermost seed"; exit 0; }
require_cmd jq >/dev/null || { warn "jq missing; skipping Mattermost seed"; exit 0; }

seed="${ROOT_DIR}/templates/seeds/mattermost.json"
team_name=$(jq -r '.team.name' "$seed")
team_display=$(jq -r '.team.display_name' "$seed")
team_type=$(jq -r '.team.type' "$seed")

log "Seeding Mattermost team/channels..."
team_json=$(curl -fsS -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" "${MATTERMOST_URL}/api/v4/teams/name/${team_name}" || true)
if [[ -z "$team_json" ]]; then
  team_json=$(curl -fsS -X POST -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"name\":\"${team_name}\",\"display_name\":\"${team_display}\",\"type\":\"${team_type}\"}" \
    "${MATTERMOST_URL}/api/v4/teams")
fi
team_id=$(echo "$team_json" | jq -r '.id')

jq -c '.channels[]' "$seed" | while read -r ch; do
  name=$(echo "$ch" | jq -r '.name')
  disp=$(echo "$ch" | jq -r '.display_name')
  typ=$(echo "$ch" | jq -r '.type')
  purpose=$(echo "$ch" | jq -r '.purpose')

  exists=$(curl -fsS -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" "${MATTERMOST_URL}/api/v4/teams/${team_id}/channels/name/${name}" || true)
  if [[ -n "$exists" ]]; then
    log "Channel exists: ${name}"
    continue
  fi
  curl -fsS -X POST -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"team_id\":\"${team_id}\",\"name\":\"${name}\",\"display_name\":\"${disp}\",\"type\":\"${typ}\",\"purpose\":\"${purpose}\"}" \
    "${MATTERMOST_URL}/api/v4/channels" >/dev/null
  log "Created channel: ${name}"
done
