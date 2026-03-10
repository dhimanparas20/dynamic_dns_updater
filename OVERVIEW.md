# Dynamic DNS Updater

[![Docker Pulls](https://img.shields.io/docker/pulls/dhimanparas20/ddns)](https://hub.docker.com/r/dhimanparas20/ddns)
[![Docker Stars](https://img.shields.io/docker/stars/dhimanparas20/ddns)](https://hub.docker.com/r/dhimanparas20/ddns)

Automatically keep your FreeDNS subdomain synchronized with your dynamic public IP address. Lightweight, reliable, and easy to deploy.

---

## What is this?

This container monitors your public IP address and automatically updates your FreeDNS (afraid.org) subdomain whenever your IP changes. Perfect for:

- Home servers behind dynamic IPs
- Remote access to home networks
- Self-hosted services (Nextcloud, Plex, etc.)
- NAS systems (Synology, QNAP, etc.)
- IoT projects requiring consistent domain access

---

## Quick Start

### Docker Compose (Recommended)

```yaml
services:
  ddns:
    image: dhimanparas20/ddns:latest
    container_name: ddns
    restart: always
    environment:
      - FREEDNS_TOKEN=your_token_here
      - UPDATE_INTERVAL=1
      - TZ=Asia/Kolkata
    volumes:
      - dns-logs:/var/log/freedns
      - dns-config:/etc/freedns

volumes:
  dns-logs:
  dns-config:
```

### Docker Run

```bash
docker run -d \
  --name ddns \
  --restart always \
  -e FREEDNS_TOKEN=your_token_here \
  -e UPDATE_INTERVAL=1 \
  -v dns-logs:/var/log/freedns \
  dhimanparas20/ddns:latest
```

---

## Setup Instructions

### 1. Get Your FreeDNS Token

1. Create an account at [FreeDNS](https://freedns.afraid.org/)
2. Add a subdomain (e.g., `myhome.mooo.com`)
3. Navigate to **Dynamic DNS** section
4. Copy your Direct URL token (the part after `update.php?`)

### 2. Configure & Run

Replace `your_token_here` in the commands above with your actual token.

---

## Features

- ✅ Automatic IP detection
- ✅ Smart updates (only when IP changes)
- ✅ Configurable check interval
- ✅ Persistent logs and IP cache
- ✅ Health check monitoring
- ✅ Minimal resource usage (~15MB image)
- ✅ Multi-architecture support

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FREEDNS_TOKEN` | Your FreeDNS token (required) | - |
| `UPDATE_INTERVAL` | Hours between checks | 1 |
| `TZ` | Container timezone | Asia/Kolkata |

### Ways to Pass Your Token

**Option 1: Using `.env` file (Recommended)**
Create a `.env` file in the same directory as your compose file:
```env
FREEDNS_TOKEN=your_token_here
UPDATE_INTERVAL=1
```
Then run: `docker compose up -d`

**Option 2: Direct environment variable**
```bash
FREEDNS_TOKEN=your_token_here docker compose up -d
```

**Option 3: Hardcode in compose (Not recommended)**
Replace `your_token_here` directly in the compose file with your actual token.

---

## Monitoring

View real-time logs:
```bash
docker logs -f ddns
```

Check health status:
```bash
docker inspect --format='{{.State.Health.Status}}' ddns
```

---

## Tags

- `latest` - Current stable release

---

## Support

- 📖 [Full Documentation](https://github.com/dhimanparas20/dynamic_dns_updater)
- 🐛 [Issue Tracker](https://github.com/dhimanparas20/dynamic_dns_updater/issues)
- ⭐ [Star on GitHub](https://github.com/dhimanparas20/dynamic_dns_updater)

---

## License

This project is licensed under the [MIT License](https://github.com/dhimanparas20/dynamic_dns_updater/blob/main/LICENSE.md).

Free to use and modify, but please mention the original author: **Paras Dhiman (dhimanparas20)**.
