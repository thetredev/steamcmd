ARG REGISTRY_BASE_IMAGE
FROM ${REGISTRY_BASE_IMAGE} AS release

# Set build arguments
ARG STEAMCMD_SERVER_APPID=0 \
    STEAMCMD_SERVER_APP_CONFIG="" \
    STEAMCMD_SERVER_PORT=0 \
    STEAMCMD_SERVER_GAME="" \
    STEAMCMD_SERVER_MAP="" \
    STEAMCMD_SERVER_MAXPLAYERS=0 \
    STEAMCMD_SERVER_MINRATE=0 \
    STEAMCMD_SERVER_MAXRATE=0 \
    STEAMCMD_SERVER_TICKRATE=0 \
    STEAMCMD_SERVER_FPSMAX=0 \
    STEAMCMD_SERVER_THREADS=0 \
    STEAMCMD_SERVER_SESSION_NAME=""

# Translate build arguments into environment variables
ENV STEAMCMD_SERVER_APPID=${STEAMCMD_SERVER_APPID} \
    STEAMCMD_SERVER_APP_CONFIG=${STEAMCMD_SERVER_APP_CONFIG} \
    STEAMCMD_SERVER_PORT=${STEAMCMD_SERVER_PORT} \
    STEAMCMD_SERVER_GAME=${STEAMCMD_SERVER_GAME} \
    STEAMCMD_SERVER_MAP=${STEAMCMD_SERVER_MAP} \
    STEAMCMD_SERVER_MAXPLAYERS=${STEAMCMD_SERVER_MAXPLAYERS} \
    STEAMCMD_SERVER_MINRATE=${STEAMCMD_SERVER_MINRATE} \
    STEAMCMD_SERVER_MAXRATE=${STEAMCMD_SERVER_MAXRATE} \
    STEAMCMD_SERVER_TICKRATE=${STEAMCMD_SERVER_TICKRATE} \
    STEAMCMD_SERVER_FPSMAX=${STEAMCMD_SERVER_FPSMAX} \
    STEAMCMD_SERVER_THREADS=${STEAMCMD_SERVER_THREADS} \
    STEAMCMD_SERVER_SESSION_NAME=${STEAMCMD_SERVER_SESSION_NAME}

ENV STEAMCMD_SERVER_SESSION_SOCKET="/tmp/steamcmd/${STEAMCMD_SERVER_SESSION_NAME}.sock" \
    STEAMCMD_SERVER_SESSION_FIFO="/tmp/steamcmd/${STEAMCMD_SERVER_SESSION_NAME}.fifo"


# Temporary build stage to get the build context for the specific engine only
FROM release AS context
USER root

WORKDIR /tmp/context-tmp
COPY . .

WORKDIR /tmp/context
RUN mv -f /tmp/context-tmp/docker-entrypoint.sh /tmp/context && \
    mv -f /tmp/context-tmp/usr /tmp/context && \
    cp -r /tmp/context-tmp/${STEAMCMD_SERVER_SESSION_NAME}/* /tmp/context && \
    rm -rf /tmp/context-tmp


# Continue building the main stage
FROM release
COPY --from=context /tmp/context /

# Switch to root user for this image
USER root

# Declare server health check
HEALTHCHECK --interval=5s --timeout=360s --start-period=15s --retries=20 \
    CMD server.sh healthy

# Set /docker/entrypoint.sh script as default entrypoint
ENTRYPOINT [ "/docker-entrypoint.sh" ]
