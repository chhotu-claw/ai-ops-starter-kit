#!/usr/bin/env bash
set -euo pipefail

# AI Ops Starter Kit — One-Command Installer
# https://github.com/chhotu-claw/ai-ops-starter-kit

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

log(){ echo -e "${BLUE}[installer]${NC} $*"; }
ok(){ echo -e "${GREEN}[✓]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
err(){ echo -e "${RED}[✗]${NC} $*"; }
info(){ echo -e "${CYAN}[i]${NC} $*"; }

usage(){
  cat <<EOF
${BOLD}AI Ops Starter Kit — One-Command Installer${NC}

${BOLD}Usage:${NC}
  $0 [options]

${BOLD}Options:${NC}
  --yes                    Run with defaults (non-interactive)
  --skip-bootstrap         Only install files, skip docker bootstrap
  --release-url <url>      Direct tarball URL override
  --checksum-url <url>     Direct checksum URL override
  --help, -h               Show this help

${BOLD}Environment Variables:${NC}
  CADDY_HTTP_PORT         HTTP port (default: 8080)
  DOMAIN                  Public domain (blank for localhost)
  PRESET                  Preset: solo-founder|small-agency|hiring-pipeline
  TIMEZONE                Timezone (default: Asia/Dubai)
  ADMIN_EMAIL             Admin email (optional)
  YES                     Non-interactive mode (1 = skip prompts)

${BOLD}Examples:${NC}
  # Interactive install
  $0

  # Fully automated
  YES=1 DOMAIN=aiops.example.com PRESET=solo-founder $0

  # Skip docker bootstrap (files only)
  $0 --skip-bootstrap
EOF
  exit 0
}

# Defaults
VERSION="${VERSION:-latest}"
BASE_URL_DEFAULT="https://aiops.chhotu.online"
MANIFEST_PATH_DEFAULT="/releases/latest.json"
INSTALL_DIR_DEFAULT="${HOME}/ai-ops-starter-kit"
PRESET_DEFAULT="solo-founder"
TIMEZONE_DEFAULT="Asia/Dubai"
PORT_DEFAULT="8080"

YES=0
SKIP_BOOTSTRAP=0
RELEASE_URL=""
CHECKSUM_URL=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --skip-bootstrap) SKIP_BOOTSTRAP=1; shift ;;
    --release-url) RELEASE_URL="$2"; shift 2 ;;
    --checksum-url) CHECKSUM_URL="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) err "Unknown option: $1"; echo "Run with --help for usage"; exit 1 ;;
  esac
done

# Prompt for missing values
prompt_if_needed(){
  [[ "$YES" -eq 1 ]] && return 0

  echo
  echo -e "${BOLD}AI Ops Starter Kit Setup${NC}"
  echo -e "${CYAN}─────────────────────${NC}"
  echo

  [[ -n "$DOMAIN" ]] || read -r -p "Domain/host (blank for localhost): " DOMAIN
  read -r -p "Preset [solo-founder|small-agency|hiring-pipeline] ($PRESET): " _preset || true
  [[ -n "${_preset:-}" ]] && PRESET="$_preset"
  read -r -p "Timezone ($TIMEZONE): " _tz || true
  [[ -n "${_tz:-}" ]] && TIMEZONE="$_tz"
  read -r -p "HTTP port ($PORT): " _port || true
  [[ -n "${_port:-}" ]] && PORT="$_port"
  read -r -p "Admin email (optional): " _mail || true
  [[ -n "${_mail:-}" ]] && ADMIN_EMAIL="$_mail"

  echo
}

# Check prerequisites
check_prereqs(){
  local missing=0
  for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || { err "Missing prerequisite: $cmd"; missing=1; }
  done

  command -v docker >/dev/null 2>&1 || { err "Docker is required but not installed."; info "Install Docker Desktop (macOS/Windows) or Docker Engine (Linux)"; missing=1; }

  if command -v docker >/dev/null 2>&1; then
    docker info >/dev/null 2>&1 || { warn "Docker is installed but daemon is not running."; info "Start Docker Desktop or run: sudo systemctl start docker"; }
  fi

  [[ "$missing" -eq 0 ]] || { echo; err "Please fix the issues above and re-run."; exit 1; }
}

