// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import QtQuick.Effects

MultiEffect {
  source: parent ? parent.target : null
  anchors.fill: parent
  blurEnabled: true
  blur: parent ? parent.blur : 1
  blurMax: 48
  brightness: 0.3
  colorization: 1.0
  colorizationColor: parent ? parent.color : "#ff6a00"
  opacity: parent ? parent.strength : 1
}
