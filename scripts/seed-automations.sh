#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

seed="${ROOT_DIR}/templates/seeds/automations.json"
out_dir="${ROOT_DIR}/automation/generated"
mkdir -p "$out_dir"

cp "$seed" "${out_dir}/automation-index.json"
cat > "${out_dir}/dispatcher.json" <<'JSON'
{ "service": "dispatcher", "enabled": true, "mode": "deterministic-first" }
JSON
cat > "${out_dir}/watcher.json" <<'JSON'
{ "service": "watcher", "enabled": true, "mode": "deterministic-first" }
JSON

echo "[starter-kit] automation seeds generated in automation/generated/"
