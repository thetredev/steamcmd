#!/bin/bash

source ./local-vars.sh

git_root=$(git rev-parse --show-toplevel)
docker_image="${REGISTRY_IMAGE}:${1:-srcds}"

docker run --rm \
    -v ${git_root}/.trivyignore:/.trivyignore:ro \
    -v ~/.trivy-cache:/root/.cache \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    aquasec/trivy:0.29.2-amd64 image --severity ${2:-CRITICAL,HIGH,MEDIUM,LOW} ${docker_image}

docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    goodwithtech/dockle:v0.4.5-amd64 ${docker_image}
