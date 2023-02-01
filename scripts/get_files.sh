#!/bin/bash

CURRENT_DIR=$( dirname "$(readlink -f "$0")" )
OFFLINE_FILES_DIR_NAME="files"
OFFLINE_FILES_DIR="${WORKSPACE}/iso/${OFFLINE_FILES_DIR_NAME}"
FILES_LIST=${FILES_LIST:-"${WORKSPACE}/files/files.list"}

# download files
if [ ! -f "${FILES_LIST}" ]; then
    echo "${FILES_LIST} should exist."
    exit 1
fi

rm -rf "${OFFLINE_FILES_DIR}"
mkdir -p "${OFFLINE_FILES_DIR}"

wget -x -P "${OFFLINE_FILES_DIR}" -i "${FILES_LIST}"
