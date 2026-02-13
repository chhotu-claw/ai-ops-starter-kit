#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

require_cmd jq >/dev/null || { warn "jq missing"; exit 1; }

CONFIG_PATH="${1:-${ROOT_DIR}/templates/org.sample.json}"
DRY_RUN="${DRY_RUN:-0}"

[[ -f "$CONFIG_PATH" ]] || { echo "Config not found: $CONFIG_PATH"; exit 1; }
log "Applying config: $CONFIG_PATH (dry_run=$DRY_RUN)"

run(){
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] $*"
  else
    eval "$*"
  fi
}

# ---------- Mattermost ----------
apply_mattermost(){
  [[ -z "${MATTERMOST_URL:-}" || -z "${MATTERMOST_BOT_TOKEN:-}" ]] && { warn "Mattermost env missing; skip"; return 0; }

  local team_name team_display team_type team_json team_id
  team_name=$(jq -r '.mattermost.team.name' "$CONFIG_PATH")
  team_display=$(jq -r '.mattermost.team.display_name' "$CONFIG_PATH")
  team_type=$(jq -r '.mattermost.team.type' "$CONFIG_PATH")

  team_json=$(curl -fsS -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" "${MATTERMOST_URL}/api/v4/teams/name/${team_name}" || true)
  if [[ -z "$team_json" || "$team_json" == *"status_code"* ]]; then
    run "curl -fsS -X POST -H 'Authorization: Bearer ${MATTERMOST_BOT_TOKEN}' -H 'Content-Type: application/json' -d '{\"name\":\"${team_name}\",\"display_name\":\"${team_display}\",\"type\":\"${team_type}\"}' '${MATTERMOST_URL}/api/v4/teams' >/tmp/aiops_mm_team.json"
    if [[ "$DRY_RUN" != "1" ]]; then
      team_json=$(cat /tmp/aiops_mm_team.json)
    fi
    log "Mattermost team ensured: ${team_name}"
  else
    log "Mattermost team exists: ${team_name}"
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    team_id='<team-id>'
  else
    team_id=$(echo "$team_json" | jq -r '.id')
  fi

  jq -c '.mattermost.channels[]' "$CONFIG_PATH" | while read -r ch; do
    local name disp typ purpose exists
    name=$(echo "$ch" | jq -r '.name')
    disp=$(echo "$ch" | jq -r '.display_name')
    typ=$(echo "$ch" | jq -r '.type')
    purpose=$(echo "$ch" | jq -r '.purpose // ""')

    exists=$(curl -fsS -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" "${MATTERMOST_URL}/api/v4/teams/${team_id}/channels/name/${name}" || true)
    if [[ -n "$exists" && "$exists" != *"status_code"* ]]; then
      log "Mattermost channel exists: ${name}"
      continue
    fi

    run "curl -fsS -X POST -H 'Authorization: Bearer ${MATTERMOST_BOT_TOKEN}' -H 'Content-Type: application/json' -d '{\"team_id\":\"${team_id}\",\"name\":\"${name}\",\"display_name\":\"${disp}\",\"type\":\"${typ}\",\"purpose\":\"${purpose}\"}' '${MATTERMOST_URL}/api/v4/channels' >/dev/null"
    log "Mattermost channel ensured: ${name}"
  done

  # Webhooks (best-effort; requires perms)
  jq -c '.mattermost.webhooks[]?' "$CONFIG_PATH" | while read -r wh; do
    local display_name channel_name desc channel_id existing hooks
    display_name=$(echo "$wh" | jq -r '.display_name')
    channel_name=$(echo "$wh" | jq -r '.channel')
    desc=$(echo "$wh" | jq -r '.description // ""')

    if [[ "$DRY_RUN" == "1" ]]; then
      log "Mattermost webhook ensured: ${display_name} -> ${channel_name}"
      continue
    fi

    channel_id=$(curl -fsS -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" "${MATTERMOST_URL}/api/v4/teams/${team_id}/channels/name/${channel_name}" | jq -r '.id')
    hooks=$(curl -fsS -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" "${MATTERMOST_URL}/api/v4/hooks/incoming" || echo '[]')
    existing=$(echo "$hooks" | jq -r --arg n "$display_name" --arg c "$channel_id" '.[] | select(.display_name==$n and .channel_id==$c) | .id' | head -1)

    if [[ -n "$existing" ]]; then
      log "Mattermost webhook exists: ${display_name}"
    else
      curl -fsS -X POST -H "Authorization: Bearer ${MATTERMOST_BOT_TOKEN}" -H "Content-Type: application/json" \
        -d "{\"channel_id\":\"${channel_id}\",\"display_name\":\"${display_name}\",\"description\":\"${desc}\"}" \
        "${MATTERMOST_URL}/api/v4/hooks/incoming" >/dev/null || warn "Webhook create failed: ${display_name}"
      log "Mattermost webhook ensured: ${display_name}"
    fi
  done
}

# ---------- Vikunja ----------
apply_vikunja(){
  [[ -z "${VIKUNJA_URL:-}" || -z "${VIKUNJA_TOKEN:-}" ]] && { warn "Vikunja env missing; skip"; return 0; }

  local proj_title proj_desc projects proj_id created
  proj_title=$(jq -r '.vikunja.project.title' "$CONFIG_PATH")
  proj_desc=$(jq -r '.vikunja.project.description' "$CONFIG_PATH")

  projects=$(curl -fsS -H "Authorization: Bearer ${VIKUNJA_TOKEN}" "${VIKUNJA_URL}/api/v1/projects" || echo '[]')
  proj_id=$(echo "$projects" | jq -r --arg t "$proj_title" '.[] | select(.title==$t) | .id' | head -1)
  if [[ -z "$proj_id" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      proj_id='<project-id>'
    else
      created=$(curl -fsS -X PUT -H "Authorization: Bearer ${VIKUNJA_TOKEN}" -H "Content-Type: application/json" -d "{\"title\":\"${proj_title}\",\"description\":\"${proj_desc}\"}" "${VIKUNJA_URL}/api/v1/projects")
      proj_id=$(echo "$created" | jq -r '.id')
    fi
    log "Vikunja project ensured: ${proj_title}"
  else
    log "Vikunja project exists: ${proj_title}"
  fi

  local labels
  labels=$(curl -fsS -H "Authorization: Bearer ${VIKUNJA_TOKEN}" "${VIKUNJA_URL}/api/v1/labels" || echo '[]')
  jq -c '.vikunja.labels[]' "$CONFIG_PATH" | while read -r lb; do
    local title color found
    title=$(echo "$lb" | jq -r '.title')
    color=$(echo "$lb" | jq -r '.hex_color')
    found=$(echo "$labels" | jq -r --arg t "$title" '.[] | select(.title==$t) | .id' | head -1)
    if [[ -n "$found" ]]; then
      log "Vikunja label exists: ${title}"
      continue
    fi
    run "curl -fsS -X PUT -H 'Authorization: Bearer ${VIKUNJA_TOKEN}' -H 'Content-Type: application/json' -d '{\"title\":\"${title}\",\"hex_color\":\"${color}\"}' '${VIKUNJA_URL}/api/v1/labels' >/dev/null"
    log "Vikunja label ensured: ${title}"
  done

  # Templates represented as idempotent TASK TEMPLATE stubs in project
  local tasks
  tasks=$(curl -fsS -H "Authorization: Bearer ${VIKUNJA_TOKEN}" "${VIKUNJA_URL}/api/v1/projects/${proj_id}/tasks" || echo '[]')
  jq -c '.vikunja.templates[]?' "$CONFIG_PATH" | while read -r t; do
    local name desc title exists
    name=$(echo "$t" | jq -r '.name')
    desc=$(echo "$t" | jq -r '.description')
    title="TEMPLATE: ${name}"
    exists=$(echo "$tasks" | jq -r --arg title "$title" '.[] | select(.title==$title) | .id' | head -1)
    if [[ -n "$exists" ]]; then
      log "Vikunja template stub exists: ${name}"
      continue
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
      log "[dry-run] create Vikunja template stub: ${name}"
    else
      body=$(jq -n --arg title "$title" --arg description "$desc" --argjson project_id "$proj_id" '{title:$title, description:$description, done:false, project_id:$project_id}')
      curl -fsS -X PUT -H "Authorization: Bearer ${VIKUNJA_TOKEN}" -H "Content-Type: application/json" -d "$body" "${VIKUNJA_URL}/api/v1/tasks" >/dev/null
      log "Vikunja template stub ensured: ${name}"
    fi
  done
}

# ---------- OpenClaw cron ----------
apply_openclaw(){
  require_cmd openclaw >/dev/null || { warn "openclaw missing; skip"; return 0; }
  local list
  list=$(openclaw cron list 2>/dev/null || true)

  jq -c '.openclaw.cron_jobs[]' "$CONFIG_PATH" | while read -r job; do
    local name every agent session message
    name=$(echo "$job" | jq -r '.name')
    every=$(echo "$job" | jq -r '.schedule.every // empty')
    agent=$(echo "$job" | jq -r '.agent')
    session=$(echo "$job" | jq -r '.session')
    message=$(echo "$job" | jq -r '.message')

    if echo "$list" | grep -q "$name"; then
      log "OpenClaw cron exists: ${name}"
      continue
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
      log "[dry-run] create cron ${name}"
    else
      openclaw cron add --name "$name" --every "$every" --session "$session" --agent "$agent" --no-deliver --message "$message" >/dev/null
      log "OpenClaw cron ensured: ${name}"
    fi
  done
}

apply_mattermost
apply_vikunja
apply_openclaw

log "Config apply complete"
