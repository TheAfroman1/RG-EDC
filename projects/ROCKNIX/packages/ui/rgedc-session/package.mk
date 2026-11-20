# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="rgedc-session"
PKG_VERSION="1.0"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="RG EDC session: what the device boots into instead of EmulationStation"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/start_rgedc.sh ${INSTALL}/usr/bin/start_rgedc.sh
  chmod 0755 ${INSTALL}/usr/bin/start_rgedc.sh

  mkdir -p ${INSTALL}/usr/lib/systemd/system/essway.service.d
  cp ${PKG_DIR}/system.d/essway.service.d/10-rgedc-session.conf \
    ${INSTALL}/usr/lib/systemd/system/essway.service.d/
}
