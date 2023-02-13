#!/bin/bash
VER=${1:-8.7}
SRC_VER=${2:-1.0.0}

read -s -p 'root password: ' ROOTPW
echo
read -s -p 'clex user password: ' USERPW
echo
ROOTPW_ENC=$(python3 -c 'import crypt;print(crypt.crypt("${ROOTPW}"))')
USERPW_ENC=$(python3 -c 'import crypt;print(crypt.crypt("${USERPW}"))')
unset ROOTPW USERPW
export ROOTPW_ENC USERPW_ENC

mkdir -p output
podman build -t docker.io/jijisa/burrito-isobuilder .
podman run --privileged -v $(pwd)/output:/output --rm \
  --env="ROOTPW_ENC=${ROOTPW_ENC}" \
  --env="USERPW_ENC=${USERPW_ENC}" \
  docker.io/jijisa/burrito-isobuilder ${VER} ${SRC_VER}
