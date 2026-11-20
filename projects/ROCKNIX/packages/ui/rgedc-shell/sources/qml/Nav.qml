// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
pragma Singleton
import QtQuick

// Which screen is showing: watch, home, music, games, settings, visualizer.
QtObject {
  property string screen: "watch"
  property string previous: "home"
  function go(s) {
    if (s === screen) return
    previous = screen
    screen = s
  }
  function back() { go(previous === screen ? "home" : previous) }
}
