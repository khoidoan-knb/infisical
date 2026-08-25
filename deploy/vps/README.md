# Run Infisical in Standalone Mode on a VPS (as OS Service)

This is a **self-contained / standalone** deployment.

- **No external database required** — PostgreSQL and Redis run automatically as Docker containers.
- Everything is managed by one systemd service (`infisical`).
- Starts on boot and restarts on failure.

> Infisical itself always needs Postgres + Redis internally.  
> With this setup you never install or manage them yourself — Docker Compose handles both.

## Prerequisites

- Linux VPS (Ubuntu 22.04 / Debian 12 recommended)
- Root or sudo access
- Docker + Docker Compose plugin

Install Docker if needed:
```bash
curl -fsSL https://get.docker.com | sh
```

## Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/khoidoan-knb/infisical/main/deploy/vps/install.sh -o install-infisical.sh
sudo bash install-infisical.sh
```

Then:

```bash
# 1. Edit secrets (required once)
sudo nano /opt/infisical/.env

# 2. Start the service
sudo systemctl start infisical
sudo systemctl status infisical
```

Open `http://YOUR_SERVER_IP` (or the `SITE_URL` you configured).

## What gets started

One command (`systemctl start infisical`) starts **three containers**:

| Container | Purpose |
|-----------|---------|
| `infisical-backend` | Infisical application |
| `infisical-db` | PostgreSQL (data persistence) |
| `infisical-dev-redis` | Redis (cache / queues) |

Data is stored in Docker volumes (`pg_data`, `redis_data`) so it survives restarts.

## Manual install

```bash
sudo mkdir -p /opt/infisical
sudo git clone https://github.com/khoidoan-knb/infisical.git /opt/infisical
cd /opt/infisical
sudo cp .env.example .env
sudo nano .env   # set ENCRYPTION_KEY, AUTH_SECRET, SITE_URL, POSTGRES_PASSWORD

sudo cp deploy/vps/infisical.service /etc/systemd/system/infisical.service
sudo systemctl daemon-reload
sudo systemctl enable --now infisical
```

## Useful commands

```bash
sudo systemctl start|stop|restart|status infisical

# View logs
cd /opt/infisical
docker compose -f docker-compose.prod.yml logs -f
```

## Required `.env` changes

| Variable | How to generate |
|----------|-----------------|
| `ENCRYPTION_KEY` | `openssl rand -hex 16` |
| `AUTH_SECRET` | `openssl rand -base64 32` |
| `POSTGRES_PASSWORD` | Strong password of your choice |
| `SITE_URL` | e.g. `https://secrets.example.com` or `http://YOUR_IP` |

## HTTPS (recommended)

Put Nginx or Caddy in front of Infisical and terminate TLS there.  
Point `SITE_URL` to the HTTPS address.

## Free-only UI note

This fork removes the main upgrade modal and the "Usage & Billing" sidebar link.  
The default compose file pulls the official image. To use the customized frontend you would need to build a custom image from this source.

## Uninstall

```bash
sudo systemctl disable --now infisical
sudo rm /etc/systemd/system/infisical.service
sudo systemctl daemon-reload
# optional: remove data
# cd /opt/infisical && docker compose -f docker-compose.prod.yml down -v
# sudo rm -rf /opt/infisical
```
