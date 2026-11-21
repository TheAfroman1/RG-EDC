#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC
#
# Launch slot. from EmulationStation (Tools > Start slot.) or from SSH.
# ES keeps running and waits for this script, like other ROCKNIX apps; slot
# opens as a Wayland client and is made fullscreen in sway.
# slot keeps everything under SLOT_ROOT; map its folders onto ROCKNIX's ROM
# folders and libretro cores instead of copying anything.

. /etc/profile

SLOT_BIN="${SLOT_BIN:-/usr/bin/slot}"
SLOT_ROOT="${SLOT_ROOT:-/storage/slot}"
export SLOT_ROOT

"${SLOT_BIN}" --init-root "${SLOT_ROOT}"

link() {
  # $1 = target, $2 = link inside SLOT_ROOT; replace only empty dirs/old links
  if [ -L "${SLOT_ROOT}/$2" ] || { [ -d "${SLOT_ROOT}/$2" ] && [ -z "$(ls -A "${SLOT_ROOT}/$2")" ]; }; then
    rm -rf "${SLOT_ROOT:?}/$2"
    ln -s "$1" "${SLOT_ROOT}/$2"
  fi
}

mkdir -p /storage/roms/gb /storage/roms/gbc /storage/roms/gba
link /storage/roms/gb   Games/GB
link /storage/roms/gbc  Games/GBC
link /storage/roms/gba  Games/GBA
link /storage/roms/bios BIOS

mkdir -p "${SLOT_ROOT}/System"
for core in mgba gpsp gambatte; do
  [ -e "/usr/lib/libretro/${core}_libretro.so" ] && \
    ln -sf "/usr/lib/libretro/${core}_libretro.so" "${SLOT_ROOT}/System/${core}_libretro.so"
done

# Join the sway session (sway.service: XDG_RUNTIME_DIR=/var/run/0-runtime-dir,
# socket wayland-1) when started from SSH or the serial console.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run/0-runtime-dir}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

# Borderless window at the panel size; sway makes it fullscreen over ES.
export SLOT_BARE=1
export SLOT_WINDOW="${SLOT_WINDOW:-720x720}"

set_kill set "slot"
sway_fullscreen "slot" pidof &

"${SLOT_BIN}" "$@"
RC=$?
set_kill stop
exit ${RC}
