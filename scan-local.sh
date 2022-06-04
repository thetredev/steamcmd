#!/bin/bash

source ./local-vars.sh
docker run --rm \
    -v ~/.trivy-cache:/root/.cache \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    aquasec/trivy:0.28.1-amd64 image --severity ${2:-CRITICAL,HIGH,MEDIUM,LOW} "${REGISTRY_IMAGE}:${1:-srcds}"
