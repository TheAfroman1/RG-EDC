// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// A soft glow of `target`, for placing behind it. Uses QtQuick.Effects when
// available (Qt 6.5+, as on the device); otherwise draws nothing.
Loader {
  id: l
  property Item target
  property color color: "#ff6a00"
  property real blur: 1.0
  property real strength: 1.0
  x: target ? target.x : 0
  y: target ? target.y : 0
  width: target ? target.width : 0
  height: target ? target.height : 0
  active: target !== null
  source: "GlowFx.qml"
  onStatusChanged: if (status === Loader.Error) active = false
}
