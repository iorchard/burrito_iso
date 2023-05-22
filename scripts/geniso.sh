#!/bin/bash

set -exo pipefail

VER=${1:-8.7}
SRC_VER=${2:-1.0.0}
REL_NAME="${SRC_VER//\//_}"
LABEL="Burrito-Rocky-${VER/./-}-x86_64"
ISOFILE="burrito-${REL_NAME}_${VER}.iso"
ISOURL="https://download.rockylinux.org/pub/rocky/${VER}/isos/x86_64/Rocky-${VER}-x86_64-minimal.iso"
BASE_ISOFILE=$(basename ${ISOURL})
REG_VER="2.8.1"
REG_URL="https://github.com/distribution/distribution/releases/download/v${REG_VER}/registry_${REG_VER}_linux_amd64.tar.gz"
export ISOURL BASE_ISOFILE REG_URL SRC_VER REL_NAME

# run prepare script - install packages, download and extract base iso file.
$(dirname $0)/prepare.sh

# run get_files.sh script - download binary tarball files
$(dirname $0)/get_files.sh

# run archive_images.sh script - download container images
$(dirname $0)/archive_images.sh

# download python packages
mkdir -p ${WORKSPACE}/iso/pypi
python3.9 -m pip download --dest ${WORKSPACE}/iso/pypi \
    --requirement ${WORKSPACE}/files/req.txt

# download ansible collections
mkdir -p ${WORKSPACE}/iso/ansible_collections
ansible-galaxy collection download \
    -p ${WORKSPACE}/iso/ansible_collections \
    -r ${WORKSPACE}/files/ceph-ansible_collections.yml

# chmod for file and directory in iso/.
find ${WORKSPACE}/iso -type f | xargs chmod 0644
find ${WORKSPACE}/iso -type d | xargs chmod 0755

# overwrite .discinfo and .treeinfo
cp ${WORKSPACE}/files/.{disc,tree}info ${WORKSPACE}/iso/

# overwrite isolinux.cfg and grub.cfg with custom LABEL
sed "s/%%LABEL%%/${LABEL}/g" ${WORKSPACE}/files/isolinux.cfg.tpl > \
    ${WORKSPACE}/iso/isolinux/isolinux.cfg
sed "s/%%LABEL%%/${LABEL}/g" ${WORKSPACE}/files/grub.cfg.tpl > \
    ${WORKSPACE}/iso/EFI/BOOT/grub.cfg
# create ks.cfg with custom root and clex password
sed "s#%%ROOTPW_ENC%%#${ROOTPW_ENC}#g;s#%%UNAME%%#${UNAME}#g;s#%%USERPW_ENC%%#${USERPW_ENC}#g;" \
  ${WORKSPACE}/files/ks.cfg.tpl > ${WORKSPACE}/iso/ks.cfg

# ceph repo setup
rpm --import 'https://download.ceph.com/keys/release.asc'
cp ${WORKSPACE}/files/ceph_quincy.repo /etc/yum.repos.d/

# copy comps_base.xml, modules.yaml into iso
mkdir -p ${WORKSPACE}/iso/BaseOS/Packages
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
            -J -R -V "${LABEL}" \
            ${WORKSPACE}/iso

pushd ${OUTPUT_DIR}
    sha512sum ${ISOFILE} > SHA512SUM
popd
