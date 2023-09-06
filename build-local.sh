#!/bin/bash

source ./local-vars.sh
docker buildx bake -f docker-compose.yml ${@}
