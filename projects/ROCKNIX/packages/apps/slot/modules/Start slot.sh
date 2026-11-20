#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC

# Tools menu entry: slot. cartridge frontend (Game Boy, Game Boy Color, GBA).
# Games are read from /storage/roms/gb, gbc and gba.

. /etc/profile

/usr/bin/start_slot.sh >/var/log/slot.log 2>&1
