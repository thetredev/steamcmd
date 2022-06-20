#!/bin/bash

if [ $(id -u) -ne ${STEAMCMD_UID} ]; then
    exec gosu steamcmd ${0} $@
fi


# Prefix tmux with shared session socket
TMUX_CMD="tmux -S ${STEAMCMD_SERVER_SESSION_SOCKET}"


SIGNAL_HLDS_HEALTHY="Connection to Steam servers successful."
SIGNAL_HLDS_UPDATE_FAILED="Error! App '90' state is 0x10E after update job."

MESSAGE_PREFIX="[HLDS]"
MESSAGE_STEAMCMD_USE_ATTACH="Use 'server.sh attach' to attach to the HLDS tmux session."

MESSAGE_STEAMCMD_UPDATE_STARTED="${MESSAGE_PREFIX} Updating game server... ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_UPDATE_RUNNING="${MESSAGE_PREFIX} SteamCMD is currently updating. ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_UPDATE_FINISHED="${MESSAGE_PREFIX} Update finished."

MESSAGE_STEAMCMD_SERVER_STARTED="${MESSAGE_PREFIX} Server started in tmux session. ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_SERVER_WAITING="${MESSAGE_PREFIX} Waiting for server to become healthy..."
MESSAGE_STEAMCMD_SERVER_RUNNING="${MESSAGE_PREFIX} Server is currently running. ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_SERVER_HEALTHY="${MESSAGE_PREFIX} Server is healthy! ${MESSAGE_STEAMCMD_USE_ATTACH}"


_is_running() {
    return $(ps cax | grep ${1} > /dev/null)
}


healthy() {
    return $(${TMUX_CMD} capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -w "${SIGNAL_HLDS_HEALTHY}" > /dev/null)
}


clear_console() {
    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "clear" "Enter"
}


wait() {
    until ! _is_running hlds; do :; done

    ${TMUX_CMD} kill-session ${STEAMCMD_SERVER_SESSION_NAME}
    ${TMUX_CMD} kill-server

    return 0
}


attach() {
    ${TMUX_CMD} a -t ${STEAMCMD_SERVER_SESSION_NAME}
}


update_restart_needed() {
    return $(${TMUX_CMD} capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -w "${SIGNAL_HLDS_UPDATE_FAILED}" > /dev/null)
}


update() {
    if _is_running steamcmd; then
        echo ${MESSAGE_STEAMCMD_UPDATE_RUNNING}
        return 1
    fi

    echo ${MESSAGE_STEAMCMD_UPDATE_STARTED}

    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "steamcmd \
        +force_install_dir ${STEAMCMD_SERVER_HOME} \
        +login anonymous \
        +app_update ${STEAMCMD_SERVER_APPID} validate \
        +quit; ${TMUX_CMD} wait-for -S steamcmd-update-finished" "Enter"

    ${TMUX_CMD} wait-for steamcmd-update-finished
    echo ${MESSAGE_STEAMCMD_UPDATE_FINISHED}

    return 0
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
