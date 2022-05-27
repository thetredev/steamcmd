FROM ubuntu:jammy-20220428

# Prepare image environment
ENV DEBIAN_FRONTEND="noninteractive"
ENV TIME_ZONE="UTC"

# Copy build context into image
COPY . /

# Fix Canonical's mess...
RUN rm -rf /etc/apt/apt.conf.d/docker-clean

# Get rid of debconf errors
RUN apt-docker quick-install apt-utils

# Set timezone for image preparation
RUN ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && \
    apt-docker quick-install tzdata

# Prepare locales: get rid of perl locale errors
RUN apt-docker quick-install locales

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_ALL=C

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    dpkg-reconfigure locales

# Install basic tools
RUN apt-docker quick-install \
        ca-certificates \
        wget \
        curl \
        file \
        zip \
        unzip \
        tmux

# Update CA certificates
RUN update-ca-certificates

# Prepare SteamCMD server directory
ENV STEAMCMD_SERVER_HOME="/var/lib/steamcmd/server"
RUN mkdir -p ${STEAMCMD_SERVER_HOME}

# Install SteamCMD
RUN echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    dpkg --add-architecture i386 && \
    apt-docker quick-install \
        steamcmd \
    && \
        update-alternatives --install /usr/bin/steamcmd steamcmd /usr/games/steamcmd 1

# Set default GID and UID for SteamCMD user
ENV STEAMCMD_UID=5000
ENV STEAMCMD_GID=5000

# Create SteamCMD user
RUN groupadd -r -g ${STEAMCMD_GID} steamcmd && \
    useradd -ms /bin/bash -r -u ${STEAMCMD_UID} -g ${STEAMCMD_GID} steamcmd && \
    su - steamcmd -c 'mkdir -p $HOME/.steam'

# Switch to SteamCMD user
USER steamcmd
WORKDIR ${STEAMCMD_SERVER_HOME}

# Update SteamCMD once
RUN steamcmd +quit > /dev/null 2>&1

# Fix SteamCMD runtime error
# [S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.
RUN ln -sf $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ "/home/steamcmd/.local/share/Steam/steamcmd" ]

# Set SteamCMD executable as default entrypoint
ENTRYPOINT ["steamcmd"]
CMD ["+help", "+quit"]
