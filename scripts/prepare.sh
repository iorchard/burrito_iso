#!/bin/bash

set -ex

# Reset yum repo to the RL official site
mv -f /etc/yum.repos.d /etc/yum.repos.d.bak
mkdir /etc/yum.repos.d
cp ${WORKSPACE}/files/yum.repos.d/* /etc/yum.repos.d/
sed -i "s/VERSION/${VER}/g" /etc/yum.repos.d/*.repo

dnf -y install epel-release
# Copy files/epel.repo to /etc/yum.repos.d/
rm /etc/yum.repos.d/epel*.repo
cp ${WORKSPACE}/files/epel.repo /etc/yum.repos.d/

COMMON_DEPS=(curl findutils git p7zip p7zip-plugins python3.11 python3.11-pip)
ISO_DEPS=(createrepo_c modulemd-tools genisoimage syslinux)
IMAGE_DEPS=(podman)
FILE_DEPS=(wget gzip xz)
dnf -y install ${COMMON_DEPS[@]} ${ISO_DEPS[@]} \
    ${IMAGE_DEPS[@]} ${FILE_DEPS[@]}

python3.11 -m pip install ansible
curl --retry 3 -Lo ${BASE_ISOFILE} ${ISOURL}
mkdir -p ${WORKSPACE}/iso

7z x ${BASE_ISOFILE} \
    '-xr!BaseOS' '-xr!Minimal' '-xr![BOOT]' \
    -aoa -o${WORKSPACE}/iso
