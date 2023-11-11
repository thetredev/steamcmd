#!/bin/bash

if [[ $(id -u) -ne ${STEAMCMD_UID} ]]; then
    exec gosu steamcmd ${0} $@
fi


source /usr/local/lib/steamcmd/server-common.sh srcds


# Define SRCDS-specific functions
_server_requires_hibernation_hooks() {
    local hibernation_hooks_appids="730 346680" # CS2, BMS

    for hibernation_hooks_appid in ${hibernation_hooks_appids}; do
        test "${STEAMCMD_SERVER_APPID}" = "${hibernation_hooks_appid}" && return 0
    done

    return 1
}


_enable_tickrate() {
    if [ ${STEAMCMD_SERVER_TICKRATE} -gt 64 ]; then
        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "sv_minupdaterate ${STEAMCMD_SERVER_TICKRATE}" "Enter"
        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "sv_mincmdrate ${STEAMCMD_SERVER_TICKRATE}" "Enter"
        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "sv_minrate ${STEAMCMD_SERVER_MINRATE}" "Enter"
        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "sv_maxrate ${STEAMCMD_SERVER_MAXRATE:-0}" "Enter"
    fi
}


_setup_hibernation_hook_attached() {
    ${TMUX_CMD} set-hook -t ${STEAMCMD_SERVER_SESSION_NAME} -u client-attached
    ${TMUX_CMD} set-hook -t ${STEAMCMD_SERVER_SESSION_NAME} client-attached 'send-keys "sv_hibernate_when_empty 0" "Enter"'
}


_setup_hibernation_hook_detached() {
    ${TMUX_CMD} set-hook -t ${STEAMCMD_SERVER_SESSION_NAME} -u client-detached
    ${TMUX_CMD} set-hook -t ${STEAMCMD_SERVER_SESSION_NAME} client-detached 'send-keys "sv_hibernate_when_empty 1" "Enter"'
}


_setup_hibernation_hooks() {
    if _is_attached; then
        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "sv_hibernate_when_empty 0" "Enter"
    fi

    _setup_hibernation_hook_detached
    _setup_hibernation_hook_attached
}


attach() {
    _attach
}


update() {
    _update
}


run() {
    pre_exit_code=$(_run_pre)

    if ! $pre_exit_code; then
        return $pre_exit_code
    fi

    echo ${MESSAGE_STEAMCMD_SERVER_STARTED}

    if [[ "${STEAMCMD_SERVER_APPID}" = "730" ]]; then
        ln -sf ${STEAMCMD_SERVER_HOME}/game/bin/linuxsteamrt64/cs2 ${STEAMCMD_SERVER_HOME}/game/bin/linuxsteamrt64/srcds

        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "cd ${STEAMCMD_SERVER_HOME}/game/bin/linuxsteamrt64; ./srcds \
            -dedicated \
            +map ${STEAMCMD_SERVER_MAP} \
            +ip 0.0.0.0 \
            -port ${STEAMCMD_SERVER_PORT} \
            -maxplayers ${STEAMCMD_SERVER_MAXPLAYERS} \
            +fps_max ${STEAMCMD_SERVER_FPSMAX}" "Enter"
    else
        ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "cd ${STEAMCMD_SERVER_HOME}; bash ./srcds_run \
            -console \
            -game ${STEAMCMD_SERVER_GAME} \
            +ip 0.0.0.0 \
            -port ${STEAMCMD_SERVER_PORT} \
            +maxplayers ${STEAMCMD_SERVER_MAXPLAYERS} \
            +map ${STEAMCMD_SERVER_MAP} \
            -tickrate ${STEAMCMD_SERVER_TICKRATE} \
            -threads ${STEAMCMD_SERVER_THREADS} \
            +fps_max ${STEAMCMD_SERVER_FPSMAX} \
            -nodev" "Enter"
    fi

    _run_post

    if _server_requires_hibernation_hooks; then
        _setup_hibernation_hooks
    fi

    test "${STEAMCMD_SERVER_APPID}" != "730" && _enable_tickrate

    return 0
}


${@}
