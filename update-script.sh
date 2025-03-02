#!/bin/bash

# Configuration
UPDATE_URL="https://freedns.afraid.org/dynamic/update.php"
CONF_FILE="/etc/freedns/dnsactual.conf"
LOG_FILE="/var/log/freedns/dnsactual.log"

# Function to get formatted date
log_date() {
    date '+%a %b %d %I:%M:%S %p %Z %Y'
}

# Function for logging
log() {
    echo "$(log_date): $1" | tee -a "$LOG_FILE"
}

# Check if the TOKEN environment variable is set
if [ -z "$TOKEN" ]; then
    log "ERROR - TOKEN environment variable is not set. Exiting."
    exit 1
fi

# Debugging: Log that the script has started
log "Script started."

# Get the current public IP
CURRENT_IP=$(wget -q -O - http://checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
if [ -z "$CURRENT_IP" ]; then
    log "Failed to fetch current IP. Exiting."
    exit 1
fi

# Debugging: Log the fetched IP
log "Current IP is $CURRENT_IP."

# Read the cached IP from the config file (if it exists)
if [ -f "$CONF_FILE" ]; then
    CACHED_IP=$(cat "$CONF_FILE")
else
    CACHED_IP=""
    log "No cached IP found. This is the first run."
fi

# Compare the current IP with the cached IP
if [ "$CURRENT_IP" = "$CACHED_IP" ]; then
    log "No update required. Current IP ($CURRENT_IP) matches cached IP."
else
    # Update the DNS and log the action
    log "IP has changed or first run. Updating DNS with new IP ($CURRENT_IP)."
    wget -q -O /dev/null "$UPDATE_URL?$TOKEN"
    if [ $? -eq 0 ]; then
        log "DNS updated successfully."
    else
        log "Failed to update DNS."
    fi

    # Update the cached IP
    echo "$CURRENT_IP" > "$CONF_FILE"
fi
