#!/bin/bash

src_image="${1}"
dst_image_ghcr="${2}"
dst_image_docker_hub="${3}"

do_retag() {
    local dst_image="${1}"

    docker tag ${src_image} ${dst_image}
    docker push ${dst_image}
}

do_retag ${dst_image_ghcr}
do_retag ${dst_image_docker_hub}
