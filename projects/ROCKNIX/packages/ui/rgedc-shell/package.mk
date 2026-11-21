# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="rgedc-shell"
PKG_VERSION="1.0"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain qt6 SDL2 noto-color-emoji"
PKG_LONGDESC="RG EDC shell: watch faces, music, cartridge shelves and settings for the RG Rotate (Qt Quick)"
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_BUILD_TYPE=Release \
                       -DCMAKE_INSTALL_PREFIX=/usr \
                       -DQT_HOST_PATH=${TOOLCHAIN}/usr/local/qt6"

unpack() {
  mkdir -p ${PKG_BUILD}
  cp -a ${PKG_DIR}/sources/. ${PKG_BUILD}/
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  # The binary sits behind a wrapper that sets up the Wayland session.
  cp ${PKG_BUILD}/.${TARGET_NAME}/rgedc-shell ${INSTALL}/usr/bin/rgedc-shell.bin
  cp ${PKG_DIR}/scripts/rgedc-shell ${INSTALL}/usr/bin/rgedc-shell
  chmod 0755 ${INSTALL}/usr/bin/rgedc-shell ${INSTALL}/usr/bin/rgedc-shell.bin

  mkdir -p ${INSTALL}/usr/share/rgedc-shell
  cp -a ${PKG_BUILD}/qml ${INSTALL}/usr/share/rgedc-shell/
  rm -f ${INSTALL}/usr/share/rgedc-shell/qml/ShotTour.qml
  cp -a ${PKG_BUILD}/fonts ${INSTALL}/usr/share/rgedc-shell/

  mkdir -p ${INSTALL}/usr/share/licenses/rgedc-shell
  cp ${PKG_BUILD}/fonts/OFL-*.txt ${INSTALL}/usr/share/licenses/rgedc-shell/
}
