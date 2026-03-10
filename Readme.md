# Dynamic DNS Updater

A lightweight, automated Docker container that keeps your FreeDNS subdomain pointing to your current public IP address. Perfect for home servers, NAS systems, or any setup with a dynamic IP.

---

## Features

- 🔄 Automatic IP detection and DNS updates at configurable intervals
- 🐳 Lightweight Alpine Linux-based Docker image (~15MB)
- 📊 Built-in health checks and comprehensive logging
- ⚙️ Simple configuration via environment variables
- 🚀 One-command deployment with Docker Compose

---

## Prerequisites

- [FreeDNS](https://freedns.afraid.org/) account
- Docker and Docker Compose installed

---

## Quick Start

### 1. Get Your FreeDNS Token

1. Sign up at [FreeDNS](https://freedns.afraid.org/)
2. Add a subdomain in the **Subdomains** section
3. Go to **Dynamic DNS** and copy your Direct URL:
   ```
   https://freedns.afraid.org/dynamic/update.php?YOUR_TOKEN_HERE
   ```
4. Extract the token (everything after `update.php?`)

### 2. Deploy with Docker Compose

```bash
# Clone the repository
git clone https://github.com/dhimanparas20/dynamic_dns_updater.git
cd dynamic_dns_updater

# Configure environment
cp env_sample .env
# Edit .env and add your FREEDNS_TOKEN

# Start the container
docker compose up -d
```

### 3. Using Docker Hub Image (Pre-built)

```yaml
services:
  ddns:
    image: dhimanparas20/ddns:latest
    container_name: ddns
    restart: always
    environment:
      - TZ=Asia/Kolkata
      - FREEDNS_TOKEN=your_token_here
      - UPDATE_INTERVAL=1
    volumes:
      - dns-logs:/var/log/freedns
      - dns-config:/etc/freedns

volumes:
  dns-logs:
  dns-config:
```

---

## Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FREEDNS_TOKEN` | FreeDNS token from Direct URL | - | Yes |
| `UPDATE_INTERVAL` | Check interval in hours | 1 | No |
| `TZ` | Timezone | Asia/Kolkata | No |

### Passing the Token

You have 3 ways to provide your `FREEDNS_TOKEN`:

**Option 1: Using `.env` file (Recommended)**
```bash
# Copy the sample file
cp env_sample .env

# Edit .env and add your token
FREEDNS_TOKEN=your_token_here
UPDATE_INTERVAL=1

# Start the container
docker compose up -d
```
✅ Token isn't exposed in command history  
✅ Easy to manage multiple variables  
✅ Already in `.gitignore` (won't be committed)

**Option 2: Pass directly via environment variable**
```bash
FREEDNS_TOKEN=your_token_here docker compose up -d
```

**Option 3: Hardcode in compose.yml (Not recommended)**
```yaml
environment:
  - FREEDNS_TOKEN=your_actual_token_here
```

---

## Monitoring

### View Logs
```bash
docker logs -f ddns
```

### Check Health Status
```bash
docker inspect --format='{{.State.Health.Status}}' ddns
```

---

## Docker Hub

Pre-built images are available on Docker Hub:

```bash
docker pull dhimanparas20/ddns:latest
```

**Available Tags:**
- `latest` - Latest stable release

---

## Building from Source

```bash
docker build -t ddns-updater .
docker run -d \
  -e FREEDNS_TOKEN=your_token \
  -e UPDATE_INTERVAL=1 \
  -v dns-logs:/var/log/freedns \
  --name ddns \
  ddns-updater
```

---

## Troubleshooting

**Empty logs?**
- Verify `FREEDNS_TOKEN` is set correctly
- Check container status: `docker ps`

**DNS not updating?**
- Verify token is correct in FreeDNS dashboard
- Check for errors: `docker logs ddns`

**Change update interval?**
```bash
# Edit .env, then restart
docker compose down
docker compose up -d
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

MIT License - Free to use and modify, but please mention the original author: **Paras Dhiman (dhimanparas20)**.

---

## Contributing

Contributions welcome! Please submit pull requests for improvements.
