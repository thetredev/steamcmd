FROM almalinux:9.1-minimal-20230222

# Build arguments
ARG TINI_VERSION=v0.19.0
ARG GOSU_VERSION=1.14

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
## System
ENV TIME_ZONE=UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US \
    LC_ALL=C \
    PATH=${PATH}:${STEAMCMD_INSTALL_DIR}

# Copy build context into image
COPY . /

# Configure system
WORKDIR /tmp

RUN yum-docker quick-install \
        # basic system packages
        glibc-langpack-en \
        util-linux-user \
        ncurses \
        # basic tools
        file \
        zip \
        unzip \
        tmux \
        procps \
        tar \
        passwd \
        shadow-utils \
        # required packages for SteamCMD
        ncurses-libs.i686 \
        SDL2.i686 \
        # required for some server addons
        libffi \
        libffi.i686 \
        zlib \
        zlib.i686 \
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
        # Update CA trust
        update-ca-trust \
    && \
        # Link ncurses and tinfo libs version 6 to 5
        ln -sf /usr/lib/libncurses++.so.6 /usr/lib/libncurses++.so.5 && \
        ln -sf /usr/lib/libncurses++w.so.6 /usr/lib/libncurses++w.so.5 && \
        ln -sf /usr/lib/libncurses.so.6 /usr/lib/libncurses.so.5 && \
        ln -sf /usr/lib/libncursesw.so.6 /usr/lib/libncursesw.so.5 && \
        ln -sf /usr/lib/libncurses++.so.6 /usr/lib/libncurses++.so.5 && \
        ln -sf /usr/lib/libtinfo.so.6 /usr/lib/libtinfo.so.5 && \
        # Link libffi.so.8 to libffi.so.6
        ln -sf /usr/lib/libffi.so.8 /usr/lib/libffi.so.6 && \
        ln -sf /usr/lib64/libffi.so.8 /usr/lib64/libffi.so.6 \
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
            /usr/bin/mount \
            /usr/bin/umount \
            /usr/bin/passwd \
            /usr/bin/gpasswd \
            /usr/bin/newgrp \
            /usr/sbin/unix_chkpwd \
            /usr/bin/su \
            /usr/sbin/pam_timestamp_check \
            /usr/libexec/utempter/utempter \
            /usr/bin/write \
            /usr/libexec/openssh/ssh-keysign

# Switch to SteamCMD user
USER steamcmd

# Set temporary workdir to SteamCMD install dir
WORKDIR ${STEAMCMD_INSTALL_DIR}

# Prepare SteamCMD
RUN curl -fsSL -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm -rf steamcmd_linux.tar.gz && \
    ln -sf "$(pwd)/steamcmd.sh" "$(pwd)/steamcmd" && \
    mkdir -p "${HOME}/.steam" && \
    steamcmd +quit > /dev/null 2>&1

# Switch back to the root user
USER root

# Link SteamCMD libstdc++ library to system
RUN ln -sf ${STEAMCMD_INSTALL_DIR}/linux32/libstdc++.so.6 /usr/lib/libstdc++.so.6

# Set default workdir to SteamCMD server dir
WORKDIR ${STEAMCMD_SERVER_HOME}

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ ${STEAMCMD_INSTALL_DIR} ]

# Declare server health check
HEALTHCHECK --interval=5s --timeout=360s --start-period=15s --retries=20 \
    CMD server.sh healthy

# Set /docker/entrypoint.sh script as default entrypoint
ENTRYPOINT [ "/usr/bin/docker-entrypoint.sh" ]
