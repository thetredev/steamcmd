#!/bin/bash

source ./local-vars.sh
docker-compose build ${@}
