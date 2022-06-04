#!/bin/bash

# Configure time zone for runtime
echo "Setting time zone to: ${TIME_ZONE}"
ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

# Set steamcmd user GID and UID
groupmod -g ${STEAMCMD_GID} steamcmd
usermod -u ${STEAMCMD_UID} steamcmd

# Change ownership of steamcmd dumps folder to new steamcmd GID and UID
mkdir -p /tmp/dumps
chown -R steamcmd:steamcmd /tmp/dumps

# Change ownership of steamcmd server folder to new steamcmd GID and UID
chown -R steamcmd:steamcmd ${STEAMCMD_SERVER_HOME}

# Create tmux session
runuser -u steamcmd -- tmux new-session -d -s ${STEAMCMD_SERVER_SESSION_NAME}

# Update the server
server.sh update

# Run the server
server.sh run
exec server.sh wait
