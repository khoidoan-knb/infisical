#!/usr/bin/env bash
set -euo pipefail

# Standalone Infisical installer for Linux VPS
# Places Infisical under /opt/infisical and registers it as a systemd service.
# Postgres + Redis are included in the Docker Compose stack — no external DB needed.
# Run as root (or with sudo).

INSTALL_DIR="/opt/infisical"
SERVICE_NAME="infisical"
REPO_URL="https://github.com/khoidoan-knb/infisical.git"

echo "==> Installing Infisical in STANDALONE mode (no external database required)"
echo "    Postgres and Redis will run automatically inside Docker."

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo $0)"
  exit 1
fi

# Ensure Docker is available
if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Please install Docker first:"
  echo "  https://docs.docker.com/engine/install/"
  exit 1
fi

if ! docker compose version &>/dev/null; then
  echo "Docker Compose plugin not found. Install docker-compose-plugin."
  exit 1
fi

# Clone or update the repository
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "==> Updating existing install at $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only || true
else
  echo "==> Cloning repository to $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Create .env if missing
if [[ ! -f .env ]]; then
  echo "==> Creating .env from .env.example"
  cp .env.example .env
  echo ""
  echo "IMPORTANT: Edit $INSTALL_DIR/.env before first start"
  echo "  - Change ENCRYPTION_KEY  (openssl rand -hex 16)"
  echo "  - Change AUTH_SECRET    (openssl rand -base64 32)"
  echo "  - Set SITE_URL to your public URL"
  echo "  - Set a strong POSTGRES_PASSWORD"
  echo ""
fi

# Install systemd unit
UNIT_SRC="$INSTALL_DIR/deploy/vps/infisical.service"
UNIT_DST="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ ! -f "$UNIT_SRC" ]]; then
  echo "Service file not found at $UNIT_SRC"
  exit 1
fi

cp "$UNIT_SRC" "$UNIT_DST"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo ""
echo "==> Standalone service installed successfully."
echo ""
echo "What is included automatically:"
echo "  - Infisical application"
echo "  - PostgreSQL (data stored in Docker volume)"
echo "  - Redis      (data stored in Docker volume)"
echo ""
echo "You do NOT need to install or manage any external database."
echo ""
echo "Next steps:"
echo "  1. Edit config:   nano $INSTALL_DIR/.env"
echo "  2. Start service: systemctl start $SERVICE_NAME"
echo "  3. Check status:  systemctl status $SERVICE_NAME"
echo "  4. View logs:     docker compose -f $INSTALL_DIR/docker-compose.prod.yml logs -f"
echo ""
echo "After start, open http://YOUR_SERVER_IP (or your SITE_URL)"
