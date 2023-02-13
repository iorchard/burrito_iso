#!/bin/bash

set -ex

dnf -y install epel-release
COMMON_DEPS=(curl findutils git p7zip p7zip-plugins python39 python39-pip)
ISO_DEPS=(createrepo_c modulemd-tools genisoimage)
IMAGE_DEPS=(podman)
FILE_DEPS=(wget gzip)
#ISO_DEPS2=(grub2-common grub2-efi grub2-pc-modules grub2-pc grub2-tools-efi 
grub2-tools-extra grub2-tools-minimal grub2-tools grubby)
dnf -y install ${COMMON_DEPS[@]} ${ISO_DEPS[@]} \
    ${IMAGE_DEPS[@]} ${FILE_DEPS[@]}

python3.9 -m pip install ansible
curl -Lo ${BASE_ISOFILE} ${ISOURL}
mkdir -p ${WORKSPACE}/iso

7z x ${BASE_ISOFILE} \
    '-xr!BaseOS' '-xr!Minimal' '-xr![BOOT]' \
    -aoa -o${WORKSPACE}/iso
