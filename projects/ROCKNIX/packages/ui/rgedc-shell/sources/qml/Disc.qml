// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// A CD-based game: silver disc with the scraped art printed on its label.
Item {
  id: d
  property string title: ""
  property url art: ""
  property string system: ""
  width: 240; height: 240
  function hue(s) { var h = 0; for (var i = 0; i < s.length; ++i) h = (h * 31 + s.charCodeAt(i)) >>> 0; return (h % 360) / 360 }

  AluRing { anchors.fill: parent; angle: 0.5 }
  CircleImage {
    id: discPrint
    anchors.centerIn: parent
    width: 224; height: 224; hole: 40
    source: d.art
    fallback: Qt.hsla(d.hue(d.title), 0.45, 0.28, 1)
  }
  // Text printed on art-less discs
  Text {
    visible: d.art == ""
    anchors.horizontalCenter: parent.horizontalCenter
    y: 26
    text: d.system.toUpperCase()
    font.family: Theme.mono; font.pixelSize: 9; font.letterSpacing: 2
    color: Qt.rgba(1, 1, 1, 0.75)
  }
  Text {
    visible: d.art == ""
    x: 34; width: parent.width - 68; y: 150
    horizontalAlignment: Text.AlignHCenter
    text: d.title
    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
    font.family: Theme.sans; font.pixelSize: 18; font.weight: Font.ExtraBold
    color: "#ffffff"
  }
  // Clear hub
  Rectangle {
    anchors.centerIn: parent; width: 80; height: 80; radius: 40
    color: Qt.rgba(0.86, 0.88, 0.9, 0.45); border.color: Qt.rgba(1, 1, 1, 0.4); border.width: 1
  }
  Rectangle {
    anchors.centerIn: parent; width: 52; height: 52; radius: 26
    color: Qt.rgba(1, 1, 1, 0.12)
  }
  Rectangle { anchors.centerIn: parent; width: 30; height: 30; radius: 15; color: "#050506"; border.color: Qt.rgba(1, 1, 1, 0.35); border.width: 1 }
  // Shine
  Rectangle {
    anchors.centerIn: parent; width: 240; height: 240; radius: 120
    rotation: -30
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
      GradientStop { position: 0.47; color: Qt.rgba(1, 1, 1, 0.12) }
      GradientStop { position: 0.53; color: Qt.rgba(1, 1, 1, 0.0) }
    }
  }
}
