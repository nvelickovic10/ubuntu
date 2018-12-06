#!/bin/bash
logInfo "Loading sudoUtil"
logInfo "Current user: $(whoami)"
echo ""

function checkSudoPrivileges {
    # Check if script has root privileges
    if [ "$EUID" -ne 0 ]
    then logError "Please run as root"
    exit 1
    fi
}

function runAsSudo {
    local COMMAND="sudo bash -c '${1}'"
    logInfo "run as sudo: ${COMMAND}" > /dev/stderr
    [ "$UID" -eq 0 ] || eval "$COMMAND"
    echo > /dev/stderr
}