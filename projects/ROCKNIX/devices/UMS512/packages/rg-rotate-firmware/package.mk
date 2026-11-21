# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="rg-rotate-firmware"
PKG_VERSION="94d2d273c20aeabec2b4c6b160e33e0c2d26dd41"
PKG_LICENSE="proprietary"
PKG_SITE="https://github.com/beebono/rg-rotate-linux"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="AGDSP, WCN (Wi-Fi/BT) and GNSS firmware for the Anbernic RG Rotate"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_firmware_dir)
    cp -a src/initramfs/overlay/lib/firmware/* ${INSTALL}/$(get_full_firmware_dir)
}
