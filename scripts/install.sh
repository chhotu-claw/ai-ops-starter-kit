#!/usr/bin/env bash
set -euo pipefail

# AI Ops Starter Kit remote installer (no git clone)

BASE_URL_DEFAULT="https://aiops.chhotu.online"
MANIFEST_PATH_DEFAULT="/releases/latest.json"
INSTALL_DIR_DEFAULT="$HOME/ai-ops-starter-kit"

YES=0
VERSION="latest"
INSTALL_DIR="$INSTALL_DIR_DEFAULT"
DOMAIN=""
PRESET="solo-founder"
TIMEZONE="Asia/Dubai"
PORT="8080"
ADMIN_EMAIL=""
BASE_URL="$BASE_URL_DEFAULT"
RELEASE_URL=""
CHECKSUM_URL=""
SKIP_BOOTSTRAP=0

log(){ echo "[installer] $*"; }
warn(){ echo "[installer][warn] $*"; }
err(){ echo "[installer][error] $*" >&2; }

usage(){
  cat <<EOF
Usage: install.sh [options]
  --yes                     Non-interactive mode
  --version <tag>           Release version (default: latest)
  --install-dir <path>      Install directory (default: $INSTALL_DIR_DEFAULT)
  --domain <domain>         Public domain/site host
  --preset <name>           Preset: solo-founder|small-agency|hiring-pipeline
  --timezone <tz>           IANA timezone (default: Asia/Dubai)
  --port <port>             Caddy HTTP port (default: 8080)
  --admin-email <email>     Admin contact email
  --base-url <url>          Artifact host base URL (default: $BASE_URL_DEFAULT)
  --release-url <url>       Direct tarball URL override
  --checksum-url <url>      Direct checksum URL override
  --skip-bootstrap          Only install files and env; skip bootstrap
  -h, --help                Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --install-dir) INSTALL_DIR="${2:-}"; shift 2 ;;
    --domain) DOMAIN="${2:-}"; shift 2 ;;
    --preset) PRESET="${2:-}"; shift 2 ;;
    --timezone) TIMEZONE="${2:-}"; shift 2 ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --admin-email) ADMIN_EMAIL="${2:-}"; shift 2 ;;
    --base-url) BASE_URL="${2:-}"; shift 2 ;;
    --release-url) RELEASE_URL="${2:-}"; shift 2 ;;
    --checksum-url) CHECKSUM_URL="${2:-}"; shift 2 ;;
    --skip-bootstrap) SKIP_BOOTSTRAP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

check_prereqs(){
  local missing=0
  for c in curl tar sha256sum awk sed; do
    command -v "$c" >/dev/null 2>&1 || { err "Missing prerequisite: $c"; missing=1; }
  done
  command -v docker >/dev/null 2>&1 || { err "Missing prerequisite: docker"; missing=1; }
  command -v docker compose >/dev/null 2>&1 || warn "docker compose plugin not found in PATH; compose commands may fail"
  [[ "$missing" -eq 0 ]] || exit 1
}

prompt_if_needed(){
  [[ "$YES" -eq 1 ]] && return 0

  [[ -n "$DOMAIN" ]] || read -r -p "Domain/host (blank for localhost): " DOMAIN
  read -r -p "Preset [solo-founder|small-agency|hiring-pipeline] ($PRESET): " _preset || true
  [[ -n "${_preset:-}" ]] && PRESET="$_preset"
  read -r -p "Timezone ($TIMEZONE): " _tz || true
  [[ -n "${_tz:-}" ]] && TIMEZONE="$_tz"
  read -r -p "HTTP port ($PORT): " _port || true
  [[ -n "${_port:-}" ]] && PORT="$_port"
  read -r -p "Admin email (optional): " _mail || true
  [[ -n "${_mail:-}" ]] && ADMIN_EMAIL="$_mail"
}

resolve_artifacts(){
  if [[ -n "$RELEASE_URL" && -n "$CHECKSUM_URL" ]]; then
    return 0
  fi

  if [[ "$VERSION" == "latest" ]]; then
    local manifest_url="${BASE_URL}${MANIFEST_PATH_DEFAULT}"
    log "Fetching release manifest: $manifest_url"
    local manifest
    manifest=$(curl -fsSL "$manifest_url")
    RELEASE_URL=$(echo "$manifest" | awk -F'"' '/"tarball_url"/{print $4; exit}')
    CHECKSUM_URL=$(echo "$manifest" | awk -F'"' '/"checksum_url"/{print $4; exit}')
    VERSION=$(echo "$manifest" | awk -F'"' '/"version"/{print $4; exit}')
  else
    RELEASE_URL="${BASE_URL}/releases/ai-ops-starter-kit-${VERSION}.tar.gz"
    CHECKSUM_URL="${BASE_URL}/releases/ai-ops-starter-kit-${VERSION}.tar.gz.sha256"
  fi

  [[ -n "$RELEASE_URL" && -n "$CHECKSUM_URL" ]] || { err "Could not resolve release artifact URLs"; exit 1; }
}

