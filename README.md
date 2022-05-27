# Sane SteamCMD Docker images
This project aims to provide pre-packaged `SteamCMD` docker images which are up-to-date and especially easy to use.

## Differences to official images
While [the official images](https://github.com/steamcmd/docker) are fine, my take differs in a couple ways:

### Base image
- Based on the official `Ubuntu 22.04 (Jammy Jellyfish)` image with all necessary dependencies and basic tools preinstalled
- The SteamCMD runtime error `[S_API FAIL] SteamAPI_Init() failed; unable to locate a running instance of Steam, or a local steamclient.dll.` is fixed
- It does not operate under the `root` user - a `steamcmd` user with default UID and GID of 5000 each is used instead
- The server path is changed to `/var/lib/steamcmd/server`

### SRCDS image
- Based on the `base` image
- Provides a generic base for SRCDS-based game servers
- `libstdc++`, `libtinfo` and other runtime errors due to missing dependencies are fixed
- Provides the script `/opt/server.sh` to manage game servers using a single `tmux` session
- Provides `server.sh` shortcuts: `attach`, `run`, `update`
- Provides a `docker-entrypoint.sh` which itself is executed as `root` with always-correct timezone and ownership of server files
- Tries to enable `128 tick` configurations by default (currently WIP)

The `/opt/server.sh` checks for the user executing it. If it's `root`, it executes itself as the `steamcmd` user via `exec runuser` to prevent ownership mismatch.

### Game server images
- Based on the `srcds` image
- Adds game server specific environment variables for configuration

Currently supported game server images:

| Game | Docker Image |
| ---- | ---- |
| Counter-Strike: Source | `ghcr.io/thetredev/steamcmd:css-latest` |

See the `compose` directory for more details.

## Image repository
The image repository is: `ghcr.io/thetredev/steamcmd`

The GitHub Actions workflows are setup in the following way:
- Pushes to the `main` branch lead to the image tags `ghcr.io/thetredev/steamcmd:<image>-latest`, where `<image>` is one of the following: `base`, `srcds`, and any game servers a `Dockerfile` is provided for (see *the supported game server images* above)
- Pushes of tags lead to retagging the `ghcr.io/thetredev/steamcmd:<image>-latest` images to `ghcr.io/thetredev/steamcmd:<image>-<tag>`

## Known bugs
See the [project issues](https://github.com/thetredev/steamcmd/issues).

## How to contribute?
Just throw me a pull request - feel free to hack along!
