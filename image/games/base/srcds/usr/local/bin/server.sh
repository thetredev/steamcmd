#!/bin/bash

if [ $(id -u) -ne ${STEAMCMD_UID} ]; then
    exec gosu steamcmd ${0} $@
fi


source /usr/local/lib/steamcmd/server-common.sh srcds


# Define SRCDS-specific functions
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

    # Prepare tickrate_enabler.cfg file in the server cfg folder
    _prepare_tickrate_enabler "${steamcmd_cfg_dir}/tickrate_enabler.cfg"

    echo ${MESSAGE_STEAMCMD_SERVER_STARTED}

    ${TMUX_CMD} send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "cd ${STEAMCMD_SERVER_HOME}; bash ./srcds_run \
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
        sleep 5
        echo ${MESSAGE_STEAMCMD_SERVER_WAITING}
    done

    echo ${MESSAGE_STEAMCMD_SERVER_HEALTHY}
    return 0
}


${@}
