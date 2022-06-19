#!/bin/bash

# Create tmux session
tmux -S ${STEAMCMD_SERVER_SESSION_SOCKET} new-session -d -s ${STEAMCMD_SERVER_SESSION_NAME}
chgrp steamcmd ${STEAMCMD_SERVER_SESSION_SOCKET}
chmod g+rwx ${STEAMCMD_SERVER_SESSION_SOCKET}

# Update the server
server.sh update

# Run the server
server.sh run
exec server.sh wait
