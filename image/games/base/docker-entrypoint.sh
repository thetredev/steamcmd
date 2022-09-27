#!/bin/bash

# Set original entrypoint
set -- tini -- start.sh ${@}

# Helper function to set time zone
_prepare_time_zone() {
    echo "Setting time zone to: ${TIME_ZONE}"
    ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
}

# Helper function to prepare the steamcmd user
_prepare_steamcmd_user() {
    # Fix group ID
    echo "Setting steamcmd user GID to ${STEAMCMD_GID}"
    groupmod -g ${STEAMCMD_GID} steamcmd

    # Fix user ID
    echo "Setting steamcmd user UID to ${STEAMCMD_UID}"
    usermod -u ${STEAMCMD_UID} steamcmd

    # Fix ownership of user home directory
    echo "Fixing ownership of ${STEAMCMD_USER_HOME}"
    cp -rT /etc/skel ${STEAMCMD_USER_HOME}
    chown -R steamcmd:steamcmd ${STEAMCMD_USER_HOME}
}

# Helper function to fix steamcmd dumps ownership
_fix_steamcmd_dumps_ownership() {
    echo "Fixing ownership of /tmp/dumps"
    mkdir -p /tmp/dumps
    chown -R steamcmd:steamcmd /tmp/dumps
}

# Helper function to fix tmux session dir ownership
_fix_tmux_session_dir_ownership() {
    tmux_socket_dir=$(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})

    echo "Fixing ownership of ${tmux_socket_dir}"
    mkdir -p ${tmux_socket_dir}
    chown -R steamcmd:steamcmd ${tmux_socket_dir}
}

# Helper function to fix host keys should they not exist
_prepare_ssh_host_key() {
    local host_key_type="${1}"
    local host_key_path="/opt/ssh/ssh_host_${host_key_type}_key"

    if [[ ! -f ${host_key_path} ]]; then
        rm -f "${host_key_path}*"
        ssh-keygen -q -N "" -t ${host_key_type} -f ${host_key_path}
    fi
}

# Helper function to prepare the SSH server
_prepare_ssh_server() {
    _ssh_keys="${STEAMCMD_SSH_AUTHORIZED_KEYS}"

    if [[ ${_ssh_keys} != ssh-* ]]; then
        _ssh_keys=$(echo -n "${STEAMCMD_SSH_AUTHORIZED_KEYS}" | base64 -d 2>&1) > /dev/null
    fi

    if [[ ${_ssh_keys} == ssh-* ]]; then
        echo "Preparing SSH server..."
        mkdir -p "${STEAMCMD_USER_HOME}/.ssh"
        echo ${_ssh_keys} > "${STEAMCMD_USER_HOME}/.ssh/authorized_keys"

        chown -R steamcmd:steamcmd "${STEAMCMD_USER_HOME}/.ssh"
        chmod 0700 "${STEAMCMD_USER_HOME}/.ssh"
        chmod 0600 "${STEAMCMD_USER_HOME}/.ssh/authorized_keys"

        mkdir -p /opt/ssh
        _prepare_ssh_host_key "dsa"
        _prepare_ssh_host_key "rsa"
        _prepare_ssh_host_key "ecdsa"
        _prepare_ssh_host_key "ed25519"

        # Add container environment as system environment variables to make them available in SSH sessions
        env | grep STEAMCMD_ > /etc/environment

        # Run the server
        /usr/sbin/sshd
    else
        echo "Couldn't parse SSH authorized keys configuration, ignoring..."
    fi
}

# Fix file and directory permissions if run as root
if [ $(id -u) -eq 0 ]; then
    _prepare_time_zone
    _prepare_steamcmd_user
    _fix_steamcmd_dumps_ownership
    _fix_tmux_session_dir_ownership

    if [[ "${STEAMCMD_SSH_SERVER_ENABLE}" == "1" ]]; then
        _prepare_ssh_server
    fi

    # Call to gosu to drop from root user to steamcmd user
    # when running original entrypoint
    set -- gosu steamcmd $@
fi

exec ${@}
