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
    logInfo "run as sudo: ${1}" > /dev/stderr
    local COMMAND="sudo bash -c '${1}'"
    #[ "$UID" -eq 0 ] || 
    eval "$COMMAND"
    echo > /dev/stderr
}

runAsSudo "" 2 > /dev/null