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
RUN apk add --no-cache file && \
    wget ${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}/go.mod && \
    wget ${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}/go.sum && \
    go mod download && \
    go mod verify && \
    wget ${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}/main.go && \
    wget ${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}/setup-user.go && \
    wget ${GOSU_GITHUB_URL}/${GOSU_COMMIT_SHA}/version.go && \
    eval "GOARCH=amd64 go build $BUILD_FLAGS -o /go/bin/gosu-amd64" && \
    file /go/bin/gosu-amd64 && \
    /go/bin/gosu-amd64 --version && \
    /go/bin/gosu-amd64 nobody id && \
    /go/bin/gosu-amd64 nobody ls -l /proc/self/fd


# Release image
FROM almalinux:8.6-minimal-20220512

# Build arguments
ARG TINI_VERSION=v0.19.0

# Prepare image environment
ENV TIME_ZONE="UTC"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_ALL=C

# Copy build context into image
COPY . /

# Install packages
RUN yum-docker quick-install \
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
        glibc.i686 \
        libgcc.i686 \
        libstdc++.i686

# Update CA trust
RUN update-ca-trust

# Disable root login
RUN chsh -s /usr/sbin/nologin root

# Install and configure tini
RUN curl -fsSL -o /usr/local/bin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 && \
    chmod +x /usr/local/bin/tini

# Install and configure gosu
COPY --from=gosu-builder /go/bin/gosu-amd64 /usr/local/bin/gosu
RUN chmod +x /usr/local/bin/gosu && \
    gosu nobody true

# Prepare SteamCMD server directory
ENV STEAMCMD_SERVER_HOME="/var/lib/steamcmd/server"
RUN mkdir -p ${STEAMCMD_SERVER_HOME}

# Set default GID and UID for SteamCMD user
ENV STEAMCMD_UID=5000
ENV STEAMCMD_GID=5000

# Create SteamCMD user
RUN groupadd -r -g ${STEAMCMD_GID} steamcmd && \
    useradd -ms /bin/bash -r -l -u ${STEAMCMD_UID} -g ${STEAMCMD_GID} steamcmd

# Switch to SteamCMD user
USER steamcmd
WORKDIR ${STEAMCMD_SERVER_HOME}

# Install SteamCMD
ENV STEAMCMD_INSTALL_DIR="/home/steamcmd/package"

RUN mkdir -p ${STEAMCMD_INSTALL_DIR} && \
    cd ${STEAMCMD_INSTALL_DIR} && \
    curl -fsSL -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm -rf steamcmd_linux.tar.gz && \
    ln -sf $(pwd)/steamcmd.sh $(pwd)/steamcmd

# Append SteamCMD install directory to PATH
ENV PATH=${PATH}:${STEAMCMD_INSTALL_DIR}

# Update SteamCMD once
RUN mkdir -p ${HOME}/.steam && \
    steamcmd +quit > /dev/null 2>&1

# Fix SteamCMD runtime error
# [S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.
RUN ln -sf ${STEAMCMD_INSTALL_DIR}/linux32 ${HOME}/.steam/sdk32

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ ${STEAMCMD_INSTALL_DIR} ]

# Set SteamCMD executable as default entrypoint
ENTRYPOINT [ "steamcmd" ]
CMD [ "+help", "+quit" ]