# Resolve artifact URLs
resolve_artifacts(){
  if [[ -n "$RELEASE_URL" && -n "$CHECKSUM_URL" ]]; then
    return 0
  fi

  if [[ "$VERSION" == "latest" ]]; then
    local manifest_url="${BASE_URL}${MANIFEST_PATH_DEFAULT}"
    log "Fetching release manifest: $manifest_url"
    local manifest
    manifest=$(curl -fsSL "$manifest_url") || { err "Failed to fetch manifest"; exit 1; }
    RELEASE_URL=$(echo "$manifest" | grep -o '"tarball_url":"[^"]*"' | cut -d'"' -f4)
    CHECKSUM_URL=$(echo "$manifest" | grep -o '"checksum_url":"[^"]*"' | cut -d'"' -f4)
    VERSION=$(echo "$manifest" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  else
    RELEASE_URL="${BASE_URL}/releases/ai-ops-starter-kit-${VERSION}.tar.gz"
    CHECKSUM_URL="${BASE_URL}/releases/ai-ops-starter-kit-${VERSION}.tar.gz.sha256"
  fi

  [[ -n "$RELEASE_URL" && -n "$CHECKSUM_URL" ]] || { err "Could not resolve release artifacts"; exit 1; }
}

# Download and verify
download_and_verify(){
  log "Downloading release: $RELEASE_URL"
  curl -fsSL "$RELEASE_URL" -o "${INSTALL_DIR}.tar.gz" || { err "Download failed"; exit 1; }

  log "Downloading checksum: $CHECKSUM_URL"
  curl -fsSL "$CHECKSUM_URL" -o "${INSTALL_DIR}.tar.gz.sha256" || { err "Checksum download failed"; exit 1; }

  log "Verifying checksum..."
  local expected actual
  expected=$(grep -oE '^[a-f0-9]+' "${INSTALL_DIR}.tar.gz.sha256" | head -1)
  actual=$(sha256sum "${INSTALL_DIR}.tar.gz" | cut -d' ' -f1)

  if [[ "$expected" == "$actual" ]]; then
    ok "Checksum verified"
  else
    err "Checksum mismatch!"
    info "Expected: $expected"
    info "Got:      $actual"
    exit 1
  fi
}

# Extract release
extract_release(){
  log "Extracting to $INSTALL_DIR"

  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"

  tar -xzf "${INSTALL_DIR}.tar.gz" -C "$INSTALL_DIR" --strip-components=1 || { err "Extraction failed"; exit 1; }

  rm -f "${INSTALL_DIR}.tar.gz" "${INSTALL_DIR}.tar.gz.sha256"

  ok "Extracted successfully"
}

# Generate .env
generate_env(){
  local env_template="$INSTALL_DIR/templates/.env.example"
  local envf="$INSTALL_DIR/.env"

  if [[ ! -f "$env_template" ]]; then
    err "Missing template: $env_template"
    exit 1
  fi

  # macOS/BSD sed compatibility
  local sed_i_arg="-i ''"
  if [[ "$(uname)" == "Linux" ]]; then
    sed_i_arg="-i"
  fi

  sed $sed_i_arg "s|%%PORT%%|${PORT}|g" "$env_template"
  sed $sed_i_arg "s|%%TIMEZONE%%|${TIMEZONE}|g" "$env_template"
  [[ -n "$ADMIN_EMAIL" ]] && sed $sed_i_arg "s|%%ADMIN_EMAIL%%|${ADMIN_EMAIL}|g" "$env_template" || true

  mv "$env_template" "$envf"
  ok ".env generated"
}

# Apply preset
apply_preset(){
  local preset_file="$INSTALL_DIR/templates/presets/${PRESET}.json"
  local target="$INSTALL_DIR/templates/org.selected.json"

  if [[ -f "$preset_file" ]]; then
    cp "$preset_file" "$target"
    ok "Preset applied: ${PRESET}"
  else
    warn "Preset file not found: $preset_file"
    info "Using defaults"
  fi
}

# Bootstrap stack
bootstrap_stack(){
  if [[ "$SKIP_BOOTSTRAP" -eq 1 ]]; then
    warn "--skip-bootstrap set; skipping bootstrap"
    return 0
  fi

  log "Running bootstrap (docker compose up)..."
  echo

  if ! docker info >/dev/null 2>&1; then
    err "Docker daemon is not running!"
    info "Start Docker and re-run: cd $INSTALL_DIR && make bootstrap"
    echo
    return 1
  fi

  if ! (cd "$INSTALL_DIR" && SKIP_COMPOSE=0 ./scripts/bootstrap.sh); then
    warn "Bootstrap encountered issues"
    info "Check logs with: cd $INSTALL_DIR && docker compose logs"
    echo
  else
    ok "Bootstrap completed"
  fi
}

# Health summary
health_summary(){
  log "Running health checks..."

  local status="PASS"
  local notes=()

  # Check docker
  if docker info >/dev/null 2>&1; then
    if (cd "$INSTALL_DIR" && ./scripts/status.sh >/dev/null 2>&1); then
      ok "Services running"
    else
      warn "Some services may need attention"
      status="WARN"
      notes+=("Check status: cd $INSTALL_DIR && make status")
    fi
  else
    status="FAIL"
    notes+=("Docker not running")
  fi

  echo
  echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}                     INSTALL COMPLETE${NC}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
  echo
  echo -e "  ${GREEN}Version:${NC}      $VERSION"
  echo -e "  ${GREEN}Install dir:${NC}  $INSTALL_DIR"
  echo -e "  ${GREEN}Preset:${NC}       $PRESET"
  echo -e "  ${GREEN}Timezone:${NC}     $TIMEZONE"
  echo -e "  ${GREEN}Port:${NC}         $PORT"
  [[ -n "$DOMAIN" ]] && echo -e "  ${GREEN}Domain:${NC}      $DOMAIN"
  [[ -n "$ADMIN_EMAIL" ]] && echo -e "  ${GREEN}Admin email:${NC} $ADMIN_EMAIL"
  echo
  echo -e "  ${BOLD}Status:${NC}       $status"
  echo

  if [[ ${#notes[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Notes:${NC}"
    for note in "${notes[@]}"; do
      echo -e "  • $note"
    done
    echo
  fi

  echo -e "${CYAN}Next steps:${NC}"
  echo -e "  • ${BOLD}cd $INSTALL_DIR${NC}"
  echo -e "  • ${BOLD}make status${NC}     — check service status"
  echo -e "  • ${BOLD}make doctor${NC}      — run health checks"
  echo -e "  • ${BOLD}make logs${NC}       — view container logs"
  echo
  echo -e "${CYAN}Useful commands:${NC}"
  echo -e "  • ${BOLD}make up${NC}         — start services"
  echo -e "  • ${BOLD}make down${NC}       — stop services"
  echo -e "  • ${BOLD}make backup${NC}     — backup data"
  echo
  echo -e "${YELLOW}Rollback:${NC}  Run ${BOLD}$INSTALL_DIR/scripts/rollback.sh${NC} to remove everything"
  echo
}

# Main
main(){
  echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║          AI Ops Starter Kit — One-Command Installer          ║${NC}"
  echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo

  check_prereqs
  prompt_if_needed

  # Apply defaults
  PRESET="${PRESET:-$PRESET_DEFAULT}"
  TIMEZONE="${TIMEZONE:-$TIMEZONE_DEFAULT}"
  PORT="${PORT:-$PORT_DEFAULT}"
  INSTALL_DIR="${INSTALL_DIR:-$INSTALL_DIR_DEFAULT}"

  resolve_artifacts
  download_and_verify
  extract_release
  generate_env
  apply_preset
  bootstrap_stack
  health_summary
}

main "$@"
