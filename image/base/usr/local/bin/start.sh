#!/bin/bash

# Create tmux session
echo "Creating tmux session with socket ${STEAMCMD_SERVER_SESSION_SOCKET}"
tmux -S ${STEAMCMD_SERVER_SESSION_SOCKET} new-session -d -s ${STEAMCMD_SERVER_SESSION_NAME}
chgrp steamcmd ${STEAMCMD_SERVER_SESSION_SOCKET}
chmod g+rwx ${STEAMCMD_SERVER_SESSION_SOCKET}

# Copy tmux config file to socket location
echo "Copying tmux session config file to $(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})/tmux.conf"
cp -f /etc/tmux.conf $(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})/tmux.conf

echo "Linking steamclient.so files..."

mkdir -p ${STEAMCMD_USER_HOME}/.steam/sdk32
ln -sf "${STEAMCMD_INSTALL_DIR}/linux32/steamclient.so" "${STEAMCMD_USER_HOME}/.steam/sdk32/steamclient.so"

if [ -f "${STEAMCMD_INSTALL_DIR}/linux64/steamclient.so" ]; then
    mkdir -p ${STEAMCMD_USER_HOME}/.steam/sdk64
    ln -sf "${STEAMCMD_INSTALL_DIR}/linux64/steamclient.so" "${STEAMCMD_USER_HOME}/.steam/sdk64/steamclient.so"
fi

# Update the server
server.sh update

# Run the server
server.sh run
exec server.sh wait
