# Dynamic DNS Updater with Docker

This project provides a simple and automated way to update your Dynamic DNS (DDNS) using `https://freedns.afraid.org/`. By using Docker, you can run a lightweight container that periodically updates your IP address with FreeDNS, ensuring your domain always points to your current public IP.

---

## Features
- Automatically updates your public IP with FreeDNS every hour.
- Lightweight and efficient, built using Docker and Alpine Linux.
- Logs all updates and actions for easy monitoring.
- Easy to set up and configure using a `.env` file.

---

## Prerequisites
1. A FreeDNS account: [https://freedns.afraid.org/](https://freedns.afraid.org/).
2. Docker and Docker Compose installed on your system.

---

## How to Set Up FreeDNS for DDNS

1. **Sign Up for FreeDNS**:
   - Go to [https://freedns.afraid.org/](https://freedns.afraid.org/) and create an account if you don’t already have one.

2. **Add a Subdomain**:
   - Navigate to the **Subdomains** section in FreeDNS.
   - Add a subdomain (e.g., `myhome.mooo.com`) and link it to your current public IP.

3. **Enable Dynamic DNS**:
   - Go to the **Dynamic DNS** section in FreeDNS: [https://freedns.afraid.org/dynamic/](https://freedns.afraid.org/dynamic/).
   - Copy the **Direct URL** for your subdomain. It will look something like this:
     ```
     https://freedns.afraid.org/dynamic/update.php?YOUR_TOKEN_HERE
     ```
   - Make sure the option **"Link updates of the same IP together?"** is set to **"Currently linked / on"**.

4. **Extract Your Token**:
   - From the Direct URL, copy the token part (everything after `update.php?`). For example:
     ```
     https://freedns.afraid.org/dynamic/update.php?<YOUR_TOKEN_HERE>
     ```

---

## How to Use This Repository

1. **Clone the Repository**:
   Clone this repository to your local machine:
   ```bash
   git clone https://github.com/dhimanparas20/dynamic_dns_updater.git
   cd dynamic_dns_updater
   ```

2. **Set Up the `.env` File**:
   - Inside this repository, rename the `env_sample` file to `.env`:
     ```bash
     mv env_sample .env
     ```
   - Open the `.env` file and paste your FreeDNS token inside:
     ```env
     TOKEN=YOUR_TOKEN_HERE
     ```

3. **Build the Docker Image**:
   Build the Docker image using Docker Compose:
   ```bash
   sudo docker compose build
   ```

4. **Run the Container**:
   Start the container in detached mode:
   ```bash
   sudo docker compose up -d
   ```

---

## What Happens Next?

1. The Docker container will start and run the `update-script.sh` script every hour.
2. The script will:
   - Fetch your current public IP.
   - Compare it with the last updated IP stored in the container.
   - If the IP has changed, it will update your FreeDNS subdomain with the new IP.
   - Log all actions (e.g., IP checks, updates) to `/var/log/freedns/dnsactual.log`.
3. You can monitor the logs using:
   ```bash
   sudo docker logs -f dns-updater
   ```

---

## Example Logs

Here’s what the logs might look like:

```
Sun Mar  2 12:49:51 UTC 2025: Script started.
Sun Mar  2 12:49:52 UTC 2025: Current IP is 117.219.152.3.
Sun Mar  2 12:49:52 UTC 2025: No update required. Current IP (117.219.152.3) matches cached IP.
```

If the IP changes:
```
Sun Mar  2 12:49:51 UTC 2025: Script started.
Sun Mar  2 12:49:52 UTC 2025: Current IP is 203.0.113.42.
Sun Mar  2 12:49:52 UTC 2025: IP has changed or first run. Updating DNS with new IP (203.0.113.42).
Sun Mar  2 12:49:53 UTC 2025: DNS updated successfully.
```

---

## Stopping the Container

To stop the container, run:
```bash
sudo docker compose down
```

---

## Troubleshooting

1. **Logs are Empty**:
   - Ensure the `.env` file is correctly configured with your token.
   - Check the container status:
     ```bash
     docker ps
     ```

2. **DNS Not Updating**:
   - Verify your token is correct.
   - Check the logs for errors:
     ```bash
     sudo docker logs dns-updater
     ```

3. **Rebuild the Container**:
   If you make changes to the script or `.env` file, rebuild the container:
   ```bash
   sudo docker compose build
   sudo docker compose up -d
   sudo docker exec -it caddy caddy fmt --overwrite /etc/caddy/Caddyfile
   sudo docker compose restrat caddy
   ```

---

## Contributing

Feel free to fork this repository and submit pull requests for improvements or additional features.
