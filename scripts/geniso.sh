#!/bin/bash

set -exo pipefail

VER=${1:-8.9}
SRC_VER=${2:-1.3.1}
REL_NAME="${SRC_VER//\//_}"
LABEL="Burrito-Rocky-${VER/./-}-x86_64"
ISOFILE="burrito-${REL_NAME}_${VER}.iso"
#ISOURL="https://download.rockylinux.org/pub/rocky/${VER}/isos/x86_64/Rocky-${VER}-x86_64-minimal.iso"
ISOURL="http://192.168.151.110:8000/burrito/Rocky-${VER}-x86_64-minimal.iso"
BASE_ISOFILE=$(basename ${ISOURL})
REG_VER="2.8.2"
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
    --requirement ${WORKSPACE}/files/requirements.txt

# download ansible collections
mkdir -p ${WORKSPACE}/iso/ansible_collections
ansible-galaxy collection download \
  -p ${WORKSPACE}/iso/ansible_collections \
  -r ${WORKSPACE}/scripts/dist/burrito/ceph-ansible/requirements.yml
mv ${WORKSPACE}/iso/ansible_collections/requirements.yml \
  ${WORKSPACE}/iso/ansible_collections/ceph-ansible_req.yml
if [ "${INCLUDE_PFX}" = 1 ]; then
  ansible-galaxy collection download \
    -p ${WORKSPACE}/iso/ansible_collections \
    -r ${WORKSPACE}/scripts/dist/burrito/pfx_requirements.yml
  mv ${WORKSPACE}/iso/ansible_collections/requirements.yml \
    ${WORKSPACE}/iso/ansible_collections/pfx_req.yml
fi
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
sed "s#%%ROOTPW_ENC%%#${ROOTPW_ENC}#g;s#%%UNAME%%#${UNAME}#g;s#%%USERPW_ENC%%#${USERPW_ENC}#g;s#%%LABEL%%#${LABEL}#g" \
  ${WORKSPACE}/files/ks.cfg.tpl > ${WORKSPACE}/iso/ks.cfg
# create .env file in iso.
echo -e "INCLUDE_NETAPP=${INCLUDE_NETAPP}\nINCLUDE_PFX=${INCLUDE_PFX}" > \
  ${WORKSPACE}/iso/.env

# ceph repo setup
rpm --import 'https://download.ceph.com/keys/release.asc'
cp ${WORKSPACE}/files/ceph_quincy.repo /etc/yum.repos.d/

# copy comps_base.xml, modules.yaml into iso
mkdir -p ${WORKSPACE}/iso/BaseOS/Packages
cp ${WORKSPACE}/files/comps_base.xml ${WORKSPACE}/iso/BaseOS/
cp ${WORKSPACE}/files/modules.yaml ${WORKSPACE}/iso/BaseOS/

# download rpm packages
PFX_RPM=""
if [ "${INCLUDE_PFX}" = 1 ]; then
  PFX_RPM="${WORKSPACE}/files/pfx_rpm.txt"
  # get powerflex package tarball from PFX_PKG_URL
  pushd ${WORKSPACE}/iso
    curl -LO ${PFX_PKG_URL}
  popd
fi
cat ${WORKSPACE}/files/burrito_rpm.txt $PFX_RPM | \
  xargs dnf --destdir ${WORKSPACE}/iso/BaseOS/Packages download
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
isohybrid --uefi ${OUTPUT_DIR}/${ISOFILE}

pushd ${OUTPUT_DIR}
    sha512sum ${ISOFILE} > SHA512SUM
popd
