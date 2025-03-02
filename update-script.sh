#!/bin/bash

# Configuration
UPDATE_URL="https://freedns.afraid.org/dynamic/update.php"
CONF_FILE="/etc/freedns/dnsactual.conf"
LOG_FILE="/var/log/freedns/dnsactual.log"

# Check if the TOKEN environment variable is set
if [ -z "$TOKEN" ]; then
  echo "$(date): ERROR - TOKEN environment variable is not set. Exiting." | tee -a "$LOG_FILE"
  exit 1
fi

# Debugging: Log that the script has started
echo "$(date): Script started." | tee -a "$LOG_FILE"

# Get the current public IP
CURRENT_IP=$(wget -q -O - http://checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
if [ -z "$CURRENT_IP" ]; then
  echo "$(date): Failed to fetch current IP. Exiting." | tee -a "$LOG_FILE"
  exit 1
fi

# Debugging: Log the fetched IP
echo "$(date): Current IP is $CURRENT_IP." | tee -a "$LOG_FILE"

# Read the cached IP from the config file (if it exists)
if [ -f "$CONF_FILE" ]; then
  CACHED_IP=$(cat "$CONF_FILE")
else
  CACHED_IP=""
  echo "$(date): No cached IP found. This is the first run." | tee -a "$LOG_FILE"
fi

# Compare the current IP with the cached IP
if [ "$CURRENT_IP" = "$CACHED_IP" ]; then
  echo "$(date): No update required. Current IP ($CURRENT_IP) matches cached IP." | tee -a "$LOG_FILE"
else
  # Update the DNS and log the action
  echo "$(date): IP has changed or first run. Updating DNS with new IP ($CURRENT_IP)." | tee -a "$LOG_FILE"
  wget -q -O /dev/null "$UPDATE_URL?$TOKEN"
  if [ $? -eq 0 ]; then
    echo "$(date): DNS updated successfully." | tee -a "$LOG_FILE"
  else
    echo "$(date): Failed to update DNS." | tee -a "$LOG_FILE"
  fi

  # Update the cached IP
  echo "$CURRENT_IP" > "$CONF_FILE"
fi
