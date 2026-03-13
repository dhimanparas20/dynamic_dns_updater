#!/usr/bin/env bash

set -Eeuo pipefail

UPDATE_SCRIPT="${UPDATE_SCRIPT:-/usr/local/bin/update-script.sh}"
LOG_FILE="${LOG_FILE:-/var/log/freedns/dnsactual.log}"
UPDATE_INTERVAL="${UPDATE_INTERVAL:-1}"

log_date() {
    date '+%Y-%m-%d %H:%M:%S %Z'
}

log() {
    printf '%s: %s\n' "$(log_date)" "$1" | tee -a "${LOG_FILE}"
}

normalize_token() {
    local raw_token="$1"
    raw_token="$(printf '%s' "${raw_token}" | tr -d '[:space:]')"
    if [[ "${raw_token}" == *"update.php?"* ]]; then
        raw_token="${raw_token#*update.php?}"
    fi
    raw_token="${raw_token#\?}"
    printf '%s' "${raw_token}"
}

is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 > 0 ))
}

mkdir -p /etc/freedns /var/log/freedns /var/run/freedns

if ! is_positive_int "${UPDATE_INTERVAL}"; then
    log "ERROR - UPDATE_INTERVAL must be a positive integer (hours)."
    exit 1
fi

TOKEN="$(normalize_token "${FREEDNS_TOKEN:-}")"
UPDATE_URL="$(printf '%s' "${FREEDNS_UPDATE_URL:-}" | tr -d '[:space:]')"

if [[ -z "${UPDATE_URL}" && ( -z "${TOKEN}" || "${TOKEN}" == "\$FREEDNS_TOKEN" || "${TOKEN}" == "\${FREEDNS_TOKEN}" ) ]]; then
    log "ERROR - Provide FREEDNS_UPDATE_URL or FREEDNS_TOKEN."
    exit 1
fi

SLEEP_SECONDS=$((UPDATE_INTERVAL * 3600))

log "Container started."
log "Update interval: ${UPDATE_INTERVAL} hour(s)."

trap 'log "Termination signal received. Exiting."; exit 0' INT TERM

while true; do
    if "${UPDATE_SCRIPT}"; then
        log "Update cycle completed successfully."
    else
        cycle_exit_code=$?
        log "WARNING - Update cycle failed with exit code ${cycle_exit_code}."
    fi

    sleep "${SLEEP_SECONDS}" &
    sleep_pid=$!
    wait "${sleep_pid}" || true
done
