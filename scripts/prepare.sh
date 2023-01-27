#!/bin/bash

set -ex

dnf -y install epel-release
COMMON_DEPS=(curl findutils git p7zip p7zip-plugins python39 python39-pip)
ISO_DEPS=(createrepo_c modulemd-tools genisoimage)
dnf -y install ${COMMON_DEPS[@]} ${ISO_DEPS[@]}

python3.9 -m pip install ansible
curl -Lo ${BASE_ISOFILE} ${ISOURL}
mkdir -p ${WORKSPACE}/iso
7z x ${BASE_ISOFILE} \
    '-xr!BaseOS' '-xr!Minimal' '-xr![BOOT]' \
    -aoa -o${WORKSPACE}/iso
