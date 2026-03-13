#!/usr/bin/env bash

set -Eeuo pipefail

UPDATE_URL_BASE="${UPDATE_URL_BASE:-https://freedns.afraid.org/dynamic/update.php}"
CONF_DIR="${CONF_DIR:-/etc/freedns}"
CONF_FILE="${CONF_FILE:-${CONF_DIR}/dnsactual.conf}"
LOG_FILE="${LOG_FILE:-/var/log/freedns/dnsactual.log}"
RUNTIME_DIR="${RUNTIME_DIR:-/var/run/freedns}"
LAST_ATTEMPT_FILE="${LAST_ATTEMPT_FILE:-${RUNTIME_DIR}/last_attempt_epoch}"
LAST_SUCCESS_FILE="${LAST_SUCCESS_FILE:-${RUNTIME_DIR}/last_success_epoch}"
FREEDNS_REQUEST_TIMEOUT_SECONDS="${FREEDNS_REQUEST_TIMEOUT_SECONDS:-15}"
FREEDNS_CONNECT_TIMEOUT_SECONDS="${FREEDNS_CONNECT_TIMEOUT_SECONDS:-8}"
FREEDNS_RETRY_COUNT="${FREEDNS_RETRY_COUNT:-1}"
FREEDNS_FORCE_IPV4="${FREEDNS_FORCE_IPV4:-1}"
FREEDNS_ALLOW_HTTP_FALLBACK="${FREEDNS_ALLOW_HTTP_FALLBACK:-1}"
FREEDNS_UPDATE_URL="${FREEDNS_UPDATE_URL:-}"
FORCE_UPDATE_EACH_CYCLE="${FORCE_UPDATE_EACH_CYCLE:-0}"

umask 077
mkdir -p "${CONF_DIR}" "$(dirname "${LOG_FILE}")" "${RUNTIME_DIR}"

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

redact_url() {
    local url="$1"
    if [[ "${url}" == *"?"* ]]; then
        printf '%s?REDACTED' "${url%%\?*}"
        return 0
    fi

    printf '%s' "${url}"
}

