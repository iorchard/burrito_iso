#!/bin/bash

set -ex

# Run registry server
mkdir -p /var/lib/registry
curl -sL $REG_URL | tar -xz registry 
rm -f /etc/containers/registries.conf
cp ${WORKSPACE}/files/registries.conf /etc/containers/
${WORKSPACE}/registry serve ${WORKSPACE}/files/config.yml &>/dev/null &
echo $! > /tmp/registry.pid

# Get hitachi csi images if INCLUDE_HITACHI=1.
if [ "${INCLUDE_HITACHI}" = 1 ]; then
  # get hitachi csi image tarball from HITACHI_IMAGE_URL
  mkdir -p ${WORKSPACE}/hitachi
  curl -LO ${HITACHI_IMAGE_URL}
  tar -C ${WORKSPACE}/hitachi -xf $(basename ${HITACHI_IMAGE_URL})
  for tarball in ${WORKSPACE}/hitachi/*; do
    zcat $tarball | podman load
  done
fi

# Push images to registry
pushd ${WORKSPACE}/files
  IMAGES=$(cat images.txt $([ "${INCLUDE_NETAPP}" = 1 ] && echo -n netapp_images.txt || :) $([ "${INCLUDE_PFX}" = 1 ] && echo -n pfx_images.txt || :))
popd

for src in ${IMAGES}; do
  repo=${src#*/}
  dst="localhost:5000/${repo}"
  echo "== Pull ${src}"
  podman pull ${src}
  echo "== Tag ${src} to ${dst}"
  podman tag ${src} ${dst}
  echo "== Push ${dst}"
  podman push ${dst}
  podman rmi ${dst} ${src}
done
if [ "${INCLUDE_HITACHI}" = 1 ]; then
  for src in $(cat ${WORKSPACE}/files/hitachi_images.txt); do
    repo=${src#*/}
    dst="localhost:5000/${repo}"
    echo "== Tag ${src} to ${dst}"
    podman tag ${src} ${dst}
    echo "== Push ${dst}"
    podman push --remove-signatures ${dst}
    podman rmi ${dst} ${src}
  done
fi

mkdir -p ${WORKSPACE}/iso/registry
mv /var/lib/registry/docker ${WORKSPACE}/iso/registry
