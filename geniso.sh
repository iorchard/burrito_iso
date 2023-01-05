#!/bin/bash

set -eo pipefail

VER=${1:-8.7}
LABEL="Burrito-Rocky-${VER/./-}-x86_64"
ISOFILE="burrito-${VER}.iso"

# chmod for file and directory in iso/.
find iso -type f | xargs chmod 0644
find iso -type d | xargs chmod 0755

# overwrite .discinfo and .treeinfo
cp .discinfo .treeinfo iso/

sed "s/%%LABEL%%/${LABEL}/g" isolinux.cfg.tpl > iso/isolinux/isolinux.cfg
sed "s/%%LABEL%%/${LABEL}/g" grub.cfg.tpl > iso/EFI/BOOT/grub.cfg

# ceph repo setup
sudo rpm --import 'https://download.ceph.com/keys/release.asc'
sudo cp ceph_quincy.repo /etc/yum.repos.d/

mkdir -p iso/BaseOS/Packages
xargs dnf --destdir ./iso/BaseOS/Packages download < burrito_rpm.txt

createrepo -g comps_base.xml iso/BaseOS/
modifyrepo_c --mdtype=modules iso/BaseOS/modules.yaml iso/BaseOS/repodata/

genisoimage -o ${ISOFILE} \
            -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            --no-emul-boot \
            --boot-load-size 4 \
            --boot-info-table \
            --eltorito-alt-boot \
            -e images/efiboot.img \
            --no-emul-boot \
            -J -R -V "${LABEL}" iso

sha512sum ${ISOFILE} > SHA512SUM
