#!/bin/bash

# Create tmux session
echo "Creating tmux session with socket ${STEAMCMD_SERVER_SESSION_SOCKET}"
tmux -S ${STEAMCMD_SERVER_SESSION_SOCKET} new-session -d -s ${STEAMCMD_SERVER_SESSION_NAME}
chgrp steamcmd ${STEAMCMD_SERVER_SESSION_SOCKET}
chmod g+rwx ${STEAMCMD_SERVER_SESSION_SOCKET}

# Copy tmux config file to socket location
echo "Copying tmux session config file to $(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})/tmux.conf"
cp -f /etc/tmux.conf $(dirname ${STEAMCMD_SERVER_SESSION_SOCKET})/tmux.conf

# Update the server
server.sh update

# Run the server
server.sh run
exec server.sh wait
