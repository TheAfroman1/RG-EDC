#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC
#
# EmulationStation Tools entry: go back to the RG EDC shell and boot into it
# from now on.

rm -f /storage/.config/rgedc/boot_es
if pgrep -f rgedc-shell.bin >/dev/null; then
  # ES was opened from the shell's Settings; closing it returns there.
  killall emulationstation
else
  systemctl restart essway.service
fi
