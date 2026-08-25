# Standalone Infisical on a VPS (OS Service)

Run Infisical as a normal Linux systemd service with **no external database required**.

Postgres and Redis are included automatically inside the Docker Compose stack.
You only need Docker on the VPS — nothing else to install or manage.

> **Note:** Infisical’s architecture always needs Postgres + Redis.  
> This setup embeds them for you, so from your point of view it is fully standalone.

## Prerequisites

- Linux VPS (Ubuntu 22.04 / Debian 12 / similar recommended)
- Root or sudo access
- Docker + Docker Compose plugin installed

Install Docker if needed: https://docs.docker.com/engine/install/

## Quick install (recommended)

```bash
# Download and run the installer (as root)
curl -fsSL https://raw.githubusercontent.com/khoidoan-knb/infisical/main/deploy/vps/install.sh -o install-infisical.sh
sudo bash install-infisical.sh
```

Then edit the config and start:

```bash
sudo nano /opt/infisical/.env          # set secrets + SITE_URL
sudo systemctl start infisical
sudo systemctl status infisical
```

## Manual install

```bash
sudo mkdir -p /opt/infisical
sudo git clone https://github.com/khoidoan-knb/infisical.git /opt/infisical
cd /opt/infisical
sudo cp .env.example .env
# Edit .env – set strong secrets and SITE_URL
sudo nano .env

sudo cp deploy/vps/infisical.service /etc/systemd/system/infisical.service
sudo systemctl daemon-reload
sudo systemctl enable --now infisical
```

## What runs automatically

| Component          | How it is provided              |
|--------------------|---------------------------------|
| Infisical app      | Docker container                |
| PostgreSQL         | Included in the stack (volume)  |
| Redis              | Included in the stack (volume)  |

**You do not need to install, configure, or manage any external database.**

## Useful commands

```bash
sudo systemctl start infisical     # start
sudo systemctl stop infisical      # stop
sudo systemctl restart infisical   # restart
sudo systemctl status infisical    # status

# Logs
cd /opt/infisical
docker compose -f docker-compose.prod.yml logs -f
```

## Configuration notes

1. **Required changes in `.env`**
   - Generate a real `ENCRYPTION_KEY` (32-byte hex): `openssl rand -hex 16`
   - Generate a real `AUTH_SECRET`: `openssl rand -base64 32`
   - Set `SITE_URL` to your public URL (e.g. `https://secrets.yourdomain.com`)
   - Change `POSTGRES_PASSWORD` to a strong password

2. **Firewall** – open port 80 (and 443 if you put a reverse proxy in front).

3. **HTTPS** – put Nginx/Caddy/Traefik in front of Infisical and terminate TLS there.  
   Point `SITE_URL` to the HTTPS address.

4. **Custom free-only UI** – this fork disables upgrade prompts in the frontend source.  
   The default `docker-compose.prod.yml` pulls the official pre-built image, so the UI changes only appear if you build a custom image from this source. For most users the official image + service management is sufficient.

## Uninstall

```bash
sudo systemctl disable --now infisical
sudo rm /etc/systemd/system/infisical.service
sudo systemctl daemon-reload
# optionally remove /opt/infisical and docker volumes
# docker volume rm infisical_pg_data infisical_redis_data
```
