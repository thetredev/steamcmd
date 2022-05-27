#!/bin/bash

# Configure time zone for runtime
ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
dpkg-reconfigure tzdata

# Set steamcmd user GID and UID
groupmod -g ${STEAMCMD_GID} steamcmd
usermod -u ${STEAMCMD_UID} steamcmd

# Change ownership of steamcmd dumps folder to new steamcmd GID and UID
mkdir -p /tmp/dumps
chown -R steamcmd:steamcmd /tmp/dumps

# Change ownership of steamcmd server folder to new steamcmd GID and UID
chown -R steamcmd:steamcmd ${STEAMCMD_SERVER_HOME}

# Execute server.sh
exec /opt/server.sh $@
