#!/bin/bash

CURRENT_DIR=$( dirname "$(readlink -f "$0")" )
OFFLINE_FILES_DIR_NAME="files"
OFFLINE_FILES_DIR="${WORKSPACE}/iso/${OFFLINE_FILES_DIR_NAME}"
FILES_LIST=${FILES_LIST:-"${WORKSPACE}/files/bin.txt"}
DIST_DIR="${CURRENT_DIR}/dist"
REL_NAME="${SRC_VER//\//_}"

mkdir -p ${DIST_DIR}
curl -sLo ${CURRENT_DIR}/git-archive-all.sh \
  https://raw.githubusercontent.com/fabacab/git-archive-all.sh/master/git-archive-all.sh
chmod +x ${CURRENT_DIR}/git-archive-all.sh

git clone --recursive -b ${SRC_VER} https://github.com/iorchard/burrito.git \
  ${DIST_DIR}/burrito
pushd ${DIST_DIR}/burrito
  echo ${SRC_VER} \($(git rev-parse HEAD)\) > VERSION
  ${CURRENT_DIR}/git-archive-all.sh --prefix burrito-${REL_NAME}/ \
    ${WORKSPACE}/iso/burrito-${REL_NAME}.tar
  # add VERSION to tarball
  tar --xform="s#^#burrito-${REL_NAME}/#" -rf \
	  ${WORKSPACE}/iso/burrito-${REL_NAME}.tar VERSION
  # compress
  gzip -9f ${WORKSPACE}/iso/burrito-${REL_NAME}.tar
popd

pushd ${WORKSPACE}/iso
  #curl -LO https://github.com/iorchard/burrito/releases/download/${SRC_VER}/burrito-${SRC_VER}.tar.gz
popd

# extract scripts/{images,bin}.txt to files/
pushd ${WORKSPACE}/files
  tar --strip-components=2 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
    burrito-${REL_NAME}/scripts/images.txt
  tar --strip-components=2 -xvzf ${WORKSPACE}/iso/burrito-${REL_NAME}.tar.gz \
    burrito-${REL_NAME}/scripts/bin.txt
popd
# download files
if [ ! -f "${FILES_LIST}" ]; then
  echo "${FILES_LIST} should exist."
  exit 1
fi

rm -rf "${OFFLINE_FILES_DIR}"
mkdir -p "${OFFLINE_FILES_DIR}"

wget -x -P "${OFFLINE_FILES_DIR}" -i "${FILES_LIST}"

