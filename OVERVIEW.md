# Dynamic DNS Updater for FreeDNS

[![Docker Pulls](https://img.shields.io/docker/pulls/dhimanparas20/ddns)](https://hub.docker.com/r/dhimanparas20/ddns)
[![Docker Stars](https://img.shields.io/docker/stars/dhimanparas20/ddns)](https://hub.docker.com/r/dhimanparas20/ddns)

Production-ready container that keeps your FreeDNS subdomains synced with your dynamic public IP.

## What This Image Does

- Detects your public IP using reliable fallback endpoints.
- Calls FreeDNS dynamic update URL when needed.
- Supports either:
  - Full FreeDNS direct URL (`FREEDNS_UPDATE_URL`) (recommended)
  - Raw FreeDNS token (`FREEDNS_TOKEN`)
- Handles retries/timeouts and network edge cases (IPv4 forcing + HTTP fallback).
- Maintains state/logs for reliable health checks.

## Quick Start (Docker Compose)

```yaml
services:
  ddns:
    image: dhimanparas20/ddns:latest
    container_name: ddns
    restart: unless-stopped
    environment:
      TZ: Asia/Calcutta
      FREEDNS_UPDATE_URL: ${FREEDNS_UPDATE_URL}
      # Optional alternative to FREEDNS_UPDATE_URL:
      # FREEDNS_TOKEN: ${FREEDNS_TOKEN}
      UPDATE_INTERVAL: 1
      FREEDNS_REQUEST_TIMEOUT_SECONDS: 15
      FREEDNS_CONNECT_TIMEOUT_SECONDS: 8
      FREEDNS_RETRY_COUNT: 1
      FREEDNS_FORCE_IPV4: 1
      FREEDNS_ALLOW_HTTP_FALLBACK: 1
      FORCE_UPDATE_EACH_CYCLE: 0
    volumes:
      - dns-logs:/var/log/freedns
      - dns-config:/etc/freedns

volumes:
  dns-logs:
  dns-config:
```

Run:

```bash
docker compose up -d
```

## Quick Start (docker run)

```bash
docker run -d \
  --name ddns \
  --restart unless-stopped \
  -e TZ=Asia/Calcutta \
  -e FREEDNS_TOKEN=your_token \
  -e UPDATE_INTERVAL=1 \
  -v dns-logs:/var/log/freedns \
  -v dns-config:/etc/freedns \
  dhimanparas20/ddns:latest
```

## Configuration

| Variable | Description | Default |
|---|---|---|
| `FREEDNS_UPDATE_URL` | Full direct URL from FreeDNS Dynamic DNS page | empty |
| `FREEDNS_TOKEN` | Raw token from direct URL (used if `FREEDNS_UPDATE_URL` is not set) | empty |
| `UPDATE_INTERVAL` | Check interval in hours | `1` |
| `TZ` | Log timezone | `UTC` (image), `Asia/Calcutta` in compose default |
| `FREEDNS_REQUEST_TIMEOUT_SECONDS` | Max time per request attempt | `15` |
| `FREEDNS_CONNECT_TIMEOUT_SECONDS` | TCP connect timeout | `8` |
| `FREEDNS_RETRY_COUNT` | Curl retries per URL | `1` |
| `FREEDNS_FORCE_IPV4` | Use IPv4 for FreeDNS calls (`1`/`0`) | `1` |
| `FREEDNS_ALLOW_HTTP_FALLBACK` | Try HTTP if HTTPS fails (`1`/`0`) | `1` |
| `FORCE_UPDATE_EACH_CYCLE` | Always call FreeDNS, skip local IP cache compare (`1`/`0`) | `0` |
| `HEALTHCHECK_GRACE_SECONDS` | Extra health grace window | `600` |

At least one of `FREEDNS_UPDATE_URL` or `FREEDNS_TOKEN` must be provided.

## Healthcheck

This image includes a built-in Docker healthcheck. It marks healthy when:

- update attempts are happening on schedule
- and at least one recent cycle completed successfully

Check status:

```bash
docker inspect --format='{{.State.Health.Status}}' ddns
```

## Logs

Follow logs:

```bash
docker logs -f ddns
```

Typical successful update log:

```text
FreeDNS update acknowledged: Updated 5 host(s) ... to <IP>
Update cycle completed successfully.
```

Typical no-change log (healthy behavior):

```text
No update required. Current IP matches cached IP (...)
Update cycle completed successfully.
```

## Getting Your FreeDNS URL/Token

1. Go to https://freedns.afraid.org/
2. Open `Dynamic DNS`
3. Copy your direct URL, e.g.:
   `https://freedns.afraid.org/dynamic/update.php?YOUR_TOKEN`
4. Use either:
   - Full URL in `FREEDNS_UPDATE_URL`
   - Token part only in `FREEDNS_TOKEN`

## Troubleshooting

- `FreeDNS request failed` with timeout:
  - Verify network access from host/container to `freedns.afraid.org`
  - Keep `FREEDNS_FORCE_IPV4=1`
  - Keep `FREEDNS_ALLOW_HTTP_FALLBACK=1`
- `FreeDNS returned an error response`:
  - Re-check URL/token for the correct subdomain/account
- Container exits immediately:
  - Ensure `FREEDNS_UPDATE_URL` or `FREEDNS_TOKEN` is set

## Tags

- `latest`: newest stable image

## License

MIT License. See `LICENSE.md`.
