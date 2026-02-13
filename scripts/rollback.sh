#!/usr/bin/env bash
set -euo pipefail

# AI Ops Starter Kit — One-Click Rollback Script
# Use this to cleanly remove the installation without leaving orphans.

INSTALL_DIR="${INSTALL_DIR:-$HOME/ai-ops-install}"
PROJECT_NAME="${PROJECT_NAME:-aiops}"

echo "=== AI Ops Starter Kit Rollback ==="
echo "Installation directory: $INSTALL_DIR"
echo ""

read -p "Continue with rollback? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Stopping containers..."
docker compose -f "$INSTALL_DIR/docker-compose.yml" down --remove-orphans 2>/dev/null || true

echo "Removing volumes (data will be lost)..."
docker compose -f "$INSTALL_DIR/docker-compose.yml" down -v --remove-orphans 2>/dev/null || true

echo "Removing installation directory..."
rm -rf "$INSTALL_DIR"

echo ""
echo "=== Rollback Complete ==="
echo "Removed: $INSTALL_DIR"
echo "If you want a completely fresh start, also run:"
echo "  docker system prune -a  # WARNING: removes all Docker images/containers"
