FROM almalinux:9.0-minimal-20220527

# Build arguments
ARG TINI_VERSION=v0.19.0
ARG GOSU_VERSION=1.14

# Prepare image environment
## SteamCMD
ENV STEAMCMD_INSTALL_DIR=/home/steamcmd/package \
    STEAMCMD_SERVER_HOME=/var/lib/steamcmd/server \
    STEAMCMD_UID=5000 \
    STEAMCMD_GID=5000
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

RUN sed -i '/\[main\]/a install_weak_deps=False' /etc/dnf/dnf.conf && \
    yum-docker quick-install \
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
        rm -rf /tmp/* \
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
        # Prepare SteamCMD server directory
        mkdir -p ${STEAMCMD_SERVER_HOME} \
    && \
        # Create SteamCMD user
        groupadd -r -g "${STEAMCMD_GID}" steamcmd && \
        useradd -ms /bin/bash -r -l -u "${STEAMCMD_UID}" -g "${STEAMCMD_GID}" steamcmd \
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
            /usr/bin/write

# Switch to SteamCMD user
USER steamcmd

# Set temporary workdir to SteamCMD install dir
WORKDIR ${STEAMCMD_INSTALL_DIR}

# Prepare SteamCMD
RUN curl -fsSL -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm -rf steamcmd_linux.tar.gz && \
    ln -sf "$(pwd)/steamcmd.sh" "$(pwd)/steamcmd" && \
    mkdir -p "${HOME}/.steam" \
    && \
        # Run SteamCMD once to install
        steamcmd +quit > /dev/null 2>&1 \
    && \
        # Fix SteamCMD runtime error
        # [S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.
        ln -sf "$(pwd)/linux32" "${HOME}/.steam/sdk32"

# Link SteamCMD libstdc++ library to system
USER root
RUN ln -sf ${STEAMCMD_INSTALL_DIR}/linux32/libstdc++.so.6 /usr/lib/libstdc++.so.6

# Fix dockle/CIS-DI-0008
RUN chmod a-s \
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
        /usr/bin/write

# Set default user to steamcmd
USER steamcmd

# Set default workdir to SteamCMD server dir
WORKDIR ${STEAMCMD_SERVER_HOME}

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ ${STEAMCMD_INSTALL_DIR} ]

# Set SteamCMD executable as default entrypoint
ENTRYPOINT [ "steamcmd" ]
CMD [ "+help", "+quit" ]
