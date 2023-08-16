#!/bin/bash

CURRENT_DIR=$( dirname "$(readlink -f "$0")" )
OFFLINE_FILES_DIR_NAME="files"
OFFLINE_FILES_DIR="${WORKSPACE}/iso/${OFFLINE_FILES_DIR_NAME}"
FILES_LIST=${FILES_LIST:-"${WORKSPACE}/files/bin.txt"}
DIST_DIR="${CURRENT_DIR}/dist"
REL_NAME="${SRC_VER//\//_}"

mkdir -p ${DIST_DIR}

git clone --recursive -b ${SRC_VER} https://github.com/iorchard/burrito.git \
  ${DIST_DIR}/burrito
pushd ${DIST_DIR}/burrito
  ./scripts/create_tarball.sh ${SRC_VER}
  mv ./scripts/dist/burrito-${REL_NAME}.tar.gz \
    ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz
popd

# extract scripts/{images,bin}.txt to files/
pushd ${WORKSPACE}/files
  tar --strip-components=2 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
    burrito-${REL_NAME}/scripts/images.txt
  tar --strip-components=2 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
    burrito-${REL_NAME}/scripts/bin.txt
  tar --strip-components=1 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
    burrito-${REL_NAME}/requirements.txt
  if [ "${INCLUDE_NETAPP}" = 1 ]; then
    tar --strip-components=2 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
      burrito-${REL_NAME}/scripts/netapp_images.txt
  fi
  if [ "${INCLUDE_PFX}" = 1 ]; then
    tar --strip-components=2 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
      burrito-${REL_NAME}/scripts/pfx_images.txt
  fi
popd
# download files
if [ ! -f "${FILES_LIST}" ]; then
  echo "${FILES_LIST} should exist."
  exit 1
fi

rm -rf "${OFFLINE_FILES_DIR}"
mkdir -p "${OFFLINE_FILES_DIR}"

wget -x -P "${OFFLINE_FILES_DIR}" -i "${FILES_LIST}"

