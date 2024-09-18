[![Build Status](https://img.shields.io/github/actions/workflow/status/thetredev/steamcmd/docker-latest.yml)](https://github.com/thetredev/steamcmd/actions)
[![CodeFactor](https://www.codefactor.io/repository/github/thetredev/steamcmd/badge)](https://www.codefactor.io/repository/github/thetredev/steamcmd)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

# Deprecation notice

Shamelessly copying the following note from https://github.com/dmadisetti/steam-tui/blob/main/README.md:

> [!NOTE]
> Steam no longer has a backend only mode.

So until further notice, this project is deprecated. I won't support requiring multiple gigabytes worth of packages (GUI stuff mostly, totalling to about ~ 4.5 last time I checked) just to run `steamcmd`.

The project will be archived for the time being to stop GitHub from triggering CI workflows.

This notice will be removed as soon as Valve has a backend only mode again, or someone finds a way how we can run `steamcmd` without these pointless dependencies.

# Sane SteamCMD Docker images
This project aims to provide pre-packaged `SteamCMD` docker images which are up-to-date and especially easy to use.

https://github.com/thetredev/steamcmd/assets/6085219/b7b807c0-3459-4522-89ed-343e4e2b3e8a

# Table of Contents
- [Differences to official images](#differences-to-official-images)
  - [tmux session socket](#tmux-session-socket)
  - [console input socket](#console-input-socket)
  - [Base image](#base-image)
  - [SSH server](#ssh-server)
- [HLDS image](#hlds-image)
  - [HLDS-based game servers](#hlds-based-game-servers)
- [SRCDS image](#srcds-image)
  - [SRCDS-based game servers](#srcds-based-game-servers)
- [Source 2 image](#source-2-image)
  - [Source 2 based game servers](#source-2-based-game-servers)
- [Running multiple game servers](#running-multiple-game-servers)
- [Kubernetes](#kubernetes)
- [Image repositories](#image-repositories)
- [Known bugs](#known-bugs)
- [How to contribute?](#how-to-contribute)

## Differences to official images
While [the official images](https://github.com/steamcmd/docker) are fine, my take differs in a couple ways:

### tmux session socket
These containers create a `tmux` session socket at `/tmp/steamcmd/session.sock`. If it is exposed to your local file system, you can use it to for example attach to the SteamCMD game server session:
```
tmux -S </path/to/bind-mounted/socket> attach
```

To expose the socket, just bind-mount the path (using `cs2` as an example):
```yaml
services:
  cs2:
    ...
    volumes:
      - /tmp/steamcmd:/tmp/steamcmd
    ...
```

Which would translate to:
```
tmux -S /tmp/steamcmd/tmux.sock attach
```

Beware that `attach` is a `tmux` command! So you could also use `a` instead:
```
tmux -S /tmp/steamcmd/tmux.sock a
```

Instead of the `attach` command, you can use `send-keys` to execute a command directly within the game server's shell, say `bot kick`:
```
tmux -S /tmp/steamcmd/tmux.sock send-keys "bot_kick" "Enter"
```

Unfortunately there's no way currently to provide a shorthand for `send-keys` yet.

### console input socket

To get around the `tmux` session syntax noise, I decided to create a Unix domain socket as well.

To type something in the SteamCMD game server console directly, you can use `netcat-openbsd` / `openbsd-netcat` like this:
```
echo "my server command" | nc -UN /tmp/steamcmd/console.sock
```

To expose the socket, just bind-mount the path (using `cs2` as an example):
```yaml
services:
  cs2:
    ...
    volumes:
      - /tmp/steamcmd:/tmp/steamcmd
    ...
```

This socket makes it possible to forward console inputs from a web API or secure TCP socket for example.

### Base image
- Based on the official [`SteamRT v3 "(Sniper)"` image](https://gitlab.steamos.cloud/steamrt/sniper/platform) with all necessary dependencies and basic tools preinstalled
- For legacy game servers (Source 1, non-CS 2 and HLDS) SteamRT v2 "Soldier" is used instead
- The SteamCMD runtime error `[S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.` is fixed
- It does not operate under the `root` user - a `steamcmd` user with default UID and GID of 5000 each is used instead
- The server path is changed to `/var/lib/steamcmd/server`
- `openssh-server` is installed to provide an easy and secure way of managing server files externally, even when using Kubernetes

### SSH server
See the SSHD configuration at [`image/base/etc/ssh/sshd_config.d/steamcmd.conf`](image/base/etc/ssh/sshd_config.d/steamcmd.conf) for the options applied to the server. Only public key authentication is enabled!

To enable the SSH server, set the environment variables `STEAMCMD_SSH_SERVER_ENABLE` to `1` and `STEAMCMD_SSH_AUTHORIZED_KEYS` to the Base64 encoded public SSH keys separated by newlines (see [`compose/hlds/cs-ssh.yml`](compose/hlds/cs-ssh.yml) or [`compose/srcds/css-ssh.yml`](compose/srcds/css-ssh.yml)). `STEAMCMD_SSH_AUTHORIZED_KEYS` essentially represents the `~/.ssh/authorized_keys` file on the server side in encoded format.

Base64-encode your public SSH keys:
```shell
cat <ssh-key1>.pub <ssh-key2>.pub <ssh-keyN>.pub | base64 -w 0
```

Then use the output as the value for `STEAMCMD_SSH_AUTHORIZED_KEYS`.

## HLDS image
- Based on the [`base`](image/base) image
- Provides a generic base for HLDS-based game servers
- Provides the script [`server.sh (HLDS)`](image/hlds/usr/local/bin/server.sh) to manage game servers using a single `tmux` session
- Provides a [`docker-entrypoint.sh`](image/base/usr/bin/docker-entrypoint.sh) which itself is executed as `root` with always-correct timezone and ownership of server files

The `server.sh` checks for the user executing it. If it's `root`, it executes itself as the `steamcmd` user via `exec gosu` to prevent ownership mismatch.

### HLDS-based game servers
- Composed via [`compose/hlds`](compose/hlds)
- Game server specific environment variables are used for configuration

Currently supported game server images:

| Game | Docker Image |
| ---- | ---- |
| Half-Life | `ghcr.io/thetredev/steamcmd:hlds-latest` |
| Half-Life: Opposing Force | `ghcr.io/thetredev/steamcmd:hlds-latest` |
| Counter-Strike | `ghcr.io/thetredev/steamcmd:hlds-latest` |
| Counter-Strike: Condition Zero | `ghcr.io/thetredev/steamcmd:hlds-latest` |
| Day of Defeat | `ghcr.io/thetredev/steamcmd:hlds-latest` |
| Deathmatch Classic | `ghcr.io/thetredev/steamcmd:hlds-latest` |
| Team Fortress Classic | `ghcr.io/thetredev/steamcmd:hlds-latest` |

**Note**: Ricochet seems like it's not available anymore.

## SRCDS image
- Based on the [`base`](image/base) image
- Provides a generic base for SRCDS-based game servers
- `libstdc++`, `libtinfo` and other runtime errors due to missing dependencies are fixed
- Provides the script [`server.sh (SRCDS)`](image/srcds/usr/local/bin/server.sh) to manage game servers using a single `tmux` session
- Provides a [`docker-entrypoint.sh`](image/base/usr/bin/docker-entrypoint.sh) which itself is executed as `root` with always-correct timezone and ownership of server files
- Tries to enable `128 tick` configurations by default. CS:S will default to 67 [because Valve said it's better this way (in 2010)](https://store.steampowered.com/oldnews/3976).

The `server.sh` checks for the user executing it. If it's `root`, it executes itself as the `steamcmd` user via `exec gosu` to prevent ownership mismatch.

### SRCDS-based game servers
- Composed via [`compose/srcds`](compose/srcds)
- Game server specific environment variables are used for configuration

Currently supported game server images:

| Game | Docker Image |
| ---- | ---- |
| Counter-Strike: Source | `ghcr.io/thetredev/steamcmd:srcds-latest` |
| Day of Defeat: Source | `ghcr.io/thetredev/steamcmd:srcds-latest` |
| Garry's Mod | `ghcr.io/thetredev/steamcmd:srcds-latest` |
| Half Life 2: Deathmatch | `ghcr.io/thetredev/steamcmd:srcds-latest` |
| Left 4 Dead | `ghcr.io/thetredev/steamcmd:srcds-latest` |
| Left 4 Dead 2 | `ghcr.io/thetredev/steamcmd:srcds-latest` |

## Source 2 image
- Based on the [`base`](image/base) image
- Provides a generic base for Source 2 based game servers
- `libstdc++`, `libtinfo` and other runtime errors due to missing dependencies are fixed
- Provides the script [`server.sh (SRCDS)`](image/srcds/usr/local/bin/server.sh) to manage game servers using a single `tmux` session
- Provides a [`docker-entrypoint.sh`](image/base/usr/bin/docker-entrypoint.sh) which itself is executed as `root` with always-correct timezone and ownership of server files
- Tries to enable `128 tick` configurations by default (Black Mesa: Deathmatch).

The `server.sh` checks for the user executing it. If it's `root`, it executes itself as the `steamcmd` user via `exec gosu` to prevent ownership mismatch.

### Source 2 based game servers
- Composed via [`compose/source2`](compose/source2)
- Game server specific environment variables are used for configuration

Currently supported game server images:

| Game | Docker Image |
| ---- | ---- |
| Black Mesa: Deathmatch | `ghcr.io/thetredev/steamcmd:source2-latest` |
| Counter-Strike 2 | `ghcr.io/thetredev/steamcmd:source2-latest` |

Note that Black Mesa: Deathmatch is built on the Counter-Strike: Global Offensive engine, which is a modified/updated version of Source 1. However, since the Source 2 image is based on the SteamRT `sniper` runtime, which was also used for CS:GO before CS 2 came along, the Black Mesa: Deathmatch game server container is now run via the Source 2 image. If you encounter any issues, please head over to the [project issues](https://github.com/thetredev/steamcmd/issues) and create a new issue to let me know.

## Running multiple game servers
If you want to run multiple game servers using one single compose file, see the example file [`compose/srcds/multiple.yml`](compose/srcds/multiple.yml).

## Kubernetes
See https://github.com/thetredev/helm-charts.

## Image repositories
The main image repository is: `ghcr.io/thetredev/steamcmd`<br/>
See https://github.com/thetredev/steamcmd/pkgs/container/steamcmd/versions for details.

The GitHub image repository is synchronized with the Docker Hub repository:<br/>
https://hub.docker.com/r/thetredev/steamcmd

The GitHub Actions workflows are setup in the following way:
- Pushes to the `main` branch lead to the image tags `ghcr.io/thetredev/steamcmd:<image>-latest`, where `<image>` is one of the following: `base`, `hlds` or `srcds` (see *the supported game server images* above)
- Pushes of tags lead to retagging the `ghcr.io/thetredev/steamcmd:<image>-latest` images to `ghcr.io/thetredev/steamcmd:<image>-<tag>`

All image builds used to be scanned for CVEs and only pushed as `latest` or the given tag if no CVEs are found. These scans have been removed and/or disabled since we're relying on official Steam Runtime images now (commit [a64d5003ac8d84eccc6326bc8270eef1105745e0](https://github.com/thetredev/steamcmd/tree/a64d5003ac8d84eccc6326bc8270eef1105745e0)) and we simply trust Valve to make the base images as secure as possible.

## Known bugs
See the [project issues](https://github.com/thetredev/steamcmd/issues).

## How to contribute?
Just throw me a pull request - feel free to hack along!
