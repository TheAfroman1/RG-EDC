// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// The watch: analog, digital or nixie. ◀▶ changes the face, any other button
// opens Home.
Item {
  id: w
  width: 720; height: 720
  readonly property var faces: ["analog", "digital", "nixie"]
  property string face: System.settingsRevision >= 0 ? System.setting("watchFace", "analog") : "analog"

  Loader {
    id: l
    anchors.fill: parent
    source: w.face === "digital" ? "FaceDigital.qml" : w.face === "nixie" ? "FaceNixie.qml" : "FaceAnalog.qml"
  }

  Text {
    id: hint
    anchors.bottom: parent.bottom; anchors.bottomMargin: 26
    anchors.horizontalCenter: parent.horizontalCenter
    text: "←→ FACE   A HOME"
    font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 2
    color: Theme.textMute
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    Timer { id: hintTimer; interval: 2500; onTriggered: hint.opacity = 0 }
  }

  function cycle(d) {
    const i = (faces.indexOf(face) + d + faces.length) % faces.length
    System.setSetting("watchFace", faces[i])
    hint.opacity = 1; hintTimer.restart()
  }

  function handle(b) {
    if (b === "left") { cycle(-1); return true }
    if (b === "right") { cycle(1); return true }
    if (b === "up" || b === "down") return true
    Nav.go("home")
    return true
  }
}
