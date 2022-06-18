ARG REGISTRY_BASE_IMAGE
FROM ${REGISTRY_BASE_IMAGE}

# Switch to root user for this image
USER root

# Temporarily switch workdir to /tmp
WORKDIR /tmp

# Install required packages for SRCDS execution
RUN yum-docker quick-install \
        ncurses-libs.i686 \
        SDL2 \
        SDL2.i686

# Link ncurses and tinfo libs version 6 to 5 as described in
# https://access.redhat.com/solutions/6907421
RUN ln -sf $(ls /usr/lib/libncurses++.so.6) /usr/lib/libncurses++.so.5 && \
    ln -sf $(ls /usr/lib/libncurses++w.so.6) /usr/lib/libncurses++w.so.5 && \
    ln -sf $(ls /usr/lib/libncurses.so.6) /usr/lib/libncurses.so.5 && \
    ln -sf $(ls /usr/lib/libncursesw.so.6) /usr/lib/libncursesw.so.5 && \
    ln -sf $(ls /usr/lib/libncurses++.so.6) /usr/lib/libncurses++.so.5 && \
    ln -sf $(ls /usr/lib/libtinfo.so.6) /usr/lib/libtinfo.so.5 && \
    ldconfig && \
    rm -rf /tmp/*

# Switch back workdir to SteamCMD server home
WORKDIR ${STEAMCMD_SERVER_HOME}

# Set default environment variables
ENV STEAMCMD_SERVER_APPID=0
ENV STEAMCMD_SERVER_PORT=27015
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
