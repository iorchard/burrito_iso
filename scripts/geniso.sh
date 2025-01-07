#!/bin/bash

set -exo pipefail

VER=${1:-8.10}
SRC_VER=${2:-2.0.9}
REL_NAME="${SRC_VER//\//_}"
LABEL="Burrito-Rocky-${VER/./-}-x86_64"
ISOFILE="burrito-${REL_NAME}_${VER}.iso"
#ISOURL="https://download.rockylinux.org/pub/rocky/${VER}/isos/x86_64/Rocky-${VER}-x86_64-minimal.iso"
ISOURL="http://192.168.151.110:8000/burrito/Rocky-${VER}-x86_64-minimal.iso"
BASE_ISOFILE=$(basename ${ISOURL})
REG_VER="2.8.2"
REG_URL="https://github.com/distribution/distribution/releases/download/v${REG_VER}/registry_${REG_VER}_linux_amd64.tar.gz"
COMPS_URL_BASE="https://download.rockylinux.org/pub/rocky/${VER}/BaseOS/x86_64/os"
MODULES_URL_BASE="https://download.rockylinux.org/pub/rocky/${VER}/AppStream/x86_64/os"
export ISOURL BASE_ISOFILE REG_URL SRC_VER REL_NAME VER

# run prepare script - install packages, download and extract base iso file.
$(dirname $0)/prepare.sh

# run get_files.sh script - download binary tarball files
$(dirname $0)/get_files.sh

# run archive_images.sh script - download container images
$(dirname $0)/archive_images.sh

# download python packages
mkdir -p ${WORKSPACE}/iso/pypi
python3.11 -m pip download --dest ${WORKSPACE}/iso/pypi \
    --requirement ${WORKSPACE}/files/requirements.txt

# download ansible collections
mkdir -p ${WORKSPACE}/iso/ansible_collections
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

# overwrite .treeinfo
cp ${WORKSPACE}/files/.treeinfo ${WORKSPACE}/iso/

# overwrite isolinux.cfg and grub.cfg with custom LABEL
sed "s/%%LABEL%%/${LABEL}/g" ${WORKSPACE}/files/isolinux.cfg.tpl > \
    ${WORKSPACE}/iso/isolinux/isolinux.cfg
sed "s/%%LABEL%%/${LABEL}/g" ${WORKSPACE}/files/grub.cfg.tpl > \
    ${WORKSPACE}/iso/EFI/BOOT/grub.cfg
# create ks.cfg with custom root and clex password
sed "s#%%ROOTPW_ENC%%#${ROOTPW_ENC}#g;s#%%UNAME%%#${UNAME}#g;s#%%USERPW_ENC%%#${USERPW_ENC}#g;s#%%LABEL%%#${LABEL}#g" \
  ${WORKSPACE}/files/ks.cfg.tpl > ${WORKSPACE}/iso/ks.cfg
# create .env file in iso.
cat <<EOF > ${WORKSPACE}/iso/.env
INCLUDE_NETAPP=${INCLUDE_NETAPP}
INCLUDE_PFX=${INCLUDE_PFX}
INCLUDE_HITACHI=${INCLUDE_HITACHI}
INCLUDE_PRIMERA=${INCLUDE_PRIMERA}
INCLUDE_PURESTORAGE=${INCLUDE_PURESTORAGE}
INCLUDE_POWERSTORE=${INCLUDE_POWERSTORE}
EOF

# ceph repo setup
rpm --import 'https://download.ceph.com/keys/release.asc'
cp ${WORKSPACE}/files/ceph_reef.repo /etc/yum.repos.d/

# download and copy comps_base.xml, modules.yaml into iso directory
mkdir -p ${WORKSPACE}/iso/BaseOS/Packages
COMPS_URL_APPEND=$(curl -sL $COMPS_URL_BASE/repodata/repomd.xml | grep comps.*xml.xz | cut -d'"' -f2)
MODULES_URL_APPEND=$(curl -sL $MODULES_URL_BASE/repodata/repomd.xml | grep modules.yaml.xz |cut -d'"' -f2)
curl -s ${COMPS_URL_BASE}/${COMPS_URL_APPEND} | unxz > ${WORKSPACE}/iso/BaseOS/comps_base.xml
curl -s ${MODULES_URL_BASE}/${MODULES_URL_APPEND} | unxz > ${WORKSPACE}/iso/BaseOS/modules.yaml

# download rpm packages
PFX_RPM=""
if [ "${INCLUDE_PFX}" = 1 ]; then
  PFX_RPM="${WORKSPACE}/files/pfx_rpm.txt"
  # get powerflex package tarball from PFX_PKG_URL
  pushd ${WORKSPACE}/iso
    curl -LO ${PFX_PKG_URL}
  popd
fi
[[ "${INCLUDE_PRIMERA}" = 1 ]] && PRIMERA_RPM="${WORKSPACE}/files/primera_rpm.txt" || PRIMERA_RPM=""
[[ "${INCLUDE_PURESTORAGE}" = 1 ]] && PURESTORAGE_RPM="${WORKSPACE}/files/purestorage_rpm.txt" || PURESTORAGE_RPM=""
cat ${WORKSPACE}/files/burrito_rpm.txt \
	$PFX_RPM $PRIMERA_RPM $PURESTORAGE_RPM | \
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
