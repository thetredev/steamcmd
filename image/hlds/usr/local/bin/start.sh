#!/bin/bash

# Create tmux session
tmux new-session -d -s ${STEAMCMD_SERVER_SESSION_NAME}

# Update the server
server.sh update

while server.sh update_restart_needed; do
    server.sh clear_console
    server.sh update
done

# Run the server
server.sh run
exec server.sh wait
