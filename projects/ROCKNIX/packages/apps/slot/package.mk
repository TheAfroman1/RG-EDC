# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="slot"
PKG_VERSION="8fbc6084ece5bc9b4b18a0fb6ef423df21606f49"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/slot-cfw/slot"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust alsa-lib systemd libxkbcommon wayland mesa"
PKG_LONGDESC="slot. - a cartridge-shelf frontend for Game Boy, Game Boy Color and Game Boy Advance (Wayland build for sway)"
PKG_TOOLCHAIN="manual"

make_target() {
  export PKG_CONFIG_ALLOW_CROSS=1
  export PKG_CONFIG_SYSROOT_DIR="${SYSROOT_PREFIX}"
  export PKG_CONFIG_PATH="${SYSROOT_PREFIX}/usr/lib/pkgconfig:${SYSROOT_PREFIX}/usr/share/pkgconfig"
  export CC_aarch64_rocknix_linux_gnu="${CC}"
  export AR_aarch64_rocknix_linux_gnu="${AR}"
  export SLOT_VERSION="${PKG_VERSION:0:12}"
  export SLOT_GIT_HASH="${PKG_VERSION:0:12}"

  # The default "host" feature is the winit/glutin/cpal/gilrs desktop backend,
  # which runs as a Wayland client under sway.
  cargo build \
    --locked \
    --target ${TARGET_NAME} \
    --release \
    -p slot
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/slot ${INSTALL}/usr/bin/slot
  cp ${PKG_DIR}/scripts/start_slot.sh ${INSTALL}/usr/bin/start_slot.sh
  chmod 0755 ${INSTALL}/usr/bin/start_slot.sh

  mkdir -p ${INSTALL}/usr/config/modules
  cp "${PKG_DIR}/modules/Start slot.sh" ${INSTALL}/usr/config/modules/
  chmod 0755 "${INSTALL}/usr/config/modules/Start slot.sh"

  mkdir -p ${INSTALL}/usr/share/licenses/slot
  cp ${PKG_BUILD}/LICENSE ${INSTALL}/usr/share/licenses/slot/
  cp -a ${PKG_BUILD}/licenses/. ${INSTALL}/usr/share/licenses/slot/
  cp ${PKG_DIR}/CREDITS ${INSTALL}/usr/share/licenses/slot/
}
