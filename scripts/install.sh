#!/usr/bin/env bash
set -euo pipefail

# AI Ops Starter Kit — Simple Installer

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log(){ echo -e "${BLUE}[installer]${NC} $*"; }
ok(){ echo -e "${GREEN}[✓]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
err(){ echo -e "${RED}[✗]${NC} $*"; exit 1; }

usage(){
  cat <<EOF
Usage: $0 [--yes]

Installs:
  • Mattermost (chat)
  • Vikunja (tasks)
  • 5 OpenClaw agents
  • Dispatcher cron job

EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in --yes) export YES=1 ;; --help|-h) usage ;; esac; shift
done

check_prereqs(){
  for cmd in git curl docker; do
    command -v "$cmd" >/dev/null || err "Missing: $cmd"
  done
}

clone_repo(){
  log "Cloning ai-ops-starter-kit..."
  rm -rf ~/ai-ops-starter-kit
  git clone https://github.com/chhotu-claw/ai-ops-starter-kit.git ~/ai-ops-starter-kit
  ok "Cloned"
}

copy_agents(){
  log "Copying agents to $HOME/.openclaw/..."
  mkdir -p $HOME/.openclaw

  for ws in ~/ai-ops-starter-kit/workspace-*; do
    name=$(basename "$ws")
    rm -rf "$HOME/.openclaw/$name"
    cp -r "$ws" $HOME/.openclaw/
    ok "Copied $name"
  done
}

setup_infra(){
  log "Setting up Mattermost + Vikunja..."
  cd ~/ai-ops-starter-kit

  cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: mattermost
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: mattermost
    volumes: [postgres_data:/var/lib/postgresql/data]

  mattermost:
    image: mattermost/mattermost-team-edition:11.3.0
    depends_on: [postgres]
    environment:
      MM_SQLSETTINGS_DATASTORE: postgres://mattermost:changeme@postgres:5432/mattermost?sslmode=disable
      MM_SERVICESETTINGS_SITEURL: http://localhost:8065
    ports: ["8065:8065"]
    volumes: [mattermost_data:/mattermost/data]

  vikunja:
    image: vikunja/vikunja
    depends_on: [postgres]
    environment:
      VIKUNJA_SERVICE_DATABASEHOST: postgres
      VIKUNJA_SERVICE_DATABASEPASSWORD: changeme
    ports: ["3456:3456"]

volumes:
  postgres_data:
  mattermost_data:
EOF

  docker compose up -d
  ok "Mattermost (8065) + Vikunja (3456) started"
}

setup_crons(){
  log "Setting up dispatcher cron..."
  mkdir -p ~/ai-ops-starter-kit/crons

  cat > ~/ai-ops-starter-kit/crons/dispatcher << 'EOF'
* * * * * cd ~/ai-ops-starter-kit && ./scripts/dispatcher.sh
EOF

  crontab ~/ai-ops-starter-kit/crons/dispatcher 2>/dev/null || true
  ok "Dispatcher cron installed"
}

main(){
  echo "AI Ops Starter Kit"
  echo "================="
  echo
  check_prereqs
  clone_repo
  copy_agents
  setup_infra
  setup_crons
  echo
  echo "Done!"
  echo "Agents: $HOME/.openclaw/workspace-*"
  echo "Mattermost: http://localhost:8065"
  echo "Vikunja: http://localhost:3456"
}

main
