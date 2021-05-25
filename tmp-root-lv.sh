#!/bin/bash

pvcreate /dev/sdb

vgcreate vg_root /dev/sdb

lvcreate -l +100%FREE -n lv_root vg_root

mkfs.xfs /dev/vg_root/lv_root

mount /dev/vg_root/lv_root /mnt

xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt

for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

chroot /mnt/ <<"EOT"
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
sed -i "s+rd.lvm.lv=VolGroup00/LogVol00+rd.lvm.lv=vg_root/lv_root+g" /boot/grub2/grub.cfg
EOT
