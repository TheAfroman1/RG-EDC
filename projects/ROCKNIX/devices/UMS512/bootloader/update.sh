#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

[ -z "$SYSTEM_ROOT" ] && SYSTEM_ROOT=""
[ -z "$BOOT_ROOT" ] && BOOT_ROOT="/flash"
[ -z "$BOOT_PART" ] && BOOT_PART=$(df "$BOOT_ROOT" | tail -1 | awk {' print $1 '})

# identify the boot device
if [ -z "$BOOT_DISK" ]; then
  case $BOOT_PART in
    /dev/mmcblk*)
      BOOT_DISK=$(echo $BOOT_PART | sed -e "s,p[0-9]*,,g")
      ;;
  esac
fi

mount -o remount,rw $BOOT_ROOT

echo "Updating device tree..."
cp -f $SYSTEM_ROOT/usr/share/bootloader/ums512-rg-rotate.dtb $BOOT_ROOT/

UBOOT_PART=$(blkid -t PARTLABEL=uboot -o device 2>/dev/null | grep "^${BOOT_DISK}" | head -1)
if [ -n "$UBOOT_PART" ] && [ -f $SYSTEM_ROOT/usr/share/bootloader/u-boot-ums512.img ]; then
  echo "Updating u-boot on $UBOOT_PART..."
  dd if=$SYSTEM_ROOT/usr/share/bootloader/u-boot-ums512.img of=$UBOOT_PART conv=fsync >/dev/null 2>&1
fi

mount -o remount,ro $BOOT_ROOT
sync
