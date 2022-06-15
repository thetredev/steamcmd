[![Build Status](https://img.shields.io/github/workflow/status/thetredev/steamcmd/Docker%20build%20and%20publish%20latest.svg?logo=github)](https://github.com/thetredev/steamcmd/actions)
[![CodeFactor](https://www.codefactor.io/repository/github/thetredev/steamcmd/badge)](https://www.codefactor.io/repository/github/thetredev/steamcmd)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

# Sane SteamCMD Docker images
This project aims to provide pre-packaged `SteamCMD` docker images which are up-to-date and especially easy to use.

## Differences to official images
While [the official images](https://github.com/steamcmd/docker) are fine, my take differs in a couple ways:

### Base image
- Based on the official `Alma Linux 8.6` image with all necessary dependencies and basic tools preinstalled
- The SteamCMD runtime error `[S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.` is fixed
- It does not operate under the `root` user - a `steamcmd` user with default UID and GID of 5000 each is used instead
- The server path is changed to `/var/lib/steamcmd/server`

### HLDS image
- Based on the `base` image
- Provides a generic base for HLDS-based game servers
- Provides the script `/opt/server.sh` to manage game servers using a single `tmux` session
- Provides a `docker-entrypoint.sh` which itself is executed as `root` with always-correct timezone and ownership of server files

The `/opt/server.sh` checks for the user executing it. If it's `root`, it executes itself as the `steamcmd` user via `exec gosu` to prevent ownership mismatch.

### HLDS-based game server images
- Based on the `hlds` image
- Adds game server specific environment variables for configuration

Currently supported game server images:

| Game | Docker Image |
| ---- | ---- |
| Counter-Strike | `ghcr.io/thetredev/steamcmd:cs-latest` |

See the `compose/hlds` directory for more details.

### SRCDS image
- Based on the `base` image
- Provides a generic base for SRCDS-based game servers
- `libstdc++`, `libtinfo` and other runtime errors due to missing dependencies are fixed
- Provides the script `/opt/server.sh` to manage game servers using a single `tmux` session
- Provides a `docker-entrypoint.sh` which itself is executed as `root` with always-correct timezone and ownership of server files
- Tries to enable `128 tick` configurations by default (CS:GO). CS:S will default to 67 [because Valve said it's better this way (in 2010)](https://store.steampowered.com/oldnews/3976).

The `/opt/server.sh` checks for the user executing it. If it's `root`, it executes itself as the `steamcmd` user via `exec gosu` to prevent ownership mismatch.

### SRCDS-based game server images
- Based on the `srcds` image
- Adds game server specific environment variables for configuration

Currently supported game server images:

| Game | Docker Image |
| ---- | ---- |
| Black Mesa: Deathmatch | `ghcr.io/thetredev/steamcmd:bms-latest` |
| Counter-Strike: Source | `ghcr.io/thetredev/steamcmd:css-latest` |
| Counter-Strike: Global Offensive | `ghcr.io/thetredev/steamcmd:csgo-latest` |
| Day of Defeat: Source | `ghcr.io/thetredev/steamcmd:dods-latest` |
| Garry's Mod | `ghcr.io/thetredev/steamcmd:gm-latest` |
| Half Life 2: Source | `ghcr.io/thetredev/steamcmd:hl2mp-latest` |
| Left 4 Dead | `ghcr.io/thetredev/steamcmd:l4d-latest` |
| Left 4 Dead 2 | `ghcr.io/thetredev/steamcmd:l4d2-latest` |

See the `compose/srcds` directory for more details. If you want to run multiple game servers using one single compose file, see the file `compose/srcds/multiple.yml`.

## Image repository
The image repository is: `ghcr.io/thetredev/steamcmd`<br/>
See https://github.com/thetredev/steamcmd/pkgs/container/steamcmd/versions for details.

The GitHub Actions workflows are setup in the following way:
- Pushes to the `main` branch lead to the image tags `ghcr.io/thetredev/steamcmd:<image>-latest`, where `<image>` is one of the following: `base`, `srcds`, and any game servers a `Dockerfile` is provided for (see *the supported game server images* above)
- Pushes of tags lead to retagging the `ghcr.io/thetredev/steamcmd:<image>-latest` images to `ghcr.io/thetredev/steamcmd:<image>-<tag>`

All image builds are scanned for CVEs and only pushed as `latest` or the given tag if no CVEs are found. The scans can be viewed publicly [from within the Actions tab](https://github.com/thetredev/steamcmd/actions) at job **build**.

## Known bugs
See the [project issues](https://github.com/thetredev/steamcmd/issues).

## How to contribute?
Just throw me a pull request - feel free to hack along!
