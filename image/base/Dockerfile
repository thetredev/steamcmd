ARG STEAMRT_PLATFORM_VERSION=0.20230712.54652
FROM registry.gitlab.steamos.cloud/steamrt/sniper/platform:${STEAMRT_PLATFORM_VERSION}

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
    STEAMCMD_SERVER_HOME="${STEAMCMD_USER_HOME}/server" \
    STEAMCMD_SERVER_SESSION_SOCKET="/tmp/steamcmd/session.sock" \
    STEAMCMD_SERVER_SESSION_FIFO="/tmp/steamcmd/session.fifo"
ENV STEAMCMD_SH="${STEAMCMD_INSTALL_DIR}/steamcmd.sh"
## System
ENV TIME_ZONE=UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US \
    LC_ALL=C \
    DEBIAN_FRONTEND=noninteractive

# Copy build context into image
COPY . /

# Configure system
WORKDIR /tmp

RUN dpkg-reconfigure locales
RUN apt-docker quick-install \
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
    && \
        # Remve preinstalled SSHD configs but keep steamcmd.conf
        mv /etc/ssh/sshd_config.d/steamcmd.conf /tmp/steamcmd.conf && \
        rm -f /etc/ssh/sshd_config.d/* && \
        mv /tmp/steamcmd.conf /etc/ssh/sshd_config.d/steamcmd.conf \
    && \
        # Update CA certificates
        update-ca-certificates \
    && \
        # Link ncurses libs version 6 to 5
        ## x86_64
        ln -sf /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5 && \
        ln -sf /lib/x86_64-linux-gnu/libncursesw.so.6 /lib/x86_64-linux-gnu/libncursesw.so.5 && \
        ## i386
        ln -sf /lib/i386-linux-gnu/libncurses.so.6 /lib/i386-linux-gnu/libncurses.so.5 && \
        ln -sf /lib/i386-linux-gnu/libncursesw.so.6 /lib/i386-linux-gnu/libncursesw.so.5 && \
        # Link tinfo libs version 6 to 5
        ## x86_64
        ln -sf /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5 && \
        ## i386
        ln -sf /lib/i386-linux-gnu/libtinfo.so.6 /lib/i386-linux-gnu/libtinfo.so.5 && \
        # Link ffi libs version 7 to 6
        ## x86_64
        ln -sf /usr/lib/x86_64-linux-gnu/libffi.so.7 /usr/lib/x86_64-linux-gnu/libffi.so.6 && \
        ## i386
        ln -sf /usr/lib/i386-linux-gnu/libffi.so.7 /usr/lib/i386-linux-gnu/libffi.so.6 \
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
            /usr/sbin/pam_timestamp_check

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

# Declare server health check
HEALTHCHECK --interval=5s --timeout=360s --start-period=15s --retries=20 \
    CMD server.sh healthy

# Set /docker/entrypoint.sh script as default entrypoint
ENTRYPOINT [ "/usr/bin/docker-entrypoint.sh" ]
