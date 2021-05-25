#!/bin/bash

# Creating LV for /home

lvcreate -n LogVol_Home -L 2G /dev/VolGroup00

mkfs.xfs /dev/VolGroup00/LogVol_Home

mount /dev/VolGroup00/LogVol_Home /mnt/

cp -aR /home/* /mnt/

rm -rf /home/*

umount /mnt

mount /dev/VolGroup00/LogVol_Home /home/

echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab

touch /home/file{1..20}

lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home

rm -f /home/file{11..20}

umount /home

lvconvert --merge /dev/VolGroup00/home_snap

mount /home

# Creating LV for /opt

yes|lvremove /dev/vg_root/lv_root

yes|vgremove /dev/vg_root

yes|pvremove /dev/sdb

wipefs /dev/sdb

pvcreate /dev/sdb /dev/sde

vgcreate vg_opt /dev/sdb /dev/sde

yes|lvcreate -L 4G -n lv_opt vg_opt /dev/sdb

lvcreate -L 128M -n lv_opt_meta vg_opt /dev/sde

lvcreate -l +80%FREE -n lv_opt_cache vg_opt /dev/sde

mkfs.btrfs /dev/vg_opt/lv_opt

yes|lvconvert --type cache-pool --cachemode writethrough --poolmetadata vg_opt/lv_opt_meta vg_opt/lv_opt_cache

yes|lvconvert --type cache --cachepool lv_opt_cache vg_opt/lv_opt

mount /dev/vg_opt/lv_opt /opt

echo "`blkid | grep lv_opt | awk '{print $2}'` /opt btrfs defaults 0 0" >> /etc/fstab

touch /opt/file{1..100}

lvcreate -L 512M -s -n opt_snap /dev/vg_opt/lv_opt

rm -f /opt/file{45..78}

umount /opt

lvconvert --merge /dev/vg_opt/opt_snap

mount /opt
