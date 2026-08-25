#!/usr/bin/env bash
set -euo pipefail

# Simple installer: places Infisical under /opt/infisical and registers it as a systemd service.
# Run as root (or with sudo).

INSTALL_DIR="/opt/infisical"
SERVICE_NAME="infisical"
REPO_URL="https://github.com/khoidoan-knb/infisical.git"

echo "==> Installing Infisical as an OS service"

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
  echo "IMPORTANT: Edit $INSTALL_DIR/.env before first start"
  echo "  - Change ENCRYPTION_KEY and AUTH_SECRET"
  echo "  - Set SITE_URL to your public URL (e.g. https://secrets.example.com)"
  echo "  - Set strong POSTGRES_PASSWORD"
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
echo "==> Service installed."
echo "Next steps:"
echo "  1. Edit config:   nano $INSTALL_DIR/.env"
echo "  2. Start service: systemctl start $SERVICE_NAME"
echo "  3. Check status:  systemctl status $SERVICE_NAME"
echo "  4. View logs:     docker compose -f $INSTALL_DIR/docker-compose.prod.yml logs -f"
echo ""
echo "After start, open http://YOUR_SERVER_IP (or your SITE_URL)"
