#!/bin/bash

if [ $(id -u) -ne ${STEAMCMD_UID} ]; then
    exec runuser -u steamcmd -- ${0} $@
fi


SIGNAL_SRCDS_HEALTHY="Connection to Steam servers successful."

MESSAGE_PREFIX="[SRCDS]"
MESSAGE_STEAMCMD_USE_ATTACH="Use 'server.sh attach' to attach to the SRCDS tmux session."

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
    return $(tmux capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -w "${SIGNAL_SRCDS_HEALTHY}" > /dev/null)
}


wait() {
    until ! _is_running srcds; do :; done
    return 0
}


attach() {
    tmux a -t ${STEAMCMD_SERVER_SESSION_NAME}
}


update() {
    if _is_running steamcmd; then
        echo ${MESSAGE_STEAMCMD_UPDATE_RUNNING}
        return 1
    fi

    echo ${MESSAGE_STEAMCMD_UPDATE_STARTED}

    tmux send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "steamcmd \
        +force_install_dir ${STEAMCMD_SERVER_HOME} \
        +login anonymous \
        +app_update ${STEAMCMD_SERVER_APPID} validate \
        +quit; tmux wait-for -S steamcmd-update-finished" "Enter"

    tmux wait-for steamcmd-update-finished
    echo ${MESSAGE_STEAMCMD_UPDATE_FINISHED}

    return 0
}


_prepare_tickrate_enabler() {
    cat > ${1} << EOF_TICKRATE_ENABLER_CFG
sv_minupdaterate ${STEAMCMD_SERVER_TICKRATE}
sv_mincmdrate ${STEAMCMD_SERVER_TICKRATE}
sv_minrate ${STEAMCMD_SERVER_MINRATE}
sv_maxrate ${STEAMCMD_SERVER_MAXRATE}
fps_max ${STEAMCMD_SERVER_FPSMAX}
EOF_TICKRATE_ENABLER_CFG
}


run() {
    if _is_running steamcmd; then
        echo ${MESSAGE_STEAMCMD_UPDATE_RUNNING}
        return 1
    fi

    if _is_running srcds; then
        echo ${MESSAGE_STEAMCMD_SERVER_RUNNING}
        return 2
    fi

    steamcmd_cfg_dir=${STEAMCMD_SERVER_HOME}/${STEAMCMD_SERVER_GAME}/cfg

    # Copy server.cfg file to the server cfg folder if it doesn't exist yet
    if [ ! -f ${steamcmd_cfg_dir}/server.cfg ]; then
        cp /etc/steamcmd/srcds/cfg/server.cfg ${steamcmd_cfg_dir}/server.cfg
    fi

    # Prepare tickrate_enabler.cfg file in the server cfg folder if it doesn't exist yet
    if [ ! -f ${steamcmd_cfg_dir}/tickrate_enabler.cfg ]; then
        _prepare_tickrate_enabler "${steamcmd_cfg_dir}/tickrate_enabler.cfg"
    fi

    echo ${MESSAGE_STEAMCMD_SERVER_STARTED}

    tmux send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "cd ${STEAMCMD_SERVER_HOME}; bash ./srcds_run \
        -console \
        -game ${STEAMCMD_SERVER_GAME} \
        +ip 0.0.0.0 \
        -port ${STEAMCMD_SERVER_PORT} \
        ${STEAMCMD_SERVER_MAXPLAYERS} \
        +map ${STEAMCMD_SERVER_MAP} \
        -tickrate ${STEAMCMD_SERVER_TICKRATE} \
        -threads ${STEAMCMD_SERVER_THREADS} \
        -nodev" "Enter"

    until healthy; do
        echo ${MESSAGE_STEAMCMD_SERVER_WAITING}
        sleep 5
    done

    echo ${MESSAGE_STEAMCMD_SERVER_HEALTHY}
    return 0
}


${@}
