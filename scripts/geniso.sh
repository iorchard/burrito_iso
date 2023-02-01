#!/bin/bash

set -exo pipefail

VER=${1:-8.7}
LABEL="Burrito-Rocky-${VER/./-}-x86_64"
ISOFILE="burrito-${VER}.iso"
ISOURL="https://download.rockylinux.org/pub/rocky/${VER:0:1}/isos/x86_64/Rocky-${VER}-x86_64-minimal.iso"
BASE_ISOFILE=$(basename ${ISOURL})
REG_VER="2.8.1"
REG_URL="https://github.com/distribution/distribution/releases/download/v${REG_VER}/registry_${REG_VER}_linux_amd64.tar.gz"
export ISOURL BASE_ISOFILE REG_URL

# run prepare script - install packages, download and extract base iso file.
$(dirname $0)/prepare.sh

# run get_files.sh script - download binary tarball files
$(dirname $0)/get_files.sh

# run archive_images.sh script - download container images
$(dirname $0)/archive_images.sh

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
genisoimage -boot-load-size 4 \
            -boot-info-table \
            -eltorito-boot isolinux/isolinux.bin \
            -eltorito-catalog isolinux/boot.cat \
            -efi-boot images/efiboot.img \
            -no-emul-boot \
            -J -R -V "${LABEL}" \
            -o ${OUTPUT_DIR}/${ISOFILE} \
            ${WORKSPACE}/iso

pushd ${OUTPUT_DIR}
    sha512sum ${ISOFILE} > SHA512SUM
popd
