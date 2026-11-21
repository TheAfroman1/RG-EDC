# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="noto-color-emoji"
PKG_VERSION="2.051"
PKG_LICENSE="OFL-1.1"
PKG_SITE="https://github.com/googlefonts/noto-emoji"
PKG_URL="https://raw.githubusercontent.com/googlefonts/noto-emoji/v${PKG_VERSION}/fonts/NotoColorEmoji.ttf"
PKG_SOURCE_NAME="NotoColorEmoji-${PKG_VERSION}.ttf"
PKG_SHA256="72a635cb3d2f3524c51620cdde406b217204e8a6a06c6a096ff8ed4b5fd6e27b"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Noto Color Emoji font"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}
  cp -f ${SOURCES}/${PKG_NAME}/${PKG_SOURCE_NAME} ${PKG_BUILD}/NotoColorEmoji.ttf
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/fonts/truetype/noto-emoji
  cp -f ${PKG_BUILD}/NotoColorEmoji.ttf ${INSTALL}/usr/share/fonts/truetype/noto-emoji/
}
