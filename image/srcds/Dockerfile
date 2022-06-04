ARG REGISTRY_BASE_IMAGE
FROM ${REGISTRY_BASE_IMAGE}

# Switch to root user for this image
USER root

# Install required packages for SRCDS execution
RUN yum-docker quick-install --enablerepo=powertools \
        ncurses-compat-libs.i686 \
        SDL2 \
        SDL2.i686

# Set default environment variables
ENV STEAMCMD_SERVER_APPID=0
ENV STEAMCMD_SERVER_PORT=0
ENV STEAMCMD_SERVER_GAME=""
ENV STEAMCMD_SERVER_MAP=""
ENV STEAMCMD_SERVER_MAXPLAYERS="+maxplayers 32"
ENV STEAMCMD_SERVER_MINRATE=80000
ENV STEAMCMD_SERVER_MAXRATE=0
ENV STEAMCMD_SERVER_TICKRATE=128
ENV STEAMCMD_SERVER_FPSMAX=300
ENV STEAMCMD_SERVER_THREADS=3
ENV STEAMCMD_SERVER_SESSION_NAME=srcds

# Copy build context into image
COPY . /

# Symlink /opt/server.sh to /usr/bin/server.sh
RUN ln -sf /opt/server.sh /usr/bin/server.sh

# Declare SRCDS health check
HEALTHCHECK --interval=5s --timeout=360s --start-period=15s --retries=20 \
    CMD server.sh healthy

# Set /docker/entrypoint.sh script as default entrypoint
ENTRYPOINT [ "/docker-entrypoint.sh" ]
