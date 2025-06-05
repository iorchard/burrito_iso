set default="0"

function load_video {
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod all_video
}

load_video
set gfxpayload=keep
insmod gzio
insmod part_gpt
insmod ext2

set timeout=10
### END /etc/grub.d/00_header ###

search --no-floppy --set=root -l '%%LABEL%%'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install Burrito Rocky Linux 9.5' --class fedora --class gnu-linux --class gnu --class os {
	linuxefi /images/pxeboot/vmlinuz inst.ks=hd:LABEL=%%LABEL%% inst.stage2=hd:LABEL=%%LABEL%% quiet
	initrdefi /images/pxeboot/initrd.img
}
