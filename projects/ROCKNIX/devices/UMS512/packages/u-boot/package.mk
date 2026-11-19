# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

PKG_NAME="u-boot"
PKG_VERSION="34afab15d051a89ebfc4d2dd1c8cda8e1ce56ea9"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/beebono/u-boot-ums512"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3:host"
PKG_LONGDESC="Unisoc vendor U-Boot for the Anbernic RG Rotate (ums512), loaded from SD by the patched SPL."
PKG_TOOLCHAIN="manual"

PKG_NEED_UNPACK="${PROJECT_DIR}/${PROJECT}/bootloader ${PROJECT_DIR}/${PROJECT}/devices/${DEVICE}/bootloader"

make_target() {
  [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0
  setup_pkg_config_host

  local uboot_make=(make ARCH=arm DEVICE_TREE=ums512_rg_rotate CROSS_COMPILE="${TARGET_KERNEL_PREFIX}"
    HOSTCC="${HOST_CC}" HOSTCFLAGS="-I${TOOLCHAIN}/include" HOSTLDFLAGS="${HOST_LDFLAGS}"
    KCFLAGS="-std=gnu11 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion")

  DEBUG=${PKG_DEBUG} LDFLAGS="" "${uboot_make[@]}" mrproper
  DEBUG=${PKG_DEBUG} LDFLAGS="" "${uboot_make[@]}" ums512_rg_rotate_defconfig
  DEBUG=${PKG_DEBUG} LDFLAGS="" "${uboot_make[@]}" u-boot-dtb.bin

  # The SPL loads u-boot from the SD's "uboot" GPT partition as a DHTB image
  python3 ${PKG_DIR}/scripts/dhtb_pack.py u-boot-dtb.bin u-boot-ums512.img
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/bootloader
    cp -av u-boot-ums512.img ${INSTALL}/usr/share/bootloader
}
