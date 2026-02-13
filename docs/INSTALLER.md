# One-Command Installer

## Quick install
Run the installer with a single command:
```bash
bash <(curl -fsSL https://aiops.chhotu.online/install.sh)
```

Or download and inspect locally:
```bash
curl -fsSL https://aiops.chhotu.online/install.sh -o install.sh
bash install.sh
```

## What it does
1. Checks Docker availability.
2. Clones the repository into `~/aiops-install`.
3. Generates `.env` from template.
4. Runs `make bootstrap` (compose up + seeds).
5. Runs `make doctor` to verify services.

## Two-step alternative (safer for CI/prod)
```bash
# Step 1: clone and prepare
git clone https://github.com/chhotu-claw/ai-ops-starter-kit.git ~/aiops-install
cd ~/aiops-install

# Step 2: bootstrap
CADDY_HTTP_PORT=8080 make bootstrap
make doctor
```

## Non-interactive examples
```bash
# Skip prompts and use defaults
CADDY_HTTP_PORT=8080 bash <(curl -fsSL https://aiops.chhotu.online/install.sh)

# Custom port and install directory
CADDY_HTTP_PORT=18080 INSTALL_DIR=~/my-aiops bash <(curl -fsSL https://aiops.chhotu.online/install.sh)
```

## Customization (environment variables)
| Variable | Default | Description |
|---|---|---|
| `CADDY_HTTP_PORT` | `8080` | Port for Caddy reverse proxy |
| `INSTALL_DIR` | `~/aiops-install` | Where the repo is cloned |
| `REPO_URL` | `https://github.com/chhotu-claw/ai-ops-starter-kit.git` | Source repository |

## Troubleshooting

### Docker not found
```
ERROR: Docker is required but not installed.
```
**Fix:** Install Docker Desktop (Windows/macOS) or Docker Engine (Linux). Ensure `docker` is in your PATH.

### Docker daemon not reachable
```
ERROR: Docker daemon is not running or not accessible.
```
**Fix:** 
- Start Docker Desktop (Windows/macOS).
- On Linux: `sudo systemctl start docker` or `sudo service docker start`.
- If using Docker Desktop WSL2 backend, ensure it's enabled in Docker Desktop settings.

### Git clone fails (network/permission)
```
fatal: unable to access 'https://github.com/...': Could not resolve host
```
**Fix:** Check internet connection. If behind firewall, configure proxy or use SSH:
```bash
export https_proxy=http://proxy:port
# or
export http_proxy=http://proxy:port
```

### Port already in use
If `CADDY_HTTP_PORT=8080` fails:
```bash
# Find what's using the port
sudo lsof -i :8080

# Use a different port
CADDY_HTTP_PORT=18080 bash <(curl -fsSL https://aiops.chhotu.online/install.sh)
```

### Bootstrap fails mid-way
```bash
# Check logs
cd ~/aiops-install
docker compose logs -f

# Retry bootstrap
cd ~/aiops-install
make bootstrap
```

### Doctor health checks fail
```bash
cd ~/aiops-install
make doctor
```
If Mattermost or Vikunja show `fail`:
- Wait 30 seconds (services may still be starting).
- Re-run `make doctor`.
- Check Docker memory/CPU limits if services crash.

## Rollback / cleanup

### One-Click Rollback Script

A dedicated rollback script is included for safe removal:

```bash
curl -fsSL https://aiops.chhotu.online/scripts/rollback.sh -o rollback.sh
bash rollback.sh
```

Or if you already have the installation:

```bash
cd ~/aiops-install ## Rollback / cleanup## Rollback / cleanup bash scripts/rollback.sh
```

## Rollback / cleanup
If the install fails or you want to start fresh:
```bash
# Stop containers and remove data
docker compose -f ~/aiops-install/docker-compose.yml down -v --remove-orphans
# Remove the installation directory
rm -rf ~/aiops-install
```

## Source
The installer script lives at:
- Repo: `install.sh`
- Hosted: `https://aiops.chhotu.online/install.sh`

It is idempotent — rerunning prompts to remove the existing installation first.
