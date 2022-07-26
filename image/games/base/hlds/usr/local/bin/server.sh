#!/bin/bash

if [ $(id -u) -ne ${STEAMCMD_UID} ]; then
    exec gosu steamcmd ${0} $@
fi


source /usr/local/lib/steamcmd/server-common.sh hlds


# Define HLDS-specific signals
SIGNAL_HLDS_UPDATE_FAILED="Error! App '90' state is 0x[0-9a-fA-f]{1,6} after update job."


# Define HLDS-specific functions
_clear_console() {
    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "clear && printf '\e[3J'" "Enter"
}


_update_restart_needed() {
    return $(${TMUX_CMD} capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -E "${SIGNAL_HLDS_UPDATE_FAILED}" > /dev/null)
}


attach() {
    _attach
}


update() {
    _update

    while _update_restart_needed; do
        _clear_console
        _update
    done
}


run() {
    pre_exit_code=$(_run_pre)

    if ! $pre_exit_code; then
        return $pre_exit_code
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

    _run_post
    return 0
}


${@}
