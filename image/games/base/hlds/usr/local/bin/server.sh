#!/bin/bash

if [ $(id -u) -ne ${STEAMCMD_UID} ]; then
    exec gosu steamcmd ${0} $@
fi


source /usr/local/lib/steamcmd/server-common.sh hlds


# Define HLDS-specific signals
SIGNAL_HLDS_UPDATE_FAILED="Error! App '90' state is 0x10E after update job."


# Define HLDS-specific functions
clear_console() {
    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "clear" "Enter"
}


update_restart_needed() {
    return $(${TMUX_CMD} capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -w "${SIGNAL_HLDS_UPDATE_FAILED}" > /dev/null)
}


run() {
    if _is_running steamcmd; then
        echo ${MESSAGE_STEAMCMD_UPDATE_RUNNING}
        return 1
    fi

    if _is_running hlds; then
        echo ${MESSAGE_STEAMCMD_SERVER_RUNNING}
        return 2
    fi

    echo ${MESSAGE_STEAMCMD_SERVER_STARTED}
    hlds_game=$(_get_hlds_game)

    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "cd ${STEAMCMD_SERVER_HOME}; bash ./hlds_run \
        -console \
        -game ${STEAMCMD_SERVER_GAME} \
        +ip 0.0.0.0 \
        -port ${STEAMCMD_SERVER_PORT} \
        +maxplayers ${STEAMCMD_SERVER_MAXPLAYERS} \
        +map ${STEAMCMD_SERVER_MAP}" "Enter"

    until healthy; do
        sleep 5
        echo ${MESSAGE_STEAMCMD_SERVER_WAITING}
    done

    echo ${MESSAGE_STEAMCMD_SERVER_HEALTHY}
    return 0
}


${@}
