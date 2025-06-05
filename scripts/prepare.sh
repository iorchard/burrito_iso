#!/bin/bash

set -ex

# Reset yum repo for the RL version
#mv /etc/yum.repos.d /etc/yum.repos.d.bak
#mkdir /etc/yum.repos.d
#cp ${WORKSPACE}/files/yum.repos.d/* /etc/yum.repos.d/
#sed -i "s/VERSION/${VER}/g" /etc/yum.repos.d/*.repo

dnf -y install epel-release
COMMON_DEPS=(findutils git p7zip p7zip-plugins python3.12 python3.12-pip)
ISO_DEPS=(createrepo_c modulemd-tools genisoimage syslinux)
IMAGE_DEPS=(podman)
FILE_DEPS=(wget gzip xz)
dnf -y install ${COMMON_DEPS[@]} ${ISO_DEPS[@]} \
    ${IMAGE_DEPS[@]} ${FILE_DEPS[@]}

python3.12 -m pip install ansible
curl --retry 3 -Lo ${BASE_ISOFILE} ${ISOURL}
mkdir -p ${WORKSPACE}/iso

7z x ${BASE_ISOFILE} \
    '-xr!BaseOS' '-xr!Minimal' '-xr![BOOT]' \
    -aoa -o${WORKSPACE}/iso
