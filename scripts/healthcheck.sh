#!/usr/bin/env bash

set -Eeuo pipefail

RUNTIME_DIR="${RUNTIME_DIR:-/var/run/freedns}"
LAST_ATTEMPT_FILE="${LAST_ATTEMPT_FILE:-${RUNTIME_DIR}/last_attempt_epoch}"
LAST_SUCCESS_FILE="${LAST_SUCCESS_FILE:-${RUNTIME_DIR}/last_success_epoch}"
UPDATE_INTERVAL="${UPDATE_INTERVAL:-1}"
HEALTHCHECK_GRACE_SECONDS="${HEALTHCHECK_GRACE_SECONDS:-600}"

is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 > 0 ))
}

read_epoch_file() {
    local file_path="$1"
    local value

    if [[ ! -s "${file_path}" ]]; then
        return 1
    fi

    value="$(tr -d '[:space:]' < "${file_path}")"
    if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    printf '%s\n' "${value}"
}

if ! is_positive_int "${UPDATE_INTERVAL}" || ! is_positive_int "${HEALTHCHECK_GRACE_SECONDS}"; then
    exit 1
fi

LAST_ATTEMPT_EPOCH="$(read_epoch_file "${LAST_ATTEMPT_FILE}" || true)"
LAST_SUCCESS_EPOCH="$(read_epoch_file "${LAST_SUCCESS_FILE}" || true)"

if [[ -z "${LAST_ATTEMPT_EPOCH}" || -z "${LAST_SUCCESS_EPOCH}" ]]; then
    exit 1
fi

NOW_EPOCH="$(date +%s)"
MAX_ATTEMPT_AGE=$((UPDATE_INTERVAL * 3600 + HEALTHCHECK_GRACE_SECONDS))
MAX_SUCCESS_AGE=$((MAX_ATTEMPT_AGE * 2))

if (( NOW_EPOCH - LAST_ATTEMPT_EPOCH > MAX_ATTEMPT_AGE )); then
    exit 1
fi

if (( NOW_EPOCH - LAST_SUCCESS_EPOCH > MAX_SUCCESS_AGE )); then
    exit 1
fi

exit 0