is_valid_ip() {
    local ip="$1"
    local octet
    local -a octets

    if [[ "${ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "${ip}"
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                return 1
            fi
        done
        return 0
    fi

    # Loose IPv6 validation is enough for updater usage.
    [[ "${ip}" =~ : ]]
}

fetch_public_ip() {
    local endpoint
    local response
    local -a ip_endpoints=(
        "https://api.ipify.org"
        "https://checkip.amazonaws.com"
        "https://ifconfig.me/ip"
    )

    for endpoint in "${ip_endpoints[@]}"; do
        response="$(curl -fsS --max-time 10 "${endpoint}" 2>/dev/null || true)"
        response="$(printf '%s' "${response}" | tr -d '[:space:]')"
        if [[ -n "${response}" ]] && is_valid_ip "${response}"; then
            printf '%s\n' "${response}"
            return 0
        fi
    done

    return 1
}

mark_attempt() {
    date +%s > "${LAST_ATTEMPT_FILE}"
}

mark_success() {
    date +%s > "${LAST_SUCCESS_FILE}"
}

build_update_url() {
    local raw_value
    local normalized

    if [[ -n "${FREEDNS_UPDATE_URL}" ]]; then
        printf '%s' "$(printf '%s' "${FREEDNS_UPDATE_URL}" | tr -d '[:space:]')"
        return 0
    fi

    raw_value="$(printf '%s' "${FREEDNS_TOKEN:-}" | tr -d '[:space:]')"

    if [[ -z "${raw_value}" ]]; then
        return 1
    fi

    if [[ "${raw_value}" == http://* || "${raw_value}" == https://* ]]; then
        printf '%s' "${raw_value}"
        return 0
    fi

    normalized="$(normalize_token "${raw_value}")"
    if [[ -z "${normalized}" ]]; then
        return 1
    fi

    printf '%s?%s' "${UPDATE_URL_BASE}" "${normalized}"
}

request_freedns_update() {
    local primary_url="$1"
    local current_url
    local response
    local curl_exit_code
    local wget_exit_code
    local timeout="${FREEDNS_REQUEST_TIMEOUT_SECONDS}"
    local connect_timeout="${FREEDNS_CONNECT_TIMEOUT_SECONDS}"
    local retry_count="${FREEDNS_RETRY_COUNT}"
    local last_error=""
    local -a curl_ip_flags=()
    local -a wget_ip_flags=()
    local -a candidate_urls=("${primary_url}")

    if [[ "${FREEDNS_FORCE_IPV4}" == "1" ]]; then
        curl_ip_flags=(-4)
        wget_ip_flags=(-4)
    fi

    if [[ "${FREEDNS_ALLOW_HTTP_FALLBACK}" == "1" && "${primary_url}" == https://* ]]; then
        candidate_urls+=("${primary_url/https:\/\//http://}")
    fi

    for current_url in "${candidate_urls[@]}"; do
        set +e
        response="$(curl "${curl_ip_flags[@]}" -fsSL --retry "${retry_count}" --retry-delay 2 --connect-timeout "${connect_timeout}" --max-time "${timeout}" "${current_url}" 2>&1)"
        curl_exit_code=$?
        set -e
        if (( curl_exit_code == 0 )); then
            printf '%s' "${response}"
            return 0
        fi

        last_error="curl exit ${curl_exit_code} to $(redact_url "${current_url}"): ${response}"

        set +e
        response="$(wget "${wget_ip_flags[@]}" -qO- --connect-timeout="${connect_timeout}" --timeout="${timeout}" --tries=1 "${current_url}" 2>&1)"
        wget_exit_code=$?
        set -e
        if (( wget_exit_code == 0 )); then
            printf '%s' "${response}"
            return 0
        fi

        last_error="${last_error}; wget exit ${wget_exit_code} to $(redact_url "${current_url}"): ${response}"
    done

    printf '%s' "${last_error}"
    return 1
}

TOKEN="$(normalize_token "${FREEDNS_TOKEN:-}")"
UPDATE_URL="$(build_update_url || true)"

mark_attempt

if [[ -z "${UPDATE_URL}" || "${UPDATE_URL}" == "\$FREEDNS_UPDATE_URL" || "${UPDATE_URL}" == "\${FREEDNS_UPDATE_URL}" ]]; then
    log "ERROR - Provide FREEDNS_UPDATE_URL or FREEDNS_TOKEN."
    exit 1
fi

if [[ -n "${TOKEN}" && ( "${TOKEN}" == "\$FREEDNS_TOKEN" || "${TOKEN}" == "\${FREEDNS_TOKEN}" ) ]]; then
    log "ERROR - FREEDNS_TOKEN is unresolved."
    exit 1
fi

log "Update cycle started."

CURRENT_IP=""
if [[ "${FORCE_UPDATE_EACH_CYCLE}" != "1" ]]; then
    CURRENT_IP="$(fetch_public_ip || true)"
    if [[ -z "${CURRENT_IP}" ]]; then
        log "ERROR - Unable to fetch a valid public IP from all configured endpoints."
        exit 1
    fi

    log "Detected public IP: ${CURRENT_IP}"

    CACHED_IP=""
    if [[ -s "${CONF_FILE}" ]]; then
        CACHED_IP="$(tr -d '[:space:]' < "${CONF_FILE}")"
    fi

    if [[ "${CURRENT_IP}" == "${CACHED_IP}" ]]; then
        log "No update required. Current IP matches cached IP (${CURRENT_IP})."
        mark_success
        exit 0
    fi

    log "IP has changed or first run. Updating DNS with new IP (${CURRENT_IP})."
else
    log "FORCE_UPDATE_EACH_CYCLE=1 set. Sending update without local IP comparison."
fi

set +e
UPDATE_RESPONSE="$(request_freedns_update "${UPDATE_URL}")"
REQUEST_EXIT_CODE=$?
set -e
SANITIZED_RESPONSE="$(printf '%s' "${UPDATE_RESPONSE}" | tr '\r\n' ' ' | sed 's/[[:space:]]\+/ /g')"

if (( REQUEST_EXIT_CODE != 0 )); then
    log "ERROR - FreeDNS request failed. ${SANITIZED_RESPONSE}"
    exit 1
fi

# FreeDNS sometimes returns strings like "ERROR: Address x.x.x.x has not changed."
# That should be considered a healthy, successful no-op update.
if [[ "${SANITIZED_RESPONSE}" =~ ([Uu]pdated|[Hh]as[[:space:]]not[[:space:]]changed|[Nn]o[[:space:]]update[[:space:]]required|[Aa]lready) ]]; then
    if [[ -n "${CURRENT_IP}" ]]; then
        printf '%s\n' "${CURRENT_IP}" > "${CONF_FILE}"
        log "Cached IP updated to ${CURRENT_IP}."
    fi
    mark_success
    log "FreeDNS update acknowledged: ${SANITIZED_RESPONSE}"
    exit 0
fi

if [[ "${SANITIZED_RESPONSE}" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
    log "ERROR - FreeDNS returned an error response: ${SANITIZED_RESPONSE}"
    exit 1
fi

log "ERROR - FreeDNS response did not confirm success: ${SANITIZED_RESPONSE}"
exit 1
