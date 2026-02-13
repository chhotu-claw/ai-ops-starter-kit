#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

[[ -z "${VIKUNJA_URL:-}" || -z "${VIKUNJA_TOKEN:-}" ]] && { warn "VIKUNJA_URL or VIKUNJA_TOKEN missing; skipping Vikunja seed"; exit 0; }
require_cmd jq >/dev/null || { warn "jq missing; skipping Vikunja seed"; exit 0; }

seed="${ROOT_DIR}/templates/seeds/vikunja.json"
proj_title=$(jq -r '.project.title' "$seed")
proj_desc=$(jq -r '.project.description' "$seed")

log "Seeding Vikunja project/labels..."
projects=$(curl -fsS -H "Authorization: Bearer ${VIKUNJA_TOKEN}" "${VIKUNJA_URL}/api/v1/projects" || echo "[]")
proj_id=$(echo "$projects" | jq -r --arg t "$proj_title" '.[] | select(.title==$t) | .id' | head -1)
if [[ -z "$proj_id" ]]; then
  created=$(curl -fsS -X PUT -H "Authorization: Bearer ${VIKUNJA_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"title\":\"${proj_title}\",\"description\":\"${proj_desc}\"}" "${VIKUNJA_URL}/api/v1/projects")
  proj_id=$(echo "$created" | jq -r '.id')
  log "Created project: ${proj_title} (#${proj_id})"
else
  log "Project exists: ${proj_title} (#${proj_id})"
fi

labels=$(curl -fsS -H "Authorization: Bearer ${VIKUNJA_TOKEN}" "${VIKUNJA_URL}/api/v1/labels" || echo "[]")
jq -c '.labels[]' "$seed" | while read -r lb; do
  title=$(echo "$lb" | jq -r '.title')
  color=$(echo "$lb" | jq -r '.hex_color')
  found=$(echo "$labels" | jq -r --arg t "$title" '.[] | select(.title==$t) | .id' | head -1)
  if [[ -n "$found" ]]; then
    log "Label exists: ${title}"
    continue
  fi
  curl -fsS -X PUT -H "Authorization: Bearer ${VIKUNJA_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"title\":\"${title}\",\"hex_color\":\"${color}\"}" "${VIKUNJA_URL}/api/v1/labels" >/dev/null
  log "Created label: ${title}"
done
