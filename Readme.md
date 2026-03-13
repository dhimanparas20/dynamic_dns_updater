# Dynamic DNS Updater (FreeDNS)

Lightweight Docker image that keeps a FreeDNS subdomain synced with your current public IP.

## What It Does

1. Detects your current public IP (with multiple fallback providers).
2. Compares it with the last cached IP.
3. Calls FreeDNS only when an update is needed.
4. Verifies FreeDNS response text before reporting success.
5. Stores logs and state in mounted volumes.

## Key Runtime Guarantees

- Container exits at startup if both `FREEDNS_TOKEN` and `FREEDNS_UPDATE_URL` are missing/unresolved.
- You can configure FreeDNS either by token (`FREEDNS_TOKEN`) or by exact direct URL (`FREEDNS_UPDATE_URL`).
- Healthcheck is based on update heartbeat timestamps, not process grep.
- Failed update cycles are logged as failures and do not get marked successful.

## Quick Start (Docker Compose)

```bash
git clone https://github.com/dhimanparas20/dynamic_dns_updater.git
cd dynamic_dns_updater
cp env_sample .env
# edit .env and set FREEDNS_UPDATE_URL (recommended) or FREEDNS_TOKEN
docker compose up -d --build
```

## Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FREEDNS_TOKEN` | FreeDNS token from direct URL | - | Yes* |
| `FREEDNS_UPDATE_URL` | Full FreeDNS direct update URL | - | Yes* |
| `UPDATE_INTERVAL` | Check interval in hours (positive integer) | `1` | No |
| `TZ` | Time zone for logs | `UTC` | No |
| `HEALTHCHECK_GRACE_SECONDS` | Extra buffer for health staleness checks | `600` | No |
| `FREEDNS_REQUEST_TIMEOUT_SECONDS` | Max duration for one FreeDNS request attempt | `15` | No |
| `FREEDNS_CONNECT_TIMEOUT_SECONDS` | Connection timeout for FreeDNS requests | `8` | No |
| `FREEDNS_RETRY_COUNT` | Curl retry count per URL | `1` | No |
| `FREEDNS_FORCE_IPV4` | Force IPv4 for FreeDNS request (`1` or `0`) | `1` | No |
| `FREEDNS_ALLOW_HTTP_FALLBACK` | Try `http://` FreeDNS URL if `https://` times out (`1` or `0`) | `1` | No |
| `FORCE_UPDATE_EACH_CYCLE` | Skip local IP cache check and always hit FreeDNS (`1` or `0`) | `0` | No |

\* Provide at least one of `FREEDNS_TOKEN` or `FREEDNS_UPDATE_URL`.

## Compose Example

```yaml
services:
  ddns:
    image: dhimanparas20/ddns:latest
    container_name: ddns
    restart: unless-stopped
    environment:
      TZ: Asia/Kolkata
      FREEDNS_UPDATE_URL: ${FREEDNS_UPDATE_URL}
      FREEDNS_TOKEN: ${FREEDNS_TOKEN}
      UPDATE_INTERVAL: 1
    volumes:
      - dns-logs:/var/log/freedns
      - dns-config:/etc/freedns

volumes:
  dns-logs:
  dns-config:
```

## Monitor

```bash
docker logs -f ddns
docker inspect --format='{{.State.Health.Status}}' ddns
```

## Troubleshooting

- If DNS is not updating:
  - Verify the exact direct URL/token from FreeDNS Dynamic DNS page.
  - Ensure the token in your `.env` matches FreeDNS generated script token for the same subdomain.
  - If logs show `curl exit 28`, keep `FREEDNS_FORCE_IPV4=1` (default) and optionally set `FREEDNS_ALLOW_HTTP_FALLBACK=1`.
  - Check container logs for `FreeDNS returned an error response`.
- If container exits immediately:
  - Confirm at least one of `FREEDNS_UPDATE_URL` or `FREEDNS_TOKEN` is set correctly.
- If health is `unhealthy`:
  - Check network reachability from container to IP check endpoints and FreeDNS.

## Build Locally

```bash
docker build -t ddns-updater:local .
docker run -d \
  --name ddns \
  --restart unless-stopped \
  -e FREEDNS_TOKEN=your_token \
  -e UPDATE_INTERVAL=1 \
  -v dns-logs:/var/log/freedns \
  -v dns-config:/etc/freedns \
  ddns-updater:local
```

## License

MIT License. See [LICENSE.md](LICENSE.md).
