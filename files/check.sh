#!/usr/bin/env bash
# vim: ft=bash
set -uo pipefail

NAME=""
DOMAIN="system"
WARNING=0
DISABLED=0

# Parse CLI flags
while (($#)); do
  case "$1" in
    --name=*)   NAME="${1#*=}" ;;
    --user)     DOMAIN="user/$(id -u)" ;;
    --disabled) DISABLED=1 ;;
    --warning)  WARNING=1 ;;
    -*|--*)     echo "ERROR unknown option: $1"; exit 1;;
  esac
  shift
done

[[ -z "${NAME}" ]] && { echo "No job name provided!"; exit 1; }

if [[ -z "${DOMAIN}" ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    DOMAIN="system"
  else
    DOMAIN="gui/$(id -u)"
  fi
fi

TARGET="${DOMAIN}/${NAME}"

JOB_STATUS="MISSING"
JOB_SWITCH="UNKNOWN"
JOB_HEALTH="UNKNOWN"
LAST_EXIT_CODE="UNKNOWN"

if JOB_OUT="$(launchctl print "${TARGET}" 2>/dev/null)"; then
  JOB_STATUS="LOADED"

  JOB_HEALTH=$(
    awk -F'= ' '
      /^[[:space:]]*state = / { gsub(/ /, "_", $2); print toupper($2); found=1; exit }
      END { if (!found) print "unknown" }
    ' <<< "${JOB_OUT}"
  )

  LAST_EXIT_CODE=$(
    awk -F'= ' '
      /^[[:space:]]*last exit code = / { print $2; found=1; exit }
      END { if (!found) print "0" }
    ' <<< "${JOB_OUT}"
  )
fi

DISABLED_OUT="$(launchctl print-disabled "${DOMAIN}" 2>/dev/null || true)"

if grep -Eq "\"${NAME}\"[[:space:]]*=>[[:space:]]*disabled" <<< "${DISABLED_OUT}"; then
  JOB_SWITCH="DISABLED"
else
  JOB_SWITCH="ENABLED"
fi

# Print current state.
echo "${NAME}: ${JOB_STATUS}, ${JOB_SWITCH}, ${JOB_HEALTH}, last_exit_code=${LAST_EXIT_CODE}"

function fail { [[ "${WARNING}" == 1 ]] && exit 1 || exit 2; }

# Verify health.
[[ "${DISABLED}" -eq 1 ]] && exit 0

[[ "${JOB_STATUS}" != "LOADED" ]]             && fail
[[ "${JOB_SWITCH}" == "DISABLED" ]]           && fail
[[ "${LAST_EXIT_CODE}" == "(never exited)" ]] && exit 0
[[ "${LAST_EXIT_CODE}" != "0" ]]              && fail
