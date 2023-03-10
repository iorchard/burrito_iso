ARG         FROM=docker.io/library/rockylinux:8.7
FROM        ${FROM}

ENV         WORKSPACE="/opt/burrito_build"
ENV         OUTPUT_DIR="/output"
WORKDIR     ${WORKSPACE}

COPY        files ${WORKSPACE}/files
COPY        scripts ${WORKSPACE}/scripts

VOLUME      ["${OUTPUT_DIR}"]

ENTRYPOINT  ["/opt/burrito_build/scripts/geniso.sh"]
