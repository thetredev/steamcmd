ARG STEAMRT_PLATFORM_VARIANT
ARG STEAMRT_PLATFORM_VERSION
FROM registry.gitlab.steamos.cloud/steamrt/${STEAMRT_PLATFORM_VARIANT}/platform:${STEAMRT_PLATFORM_VERSION}

# Build arguments
ARG TINI_VERSION=v0.19.0
ARG GOSU_VERSION=1.16

# Prepare image environment
## SteamCMD user
ENV STEAMCMD_USER_HOME=/var/lib/steamcmd \
    STEAMCMD_UID=5000 \
    STEAMCMD_GID=5000
## SteamCMD package & server
ENV STEAMCMD_INSTALL_DIR="${STEAMCMD_USER_HOME}/package" \
    STEAMCMD_SERVER_HOME="${STEAMCMD_USER_HOME}/server"
ENV STEAMCMD_SH="${STEAMCMD_INSTALL_DIR}/steamcmd.sh"
## SteamCMD socket paths
ENV STEAMCMD_SERVER_SOCKET_PATH="/tmp/steamcmd"
ENV STEAMCMD_SERVER_TMUX_SOCKET="${STEAMCMD_SERVER_SOCKET_PATH}/tmux.sock" \
    STEAMCMD_SERVER_LOGS_SOCKET="${STEAMCMD_SERVER_SOCKET_PATH}/logs.sock" \
    STEAMCMD_SERVER_CONSOLE_SOCKET="${STEAMCMD_SERVER_SOCKET_PATH}/console.sock"
## System
ENV TIME_ZONE=UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US \
    LC_ALL=C \
    DEBIAN_FRONTEND=noninteractive

# Configure system
WORKDIR /tmp

RUN dpkg-reconfigure locales
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        # basic tools
        file \
        zip \
        curl \
        unzip \
        tmux \
        procps \
        # SSHD and editors/tools for modifying server files externally
        openssh-server \
        vim \
        nano \
        bash-completion \
        # tools needed for managing unix domain sockets
        netcat-openbsd \
    && \
        # Remve preinstalled SSHD configs
        rm -f /etc/ssh/sshd_config.d/* \
    && \
        # Update CA certificates
        update-ca-certificates \
    && \
        # Disable root login
        chsh -s /usr/sbin/nologin root \
    && \
        # Install and configure tini
        curl -fsSL -o /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64" && \
        chmod +x /usr/local/bin/tini \
    && \
        # Install and configure gosu
        curl -fsSL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" && \
        chmod +x /usr/local/bin/gosu && \
        gosu nobody true \
    && \
        # Configure bash prompt skeleton
        echo "export PS1=$(cat /etc/skel.d/bash_prompt)" >> /etc/bash.bashrc && \
        echo "export PS1=$(cat /etc/skel.d/bash_prompt)" >> /etc/skel/.bashrc \
    && \
        # Create SteamCMD user
        groupadd -r -g "${STEAMCMD_GID}" steamcmd && \
        useradd -ms /bin/bash -d ${STEAMCMD_USER_HOME} -r -l -u "${STEAMCMD_UID}" -g "${STEAMCMD_GID}" steamcmd \
    && \
        # Fix dockle/CIS-DI-0008
        chmod a-s \
            /usr/bin/chage \
            /usr/bin/chfn \
            /usr/bin/chsh \
            /usr/bin/passwd \
            /usr/bin/gpasswd \
            /usr/bin/newgrp \
            /usr/sbin/pam_timestamp_check \
    && \
        apt-get -y clean && \
        rm -rf /var/lib/apt/lists/*

# Switch to SteamCMD user
USER steamcmd

# Set temporary workdir to SteamCMD install dir
WORKDIR ${STEAMCMD_INSTALL_DIR}

# Prepare SteamCMD
RUN curl -fsSL -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm -rf steamcmd_linux.tar.gz && \
    mkdir -p "${HOME}/.steam" && \
    ${STEAMCMD_SH} +quit > /dev/null 2>&1

# Switch back to the root user
USER root

# Set default workdir to SteamCMD server dir
WORKDIR ${STEAMCMD_SERVER_HOME}

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ ${STEAMCMD_INSTALL_DIR} ]

# Copy build context into image
COPY . /

# Declare server health check
HEALTHCHECK --interval=5s --timeout=360s --start-period=15s --retries=20 \
    CMD server.sh healthy

# Set /docker/entrypoint.sh script as default entrypoint
ENTRYPOINT [ "/usr/bin/docker-entrypoint.sh" ]
