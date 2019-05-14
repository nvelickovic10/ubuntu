#!/bin/bash

SCRIPT_START_TIMESTAMP=`date +%s`

# Log end of script
# set -e
function cleanup {
  local RUNTIME=$(($(date +%s)-SCRIPT_START_TIMESTAMP))
  echo
  isRebootRequired
  logInfo "FINISHED ${SCRIPT_NAME} $(date +%Y-%m-%d-%H-%M-%S), RUNTIME: ${RUNTIME} seconds"
}
trap cleanup EXIT

function logInfo {
    echo -e "INFO: $1"
}

function logError {
    echo -e ">>> ERROR: $1"
}

function logDebug {
    echo -e ">>> >>> DEBUG: $1"
}

function isRebootRequired {
    if [ -f /var/run/reboot-required ]; then
        logInfo 'Reboot required'
    fi
}

SCRIPT_NAME="${0##*/}"
logInfo "STARTING ${SCRIPT_NAME} $(date +%Y-%m-%d-%H-%M-%S)"
logInfo "${SCRIPT_DESC}"
echo

#END
