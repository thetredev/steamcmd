#!/bin/bash

# Set original entrypoint
set -- tini -- start.sh ${@}

# Helper function to fix host keys should they not exist
prepare_ssh_host_key() {
    host_key_type="${1}"
    host_key_path="/opt/ssh/ssh_host_${host_key_type}_key"

    if [[ ! -f ${host_key_path} ]]; then
        rm -f "${host_key_path}*"
        ssh-keygen -q -N "" -t ${host_key_type} -f ${host_key_path}
    fi
}

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

    # Change ownership of steamcmd user folder to new steamcmd GID and UID
    echo "Fixing ownership of ${STEAMCMD_USER_HOME}"
    cp -rT /etc/skel ${STEAMCMD_USER_HOME}
    chown -R steamcmd:steamcmd ${STEAMCMD_USER_HOME}

    # Change ownership of tmux session folder to new steamcmd GID and UID
    tmux_socket_dir=$(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})
    echo "Fixing ownership of ${tmux_socket_dir}"
    mkdir -p ${tmux_socket_dir}
    chown -R steamcmd:steamcmd ${tmux_socket_dir}

    if [[ "${STEAMCMD_SSH_SERVER_ENABLE}" == "1" ]]; then
        # Prepare SSH server
        echo "Preparing SSH server..."
        mkdir -p "${STEAMCMD_USER_HOME}/.ssh"

        echo -n "${STEAMCMD_SSH_AUTHORIZED_KEYS}" | base64 -d > "${STEAMCMD_USER_HOME}/.ssh/authorized_keys"

        if [ $? -ne 0 ]; then
            echo "${STEAMCMD_SSH_AUTHORIZED_KEYS}" > "${STEAMCMD_USER_HOME}/.ssh/authorized_keys"
        fi

        chown -R steamcmd:steamcmd "${STEAMCMD_USER_HOME}/.ssh"
        chmod 0700 "${STEAMCMD_USER_HOME}/.ssh"
        chmod 0600 "${STEAMCMD_USER_HOME}/.ssh/authorized_keys"

        mkdir -p /opt/ssh
        prepare_ssh_host_key "dsa"
        prepare_ssh_host_key "rsa"
        prepare_ssh_host_key "ecdsa"
        prepare_ssh_host_key "ed25519"

        # Add container environment as system environment variables to make them available in SSH sessions
        env | grep STEAMCMD_ > /etc/environment

        # Run the server
        /usr/sbin/sshd
    fi

    # Call to gosu to drop from root user to steamcmd user
    # when running original entrypoint
    set -- gosu steamcmd $@
fi

exec ${@}
