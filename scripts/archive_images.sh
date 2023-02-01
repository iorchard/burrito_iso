#!/bin/bash

set -ex

# Run registry server
mkdir -p /var/lib/registry
curl -sL $REG_URL | tar -xz registry 
rm -f /etc/containers/registries.conf
cp ${WORKSPACE}/files/registries.conf /etc/containers/
${WORKSPACE}/registry serve ${WORKSPACE}/files/config.yml &>/dev/null &
echo $! > /tmp/registry.pid

# Push images to registry
for src in $(cat ${WORKSPACE}/files/burrito_images.txt)
do
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
mkdir -p ${WORKSPACE}/iso/registry
mv /var/lib/registry/docker ${WORKSPACE}/iso/registry
