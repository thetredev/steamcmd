# gosu builder: temporary, until an updated version of gosu is available.
FROM golang:1.17-alpine3.15 AS gosu-builder

# This is going to be an unsigned version of gosu, obviously.
# However, we need a newer version than 1.14 to get rid of runc CVEs
# present in runc 1.0.1 which is used in golang 1.16 used to build gosu 1.14.
ARG GOSU_GITHUB_URL=https://raw.githubusercontent.com/tianon/gosu

# This commit SHA represents the latest master of the project as of
# 2022-06-06.
ARG GOSU_COMMIT_SHA=b6fb26168851702bd888af4e254f7e59d6e14a86

# Set build arguments
ENV CGO_ENABLED 0
ENV BUILD_FLAGS="-v -ldflags '-d -s -w'"

# Set workdir
WORKDIR /go/src/github.com/tianon/gosu

# Build and test gosu
RUN apk add --no-cache \
        file=5.41-r0 \
        curl=7.80.0-r1 \
    && \
        curl -fsSL -O "${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}"/go.mod && \
        curl -fsSL -O "${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}"/go.sum && \
        go mod download && \
        go mod verify && \
        curl -fsSL -O "${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}"/main.go && \
        curl -fsSL -O "${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}"/setup-user.go && \
        curl -fsSL -O "${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}"/version.go && \
        eval "GOARCH=amd64 go build $BUILD_FLAGS -o /go/bin/gosu-amd64" && \
        file /go/bin/gosu-amd64 && \
        /go/bin/gosu-amd64 --version && \
        /go/bin/gosu-amd64 nobody id


# Release image
FROM almalinux:9.0-minimal-20220527

# Build arguments
ARG TINI_VERSION=v0.19.0

# Prepare image environment
## SteamCMD
ENV STEAMCMD_INSTALL_DIR=/home/steamcmd/package
ENV STEAMCMD_SERVER_HOME=/var/lib/steamcmd/server
ENV STEAMCMD_UID=5000
ENV STEAMCMD_GID=5000
## System
ENV TIME_ZONE=UTC
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_ALL=C
ENV PATH=${PATH}:${STEAMCMD_INSTALL_DIR}

# Copy build context into image
COPY . /

# Copy gosu binary from gosu-builder
COPY --from=gosu-builder /go/bin/gosu-amd64 /usr/local/bin/gosu

# Configure system
WORKDIR /tmp

RUN sed -i '/\[main\]/a install_weak_deps=False' /etc/dnf/dnf.conf && \
    yum-docker quick-install \
        # basic system packages
        glibc-langpack-en \
        util-linux-user \
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
        ldconfig && \
        rm -rf /tmp/* \
    && \
        # Disable root login
        chsh -s /usr/sbin/nologin root \
    && \
        # Install and configure tini
        curl -fsSL -o /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64" && \
        chmod +x /usr/local/bin/tini \
    && \
        # Configure gosu binary
        chmod +x /usr/local/bin/gosu && \
        gosu nobody true \
    && \
        # Prepare SteamCMD server directory
        mkdir -p ${STEAMCMD_SERVER_HOME} \
    && \
        # Create SteamCMD user
        groupadd -r -g "${STEAMCMD_GID}" steamcmd && \
        useradd -ms /bin/bash -r -l -u "${STEAMCMD_UID}" -g "${STEAMCMD_GID}" steamcmd

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

# Set default workdir to SteamCMD server dir
WORKDIR ${STEAMCMD_SERVER_HOME}

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ ${STEAMCMD_INSTALL_DIR} ]

# Set SteamCMD executable as default entrypoint
ENTRYPOINT [ "steamcmd" ]
CMD [ "+help", "+quit" ]
