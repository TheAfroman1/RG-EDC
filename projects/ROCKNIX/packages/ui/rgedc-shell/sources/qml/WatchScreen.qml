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

  // Unread phone notifications: a small pill above the face.
  Rectangle {
    id: pill
    readonly property var latest: Phone.count ? Phone.notifications[0] : null
    anchors.horizontalCenter: parent.horizontalCenter
    y: Phone.unread > 0 ? 10 : -height
    Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
    width: Math.min(560, prow.width + 36); height: 34; radius: 17
    color: "#141518"; border.color: "#2f3135"
    visible: y > -height
    Row {
      id: prow
      anchors.centerIn: parent
      spacing: 10
      Rectangle { width: 10; height: 10; radius: 5; color: Theme.copper; anchors.verticalCenter: parent.verticalCenter }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String(Phone.unread)
        font.family: Theme.mono; font.pixelSize: 15; font.weight: Font.Medium; color: Theme.creamDim
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 440)
        elide: Text.ElideRight
        text: pill.latest ? [pill.latest.app, pill.latest.title].filter(s => s).join(" · ") : ""
        font.family: Theme.sans; font.pixelSize: 15; color: Theme.textDim
      }
    }
  }

  Text {
    id: hint
    anchors.bottom: parent.bottom; anchors.bottomMargin: 26
    anchors.horizontalCenter: parent.horizontalCenter
    text: Phone.count ? "←→ FACE   ↓ NOTIFICATIONS   A HOME" : "←→ FACE   A HOME"
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
    if (b === "down" && Phone.count) { Nav.go("notifications"); return true }
    if (b === "up" || b === "down") return true
    Nav.go("home")
    return true
  }
}
