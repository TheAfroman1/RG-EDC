# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="rgedc-phone"
PKG_VERSION="0.1"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain Python3 dbussy bluez"
PKG_LONGDESC="RG EDC phone link: iPhone notifications (ANCS) and Android via Gadgetbridge, over Bluetooth LE"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/rgedc-phone ${INSTALL}/usr/bin/rgedc-phone
  chmod 0755 ${INSTALL}/usr/bin/rgedc-phone
}

post_install() {
  enable_service rgedc-phone.service
}
