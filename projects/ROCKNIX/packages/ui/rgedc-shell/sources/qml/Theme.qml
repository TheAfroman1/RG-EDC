// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
pragma Singleton
import QtQuick

// Black, brushed aluminum and walnut.
QtObject {
  readonly property string sans: "Archivo"
  readonly property string mono: "IBM Plex Mono"
  // Static wdth=68 cut of Archivo for the big numerals (Qt can't pick a width axis).
  readonly property string condensed: "Archivo Condensed"

  readonly property color bg: "#08080a"
  readonly property color bgDeep: "#050506"
  readonly property color text: "#eceded"
  readonly property color textBright: "#f2f3f4"
  readonly property color textDim: "#a3a8ae"
  readonly property color textMute: "#8f949b"
  readonly property color textOff: "#7f848b"
  readonly property color line: "#2c2e32"
  readonly property color panel: "#111113"
  readonly property color panelLine: "#2a2c30"
  readonly property color copper: "#b07a4c"
  readonly property color copperDark: "#80502f"
  readonly property color walnutDark: "#5f3a23"
  readonly property color cream: "#f1e6da"
  readonly property color creamDim: "#e7d3bf"
  readonly property color nixie: "#ffb36b"
  readonly property color nixieHot: "#ff7a1a"

  // Shared motion
  readonly property int fast: 180
  readonly property int med: 280
  readonly property int slow: 420
}
