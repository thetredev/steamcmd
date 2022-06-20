#!/bin/bash

# Set original entrypoint
set -- tini -- start.sh ${@}

# Fix file and directory permissions if run as root
if [ $(id -u) -eq 0 ]; then

    # Configure time zone for runtime
    echo "Setting time zone to: ${TIME_ZONE}"
    ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

    # Set steamcmd user GID and UID
    echo "Setting steamcmd user GID to ${STEAMCMD_GID}"
    groupmod -g ${STEAMCMD_GID} steamcmd

    echo "Setting steamcmd user UID to ${STEAMCMD_UID}"
    usermod -u ${STEAMCMD_UID} steamcmd

    # Change ownership of steamcmd dumps folder to new steamcmd GID and UID
    echo "Fixing ownership of /tmp/dumps"
    mkdir -p /tmp/dumps
    chown -R steamcmd:steamcmd /tmp/dumps

    # Change ownership of steamcmd server folder to new steamcmd GID and UID
    echo "Fixing ownership of ${STEAMCMD_SERVER_HOME}"
    chown -R steamcmd:steamcmd ${STEAMCMD_SERVER_HOME}

    # Change ownership of tmux session folder to new steamcmd GID and UID
    tmux_socket_dir=$(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})
    echo "Fixing ownership of ${tmux_socket_dir}"
    mkdir -p ${tmux_socket_dir}
    chown -R steamcmd:steamcmd ${tmux_socket_dir}

    # Call to gosu to drop from root user to steamcmd user
    # when running original entrypoint
    set -- gosu steamcmd $@
fi

exec ${@}
