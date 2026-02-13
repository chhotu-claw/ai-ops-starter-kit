#!/usr/bin/env bash
set -euo pipefail

# Build and package release artifacts for installer consumption

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
RELEASE_DIR="${ROOT_DIR}/releases"
VERSION_FILE="${ROOT_DIR}/VERSION"

usage(){
  cat <<EOF
Usage: package-release.sh [options]
  --version <ver>         Release version (auto-detect from VERSION file if not set)
  --output <dir>          Output directory for artifacts (default: ./releases)
  --publish               Copy artifacts to publish directory (e.g., webroot)
  --base-url <url>        Base URL for artifact hosting (default: https://aiops.chhotu.online)
  -h, --help              Show help
EOF
}

VERSION=""
OUTPUT_DIR="$RELEASE_DIR"
PUBLISH=0
BASE_URL="https://aiops.chhotu.online"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --output) OUTPUT_DIR="${2:-}"; shift 2 ;;
    --publish) PUBLISH=1; shift ;;
    --base-url) BASE_URL="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

log(){ echo "[release] $*"; }
warn(){ echo "[release][warn] $*"; }
err(){ echo "[release][error] $*" >&2; }

# Auto-detect version
if [[ -z "$VERSION" ]]; then
  if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
  else
    VERSION="0.1.0"
    warn "No VERSION file found; using default: $VERSION"
  fi
fi

# Ensure output dir
mkdir -p "$OUTPUT_DIR"

TAR_NAME="ai-ops-starter-kit-${VERSION}.tar.gz"
SUM_NAME="${TAR_NAME}.sha256"
MANIFEST_NAME="latest.json"
MANIFEST_PATH="${OUTPUT_DIR}/${MANIFEST_NAME}"

# Build tarball (exclude .git, .env, node_modules, docker artifacts)
TAR_PATH="${OUTPUT_DIR}/${TAR_NAME}"
log "Building tarball: $TAR_NAME"
tar -czf "$TAR_PATH" \
  -C "$ROOT_DIR" \
  --exclude='.git' \
  --exclude='.env' \
  --exclude='node_modules' \
  --exclude='.venv' \
  --exclude='venv' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  --exclude='releases' \
  --exclude='reports' \
  .

# Generate SHA256SUMS
SUM_PATH="${OUTPUT_DIR}/${SUM_NAME}"
log "Generating checksum: $SUM_NAME"
sha256sum "$TAR_PATH" | awk '{print $1"  "FILENAME}' | sed "s|${OUTPUT_DIR}/||" > "$SUM_PATH"

# Generate manifest (latest.json)
log "Generating manifest: $MANIFEST_NAME"
cat > "$MANIFEST_PATH" <<EOF
{
  "version": "${VERSION}",
  "tarball_url": "${BASE_URL}/releases/${TAR_NAME}",
  "checksum_url": "${BASE_URL}/releases/${SUM_NAME}",
  "released_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

log "Artifacts packaged:"
ls -la "$OUTPUT_DIR"

# Publish step (copy to webroot if configured)
if [[ "$PUBLISH" == "1" ]]; then
  : "${PUBLISH_DIR:-}"
  if [[ -z "$PUBLISH_DIR" ]]; then
    warn "PUBLISH_DIR not set; skipping publish. Set PUBLISH_DIR to webroot path."
  else
    log "Publishing to $PUBLISH_DIR"
    mkdir -p "$PUBLISH_DIR"
    cp "$TAR_PATH" "$PUBLISH_DIR/"
    cp "$SUM_PATH" "$PUBLISH_DIR/"
    cp "$MANIFEST_PATH" "$PUBLISH_DIR/"
    log "Published artifacts:"
    ls -la "$PUBLISH_DIR"
  fi
fi

log "Release ${VERSION} packaged successfully"