download_and_verify(){
  local tmpdir
  tmpdir=$(mktemp -d)
  TAR_PATH="$tmpdir/release.tar.gz"
  SUM_PATH="$tmpdir/release.sha256"

  log "Downloading release: $RELEASE_URL"
  curl -fsSL "$RELEASE_URL" -o "$TAR_PATH"
  log "Downloading checksum: $CHECKSUM_URL"
  curl -fsSL "$CHECKSUM_URL" -o "$SUM_PATH"

  local expected actual
  expected=$(awk '{print $1}' "$SUM_PATH" | head -1)
  actual=$(sha256sum "$TAR_PATH" | awk '{print $1}')

  [[ -n "$expected" ]] || { err "Checksum file invalid"; exit 1; }
  [[ "$expected" == "$actual" ]] || { err "Checksum mismatch"; exit 1; }
  log "Checksum verified"
}

extract_release(){
  mkdir -p "$INSTALL_DIR"
  log "Extracting to $INSTALL_DIR"
  tar -xzf "$TAR_PATH" -C "$INSTALL_DIR" --strip-components=1
}

generate_env(){
  local envf="$INSTALL_DIR/.env"
  local env_template="$INSTALL_DIR/templates/.env.example"
  [[ -f "$env_template" ]] || { err "Missing env template: $env_template"; exit 1; }

  cp "$env_template" "$envf"
  sed -i "s|^TZ=.*|TZ=${TIMEZONE}|" "$envf" || true
  sed -i "s|^CADDY_HTTP_PORT=.*|CADDY_HTTP_PORT=${PORT}|" "$envf" || true
  sed -i "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=minimal|" "$envf" || true

  if [[ -n "$DOMAIN" ]]; then
    sed -i "s|^MATTERMOST_SITEURL=.*|MATTERMOST_SITEURL=http://${DOMAIN}:${PORT}|" "$envf" || true
    sed -i "s|^VIKUNJA_PUBLIC_URL=.*|VIKUNJA_PUBLIC_URL=http://${DOMAIN}:${PORT}/vikunja|" "$envf" || true
  fi

  [[ -n "$ADMIN_EMAIL" ]] && echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> "$envf"
  echo "STARTER_KIT_PRESET=${PRESET}" >> "$envf"

  log ".env generated"
}

apply_preset(){
  local preset_file="$INSTALL_DIR/templates/presets/${PRESET}.json"
  local target="$INSTALL_DIR/templates/org.selected.json"
  if [[ -f "$preset_file" ]]; then
    cp "$preset_file" "$target"
    log "Preset applied: $PRESET"
  else
    warn "Preset file not found: $preset_file (continuing with defaults)"
  fi
}

bootstrap_stack(){
  [[ "$SKIP_BOOTSTRAP" -eq 1 ]] && { warn "--skip-bootstrap set; skipping bootstrap"; return 0; }
  log "Running bootstrap flow"
  (cd "$INSTALL_DIR" && SKIP_COMPOSE=0 ./scripts/bootstrap.sh)
}

health_summary(){
  log "Running post-install health checks"
  local ok=1
  (cd "$INSTALL_DIR" && ./scripts/status.sh) || ok=0
  (cd "$INSTALL_DIR" && ./scripts/doctor.sh) || ok=0

  echo
  echo "==== INSTALL SUMMARY ===="
  echo "Version: ${VERSION}"
  echo "Install dir: ${INSTALL_DIR}"
  echo "Preset: ${PRESET}"
  echo "Timezone: ${TIMEZONE}"
  echo "Port: ${PORT}"
  [[ -n "$DOMAIN" ]] && echo "Domain: ${DOMAIN}"
  [[ -n "$ADMIN_EMAIL" ]] && echo "Admin email: ${ADMIN_EMAIL}"
  if [[ "$ok" -eq 1 ]]; then
    echo "Health checks: PASS"
  else
    echo "Health checks: WARN (inspect logs/status)"
  fi
}

main(){
  check_prereqs
  prompt_if_needed
  resolve_artifacts
  download_and_verify
  extract_release
  generate_env
  apply_preset
  bootstrap_stack
  health_summary
}

main
