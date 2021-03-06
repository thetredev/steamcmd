#!/bin/bash

command="${1}"
command_upper=$(echo ${command} | tr '[:lower:]' '[:upper:]')


# Prefix tmux with shared session socket
TMUX_CMD="tmux -S ${STEAMCMD_SERVER_SESSION_SOCKET}"


# Define common healthy signal
SIGNAL_SERVER_HEALTHY="Connection to Steam servers successful."


# Define common messages
MESSAGE_PREFIX="[${command_upper}]"
MESSAGE_STEAMCMD_USE_ATTACH="Use 'server.sh attach' to attach to the ${command_upper} tmux session."

MESSAGE_STEAMCMD_UPDATE_STARTED="${MESSAGE_PREFIX} Updating game server... ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_UPDATE_RUNNING="${MESSAGE_PREFIX} SteamCMD is currently updating. ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_UPDATE_FINISHED="${MESSAGE_PREFIX} Update finished."

MESSAGE_STEAMCMD_SERVER_STARTED="${MESSAGE_PREFIX} Server started in tmux session. ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_SERVER_WAITING="${MESSAGE_PREFIX} Waiting for server to become healthy..."
MESSAGE_STEAMCMD_SERVER_RUNNING="${MESSAGE_PREFIX} Server is currently running. ${MESSAGE_STEAMCMD_USE_ATTACH}"
MESSAGE_STEAMCMD_SERVER_HEALTHY="${MESSAGE_PREFIX} Server is healthy! ${MESSAGE_STEAMCMD_USE_ATTACH}"


# Define common functions
_is_running() {
    return $(ps cax | grep ${1} > /dev/null)
}


healthy() {
    return $(${TMUX_CMD} capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -w "${SIGNAL_SERVER_HEALTHY}" > /dev/null)
}


wait() {
    until ! _is_running ${command}; do :; done

    ${TMUX_CMD} kill-session -t ${STEAMCMD_SERVER_SESSION_NAME}
    ${TMUX_CMD} kill-server

    return 0
}


attach() {
    ${TMUX_CMD} a -t ${STEAMCMD_SERVER_SESSION_NAME}
}


_update() {
    if _is_running steamcmd; then
        echo ${MESSAGE_STEAMCMD_UPDATE_RUNNING}
        return 1
    fi

    echo ${MESSAGE_STEAMCMD_UPDATE_STARTED}

    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "steamcmd \
        +force_install_dir ${STEAMCMD_SERVER_HOME} \
        +login anonymous \
        ${STEAMCMD_SERVER_APP_CONFIG} \
        +app_update ${STEAMCMD_SERVER_APPID} validate \
        +quit; ${TMUX_CMD} wait-for -S steamcmd-update-finished" "Enter"

    ${TMUX_CMD} wait-for steamcmd-update-finished
    echo ${MESSAGE_STEAMCMD_UPDATE_FINISHED}

    return 0
}
