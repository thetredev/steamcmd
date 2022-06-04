FROM rockylinux:8.5.20220308

# Prepare image environment
ENV TIME_ZONE="UTC"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_ALL=C

# yum: Clean dependencies on remove
RUN echo "clean_requirements_on_remove=1" >> /etc/yum.conf

# Copy build context into image
COPY . /

# Update packages
RUN yum-docker update

# Install packages
RUN yum-docker quick-install \
        # basic system packages
        tzdata \
        glibc-langpack-en \
        # basic tools
        file \
        zip \
        unzip \
        tmux \
        # required packages for SteamCMD
        glibc.i686 \
        libgcc.i686 \
        libstdc++.i686

# Remove vulnerable packages
RUN yum-docker remove \
        platform-python-pip

# Update CA trust
RUN update-ca-trust

# Prepare SteamCMD server directory
ENV STEAMCMD_SERVER_HOME="/var/lib/steamcmd/server"
RUN mkdir -p ${STEAMCMD_SERVER_HOME}

# Set default GID and UID for SteamCMD user
ENV STEAMCMD_UID=5000
ENV STEAMCMD_GID=5000

# Create SteamCMD user
RUN groupadd -r -g ${STEAMCMD_GID} steamcmd && \
    useradd -ms /bin/bash -r -u ${STEAMCMD_UID} -g ${STEAMCMD_GID} steamcmd

# Switch to SteamCMD user
USER steamcmd
WORKDIR ${STEAMCMD_SERVER_HOME}

# Install SteamCMD
RUN mkdir -p $HOME/.local/share/Steam/steamcmd && \
    cd $HOME/.local/share/Steam/steamcmd && \
    curl -fsSL -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm -rf steamcmd_linux.tar.gz && \
    ln -sf $(pwd)/steamcmd.sh $(pwd)/steamcmd

# Append SteamCMD install directory to PATH
ENV PATH=${PATH}:/home/steamcmd/.local/share/Steam/steamcmd

# Update SteamCMD once
RUN mkdir -p $HOME/.steam && \
    steamcmd +quit > /dev/null 2>&1

# Fix SteamCMD runtime error
# [S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.
RUN ln -sf $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32

# Declare SteamCMD install directory as Docker volume to enable incremental updates
VOLUME [ "/home/steamcmd/.local/share/Steam/steamcmd" ]

# Set SteamCMD executable as default entrypoint
ENTRYPOINT ["steamcmd"]
CMD ["+help", "+quit"]
