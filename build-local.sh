#!/bin/bash

export REGISTRY_IMAGE="thetredev-steamcmd"
docker-compose build ${@}
