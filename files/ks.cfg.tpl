## version=Rocky8
## Rocky Linux 8 Kickstart 
# install mode: text, graphical
text
# network install
#url --url="http://download.rockylinux.org/pub/rocky/8/BaseOS/x86_64/os/"
# usb install
harddrive --partition=/dev/disk/by-label/%%LABEL%% --dir=/
#lang ko_KR.UTF-8
lang en_US --addsupport=ko_KR
keyboard us
firewall --disabled
selinux --disabled
timezone Asia/Seoul --utc --nontp
bootloader --timeout=5 --location=mbr
skipx
# Partition scheme split into 2 mode - legacy BIOS vs. UEFI
%include /tmp/partition-scheme
%pre --logfile /tmp/ks-pre.log
# Select OS disk
# Should not be removable
# is not less than $MINSIZE GB
# is not more than $MAXSIZE GB
BLOCKDIR="/sys/block"
MINSIZE=45
MAXSIZE=1100
ROOTDRIVE=""
for d in $BLOCKDIR/sd* $BLOCKDIR/nvme*; do
  DEV=$(basename "$d")
  if [ -d $BLOCKDIR/$DEV ]; then
    if [[ "`cat $BLOCKDIR/$DEV/removable`" = "0" ]]; then
      GB=$((`cat $BLOCKDIR/$DEV/size`/2**21))
      echo "Block device $DEV has $GB GB."
      if [ $GB -gt $MINSIZE -a $GB -lt $MAXSIZE -a -z "$ROOTDRIVE" ]; then
        ROOTDRIVE=$DEV
        echo "Selected ROOTDRIVE=$ROOTDRIVE"
        break
      fi
    fi
  fi
done

if [ -z "$ROOTDRIVE" ]; then
  echo "ERROR: ROOTDRIVE is not defined."
else
  echo "ROOTDRIVE is defined: $ROOTDRIVE"
  cat > /tmp/partition-scheme <<END
zerombr
clearpart --drives=$ROOTDRIVE --all --initlabel
ignoredisk --only-use=$ROOTDRIVE
END
fi

if [ -d /sys/firmware/efi ]; then
  cat >> /tmp/partition-scheme <<END
part /boot --fstype xfs --size 1024
part /boot/efi --fstype efi --size 500
part / --fstype xfs --size 1 --grow
END
else
  cat >> /tmp/partition-scheme <<END
part / --fstype xfs --size 1 --grow
END
fi
%end

firstboot --disabled
reboot --eject
rootpw --iscrypted %%ROOTPW_ENC%%
user --name=%%UNAME%% --iscrypted --password %%USERPW_ENC%%

%packages --instLangs=en_US.utf8
openssh-clients
sudo
nfs-utils
net-tools
tar
bzip2
rsync
python3
git
python3-cryptography
sshpass
lsof
wget
jq
patch
%end

%post
# sudo
echo 'Defaults:clex !requiretty' > /etc/sudoers.d/clex
echo '%clex ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/clex
chmod 440 /etc/sudoers.d/clex
# security settings
sed -i 's/^#UseDNS no/UseDNS no/;s/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
echo -e "TMOUT=300\nexport TMOUT" >> /etc/profile
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --strict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --strict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --strict --nochanges --notempty
%end
