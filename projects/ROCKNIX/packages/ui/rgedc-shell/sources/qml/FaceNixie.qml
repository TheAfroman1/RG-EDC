// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Six nixie tubes on a walnut plinth with an aluminum cap.
Item {
  id: face
  width: 720; height: 720
  property bool seconds: System.settingsRevision >= 0 && System.flag("nixieSeconds", true)
  readonly property string str: Clock.pad(Clock.h12) + ":" + Clock.pad(Clock.m) + (seconds ? ":" + Clock.pad(Clock.s) : "")
  readonly property bool lit: Clock.s % 2 === 0
  readonly property int tw: seconds ? 84 : 120

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#120d09" }
      GradientStop { position: 0.55; color: "#0a0807" }
      GradientStop { position: 1.0; color: "#040404" }
    }
  }
  Text {
    y: 92; width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: Clock.longDow + " · " + Clock.day + " " + Clock.mon
    font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 4
    color: Theme.textMute
  }

  Row {
    id: tubes
    anchors.horizontalCenter: parent.horizontalCenter
    y: 470 - 250
    spacing: 10
    Repeater {
      model: face.str.length
      delegate: Item {
        id: slot
        required property int index
        readonly property string modelData: face.str.charAt(index)
        readonly property bool sep: modelData === ":"
        width: sep ? 26 : face.tw
        height: 250
        // Colon: two glowing dots.
        Column {
          visible: slot.sep
          anchors.horizontalCenter: parent.horizontalCenter
          y: 70; spacing: 34
          Repeater {
            model: 2
            Rectangle {
              width: 12; height: 12; radius: 6
              color: face.lit ? Theme.nixie : "#3a2a20"
              Behavior on color { ColorAnimation { duration: 250 } }
              Rectangle { anchors.centerIn: parent; width: 26; height: 26; radius: 13; color: Theme.nixieHot; opacity: face.lit ? 0.25 : 0; z: -1 }
            }
          }
        }
        // Tube
        Item {
          visible: !slot.sep
          anchors.fill: parent
          Rectangle {
            id: glass
            anchors.fill: parent
            radius: width / 2
            color: "#140e0a"
            border.color: Qt.rgba(0.86, 0.88, 0.9, 0.28); border.width: 1.5
            Rectangle {
              anchors.fill: parent; anchors.margins: 1.5; radius: parent.radius
              gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 0.47, 0.16, 0.05) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 0.47, 0.16, 0.12) }
                GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.05, 0.04, 0.95) }
              }
            }
          }
          // Square bottom half of the tube
          Rectangle { y: parent.height - 70; width: parent.width; height: 70; radius: 10; color: "#0d0907"; border.color: glass.border.color; border.width: 1.5 }
          Rectangle { x: 1.5; y: parent.height - 72; width: parent.width - 3; height: 6; color: "#0d0907" }
          // Mesh
          Grid {
            x: 10; y: 30; width: parent.width - 20; height: parent.height - 60
            columns: Math.max(1, Math.floor(width / 6)); rows: Math.max(1, Math.floor(height / 6))
            opacity: 0.10
            Repeater {
              model: parent.columns * parent.rows
              Rectangle { width: 6; height: 6; color: "transparent"; border.color: "#a08c78"; border.width: 0.5 }
            }
          }
          // Unlit cathodes behind
          Repeater {
            model: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            Text {
              required property string modelData
              visible: !slot.sep && modelData !== slot.modelData
              y: 34; width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              font.family: Theme.condensed; font.pixelSize: 150; font.weight: Font.Light
              color: Qt.rgba(0.59, 0.51, 0.45, 0.10)
            }
          }
          Glow { target: digit; color: Theme.nixieHot; blur: 0.8; strength: 0.9 }
          Text {
            id: digit
            y: 34; width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: slot.modelData
            font.family: Theme.condensed; font.pixelSize: 150; font.weight: Font.Light
            color: Theme.nixie
            style: Text.Outline; styleColor: Qt.rgba(1, 0.42, 0, 0.35)
            SequentialAnimation on opacity {
              loops: Animation.Infinite
              PauseAnimation { duration: 6700 + Math.random() * 1800 }
              NumberAnimation { to: 0.82; duration: 60 }
              NumberAnimation { to: 1.0; duration: 60 }
              NumberAnimation { to: 0.9; duration: 60 }
              NumberAnimation { to: 1.0; duration: 60 }
            }
          }
          // Glass highlight
          Rectangle {
            x: 6; y: 6; width: 26; height: 170; radius: 13
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
              GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
          }
        }
      }
    }
  }

  Alu { x: 60; y: 462; width: 600; height: 10; radius: 4 }
  Walnut {
    x: 60; y: 470; width: 600; height: 74; radius: 10; seed: 23
  }
  Item {
    x: 60; y: 470; width: 600; height: 74
    Text {
      x: 28; anchors.verticalCenter: parent.verticalCenter
      text: "RG EDC"; font.family: Theme.sans; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 5
      color: Theme.cream
    }
    Row {
      anchors.centerIn: parent; spacing: 10
      Repeater { model: 3; AluRing { width: 12; height: 12 } }
    }
    Text {
      anchors.right: parent.right; anchors.rightMargin: 28; anchors.verticalCenter: parent.verticalCenter
      text: (System.charging ? "CHG " : "BATT ") + System.battery + "%"
      font.family: Theme.mono; font.pixelSize: 14; color: Theme.cream
    }
  }

  Text {
    y: 600; width: parent.width
    horizontalAlignment: Text.AlignHCenter
    visible: Player.hasTrack
    text: (Player.title + (Player.artist ? " · " + Player.artist : "")).toUpperCase()
    elide: Text.ElideRight
    font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 2
    color: Theme.textMute
  }
}
