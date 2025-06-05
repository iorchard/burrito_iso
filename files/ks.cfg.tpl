## version=Rocky9
## Rocky Linux 9 Kickstart 
# install mode: text, graphical
text
# usb install
harddrive --partition=/dev/disk/by-label/%%LABEL%% --dir=/
lang en_US --addsupport=ko_KR
keyboard us
firewall --disabled
selinux --disabled
timezone Asia/Seoul --utc --nontp
bootloader --timeout=5 --location=mbr
skipx
# Partition scheme split into 2 mode - legacy BIOS vs. UEFI
%include /tmp/partition-scheme
%pre --logfile /tmp/ks-pre.log --interpreter=/usr/bin/bash --erroronfail
# Select OS disk
# Should not be removable
# is not less than $MINSIZE GB
# is not more than $MAXSIZE GB
BLOCKDIR="/sys/block"
MINSIZE=45
MAXSIZE=1100000
MSG=
ROOTDRIVE=
CANDIDATES=()
MMCBLK_GRP=()
SD_GRP=()
NVME_GRP=()
TOTAL_SCORE=0
MMCBLK_SCORE=0
SD_SCORE=0
NVME_SCORE=0

for d in $BLOCKDIR/sd* $BLOCKDIR/nvme* $BLOCKDIR/mmcblk*; do
  DEV=$(basename "$d")
  if [ -d $BLOCKDIR/$DEV ]; then
    if [[ "`cat $BLOCKDIR/$DEV/removable`" = "0" ]]; then
      GB=$((`cat $BLOCKDIR/$DEV/size`/2**21))
      echo "Block device $DEV has $GB GB."
      if [ $GB -gt $MINSIZE -a $GB -lt $MAXSIZE ]; then
        CANDIDATES+=("$DEV")
        case $DEV in
          sd*)
            SD_GRP+=("$DEV")
            SD_SCORE=1
            ;;
          nvme*)
            NVME_GRP+=("$DEV")
            NVME_SCORE=2
            ;;
          mmcblk*)
            MMCBLK_GRP+=("$DEV")
            MMCBLK_SCORE=4
            ;;
        esac
        if [ -z "$MSG" ]; then
          MSG="$DEV ($GB GB)"
        else
          MSG="${MSG}, $DEV ($GB GB)"
        fi
      fi
    fi
  fi
done

TOTAL_SCORE=$(($SD_SCORE+$NVME_SCORE+$MMCBLK_SCORE))
if [[ "$TOTAL_SCORE" = "0" ]]; then
    echo "ERROR: Cannot find the OS device candidates."
    exit 1
else
    if [[ "$(($TOTAL_SCORE & ($TOTAL_SCORE-1)))" = "0" ]]; then
      echo "Only one device group has the OS device candidates."
      case $TOTAL_SCORE in
          1)
              ROOTDRIVE=${SD_GRP[0]}
              ;;
          2)
              ROOTDRIVE=${NVME_GRP[0]}
              ;;
          4)
              ROOTDRIVE=${MMCBLK_GRP[0]}
              ;;
      esac
    else
      echo "Multiple device groups have the OS device candidates."
      exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
      chvt 6
      echo
      while :; do
        echo -e "Root drive candidates:\n$MSG\n"
        read -p "Which device do you want to install the OS on? " SELECTED
        if [[ " ${CANDIDATES[*]} " != *" $SELECTED "* ]]; then
          echo "You entered the wrong device name. Please enter it again."
          echo
        else
          break
        fi
      done
      ROOTDRIVE=$SELECTED
      echo
      echo "You have selected $ROOTDRIVE for the OS installation device."
      sleep 3
      chvt 1
      exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
    fi
fi

if [ -z "$ROOTDRIVE" ]; then
  echo "ERROR: ROOTDRIVE is not defined."
  exit 1
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
gnutls-utils
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
