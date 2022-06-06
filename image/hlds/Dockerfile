ARG REGISTRY_BASE_IMAGE
FROM ${REGISTRY_BASE_IMAGE}

# Switch to root user for this image
USER root

# Install required packages for HLDS management
RUN yum-docker quick-install \
        ncurses

# Set default environment variables
ENV STEAMCMD_SERVER_APPID=90
ENV STEAMCMD_SERVER_PORT=27015
ENV STEAMCMD_SERVER_GAME=""
ENV STEAMCMD_SERVER_MAP=""
ENV STEAMCMD_SERVER_MAXPLAYERS=32
ENV STEAMCMD_SERVER_SESSION_NAME=hlds

# Copy build context into image
COPY . /

# Symlink /opt/server.sh to /usr/bin/server.sh
RUN ln -sf /opt/server.sh /usr/bin/server.sh

# Declare SRCDS health check
HEALTHCHECK --interval=5s --timeout=360s --start-period=15s --retries=20 \
    CMD server.sh healthy

# Set /docker/entrypoint.sh script as default entrypoint
ENTRYPOINT [ "/docker-entrypoint.sh" ]
