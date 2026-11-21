#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC
#
# What the RG EDC session starts in sway (run by essway.service):
#   1. /storage/.config/rgedc/boot_es exists -> EmulationStation, as before.
#   2. /usr/bin/rgedc-shell exists           -> the RG EDC shell (EmulationStation
#      if it fails at start-up).
#   3. otherwise (interim)                   -> slot.; leaving it ("Back to
#      RG EDC", or B on the shelf) continues into EmulationStation for every
#      system slot doesn't cover.

. /etc/profile

if [ -e /storage/.config/rgedc/boot_es ]; then
  exec /usr/bin/start_es.sh "$@"
fi

if [ -x /usr/bin/rgedc-shell ]; then
  START=$(date +%s)
  /usr/bin/rgedc-shell "$@"
  RC=$?
  # Settings > Start in EmulationStation sets the flag and quits.
  [ -e /storage/.config/rgedc/boot_es ] && exec /usr/bin/start_es.sh "$@"
  # If the shell dies right away, don't loop on a black screen: run ES this
  # time (essway restarts us, and the shell is tried again, when ES exits).
  if [ ${RC} -ne 0 ] && [ $(( $(date +%s) - START )) -lt 20 ]; then
    echo "rgedc-shell exited with ${RC} at start-up, falling back to EmulationStation" >>/var/log/rgedc-shell.log
    exec /usr/bin/start_es.sh "$@"
  fi
  exit ${RC}
fi

if [ -x /usr/bin/start_slot.sh ]; then
  SLOT_BACK_EXITS=1 /usr/bin/start_slot.sh >/var/log/slot.log 2>&1
fi

exec /usr/bin/start_es.sh "$@"
