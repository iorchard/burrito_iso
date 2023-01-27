#!/bin/bash

set -exo pipefail

VER=${1:-8.7}
LABEL="Burrito-Rocky-${VER/./-}-x86_64"
ISOFILE="burrito-${VER}.iso"
ISOURL="https://download.rockylinux.org/pub/rocky/${VER:0:1}/isos/x86_64/Rocky-${VER}-x86_64-minimal.iso"
BASE_ISOFILE=$(basename ${ISOURL})
export ISOURL BASE_ISOFILE

# run prepare script - install packages, download and extract base iso file.
$(dirname $0)/prepare.sh

# overwrite .discinfo and .treeinfo
cp ${WORKSPACE}/files/.{disc,tree}info ${WORKSPACE}/iso/

# overwrite isolinux.cfg and grub.cfg with custom LABEL
sed "s/%%LABEL%%/${LABEL}/g" ${WORKSPACE}/files/isolinux.cfg.tpl > \
    ${WORKSPACE}/iso/isolinux/isolinux.cfg
sed "s/%%LABEL%%/${LABEL}/g" ${WORKSPACE}/files/grub.cfg.tpl > \
    ${WORKSPACE}/iso/EFI/BOOT/grub.cfg

# download python packages
mkdir -p ${WORKSPACE}/iso/pypi
python3.9 -m pip download --dest ${WORKSPACE}/iso/pypi \
    --requirement ${WORKSPACE}/files/req.txt

# download ansible collections
mkdir -p ${WORKSPACE}/iso/ansible_collections
ansible-galaxy collection download \
    -p ${WORKSPACE}/iso/ansible_collections \
    -r ${WORKSPACE}/files/ceph-ansible_collections.yml

# ceph repo setup
rpm --import 'https://download.ceph.com/keys/release.asc'
cp ${WORKSPACE}/files/ceph_quincy.repo /etc/yum.repos.d/

# copy ks.cfg, comps_base.xml, modules.yaml into iso
mkdir -p ${WORKSPACE}/iso/BaseOS/Packages
cp ${WORKSPACE}/files/ks.cfg ${WORKSPACE}/iso/
cp ${WORKSPACE}/files/comps_base.xml ${WORKSPACE}/iso/BaseOS/
cp ${WORKSPACE}/files/modules.yaml ${WORKSPACE}/iso/BaseOS/

# download rpm packages
xargs dnf --destdir ${WORKSPACE}/iso/BaseOS/Packages download < \
    ${WORKSPACE}/files/burrito_rpm.txt
createrepo -g comps_base.xml ${WORKSPACE}/iso/BaseOS/

# create iso file
genisoimage -o ${OUTPUT_DIR}/${ISOFILE} \
            -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            --no-emul-boot \
            --boot-load-size 4 \
            --boot-info-table \
            --eltorito-alt-boot \
            -e images/efiboot.img \
            --no-emul-boot \
            -J -R -V "${LABEL}" ${WORKSPACE}/iso

sha512sum ${OUTPUT_DIR}/${ISOFILE} > ${OUTPUT_DIR}/SHA512SUM
