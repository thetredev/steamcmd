#!/bin/bash

# Create tmux session
tmux new-session -d -s ${STEAMCMD_SERVER_SESSION_NAME}

# Update the server
server.sh update

# Run the server
server.sh run
exec server.sh wait
