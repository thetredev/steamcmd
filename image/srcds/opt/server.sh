#!/bin/bash

if [ $(id -u) -ne ${STEAMCMD_UID} ]; then
    exec runuser -u steamcmd -- ${0} $@
fi



healthy() {
    return $(tmux capture-pane -pt ${STEAMCMD_SERVER_SESSION_NAME} | grep -w "Connection to Steam servers successful." > /dev/null)
}


wait() {
    until ! _is_running srcds; do
        :
    done

    return 0
}


update() {
    tmux send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "steamcmd \
        +force_install_dir ${STEAMCMD_SERVER_HOME} \
        +login anonymous \
        +app_update ${STEAMCMD_SERVER_APPID} validate \
        +quit; tmux wait-for -S steamcmd-update-finished" "Enter"

    tmux wait-for steamcmd-update-finished
}

run() {
    update

    steamcmd_cfg_dir=${STEAMCMD_SERVER_HOME}/${STEAMCMD_SERVER_GAME}/cfg

    # Copy server.cfg file to the server cfg folder if it doesn't exist yet
    if [ ! -f ${steamcmd_cfg_dir}/server.cfg ]; then
        cp /etc/steamcmd/srcds/cfg/server.cfg ${steamcmd_cfg_dir}/server.cfg
    fi

    # Prepare tickrate_enabler.cfg file in the server cfg folder if it doesn't exist yet
    if [ ! -f ${steamcmd_cfg_dir}/tickrate_enabler.cfg ]; then
        echo "sv_minupdaterate ${STEAMCMD_SERVER_TICKRATE}" > ${steamcmd_cfg_dir}/tickrate_enabler.cfg
        echo "sv_mincmdrate ${STEAMCMD_SERVER_TICKRATE}" >> ${steamcmd_cfg_dir}/tickrate_enabler.cfg
        echo "sv_minrate ${STEAMCMD_SERVER_MINRATE}" >> ${steamcmd_cfg_dir}/tickrate_enabler.cfg
        echo "sv_maxrate ${STEAMCMD_SERVER_MAXRATE}" >> ${steamcmd_cfg_dir}/tickrate_enabler.cfg
        echo "fps_max ${STEAMCMD_SERVER_FPSMAX}" >> ${steamcmd_cfg_dir}/tickrate_enabler.cfg
    fi

    tmux send-keys -t ${STEAMCMD_SERVER_SESSION_NAME} "cd ${STEAMCMD_SERVER_HOME}; ./srcds_run \
        -console \
        -game ${STEAMCMD_SERVER_GAME} \
        +ip 0.0.0.0 \
        -port ${STEAMCMD_SERVER_PORT} \
        +maxplayers ${STEAMCMD_SERVER_MAXPLAYERS} \
        +map ${STEAMCMD_SERVER_MAP} \
        -tickrate ${STEAMCMD_SERVER_TICKRATE} \
        -threads ${STEAMCMD_SERVER_THREADS} \
        -nodev" "Enter"
}

attach() {
    if ! ps cax | grep srcds > /dev/null; then
        run
    fi

    tmux a -t ${STEAMCMD_SERVER_SESSION_NAME}
}

${@}
