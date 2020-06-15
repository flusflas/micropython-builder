#!/bin/bash

if [ -z "$1" ]; then
    echo -e "Usage:\n  $0 docker_image [output_filename]"
    exit
fi

SRC_FIRMWARE=/home/esp32/micropython/ports/esp32/build-GENERIC/firmware.bin
DST_FIRMWARE=${2:-firmware.bin}

docker create -ti --name dummy $1 bash 1>/dev/null
docker cp dummy:$SRC_FIRMWARE $DST_FIRMWARE
docker rm -f dummy 1>/dev/null
