#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

log(){ echo "[starter-kit] $*"; }
warn(){ echo "[starter-kit][warn] $*"; }

load_env(){
  [[ -f "$ENV_FILE" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      # strip optional surrounding quotes
      val="${val%\"}"; val="${val#\"}"
      val="${val%\'}"; val="${val#\'}"
      export "$key=$val"
    fi
  done < "$ENV_FILE"
}

require_cmd(){ command -v "$1" >/dev/null 2>&1 || { warn "missing command: $1"; return 1; }; }

api_get(){
  local url="$1" token="$2"
  curl -fsS -H "Authorization: Bearer ${token}" "$url"
}

api_post(){
  local url="$1" token="$2" body="$3"
  curl -fsS -X POST -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" -d "$body" "$url"
}
