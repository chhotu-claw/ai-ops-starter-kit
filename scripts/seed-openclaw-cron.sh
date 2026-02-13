#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

require_cmd openclaw >/dev/null || { warn "openclaw CLI missing; skipping cron seed"; exit 0; }
require_cmd jq >/dev/null || { warn "jq missing; skipping cron seed"; exit 0; }

seed="${ROOT_DIR}/templates/seeds/openclaw-cron.json"
log "Seeding OpenClaw cron jobs..."
list=$(openclaw cron list 2>/dev/null || true)

jq -c '.jobs[]' "$seed" | while read -r job; do
  name=$(echo "$job" | jq -r '.name')
  every=$(echo "$job" | jq -r '.schedule.every // empty')
  agent=$(echo "$job" | jq -r '.agent')
  session=$(echo "$job" | jq -r '.session')
  message=$(echo "$job" | jq -r '.message')

  if echo "$list" | grep -q "$name"; then
    log "Cron exists: ${name}"
    continue
  fi

  openclaw cron add --name "$name" --every "$every" --session "$session" --agent "$agent" --no-deliver --message "$message" >/dev/null
  log "Created cron: ${name}"
done
