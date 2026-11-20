// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Clock on the left; Wi-Fi, output and battery on the right.
Item {
  id: bar
  property string label: Clock.hm
  property bool showOutput: false
  width: parent ? parent.width : 720
  height: 64

  Text {
    anchors.left: parent.left; anchors.leftMargin: 36
    anchors.verticalCenter: parent.verticalCenter
    text: bar.label
    font.family: Theme.mono; font.pixelSize: 18; font.weight: Font.Medium
    color: Theme.text
  }
  Row {
    anchors.right: parent.right; anchors.rightMargin: 36
    anchors.verticalCenter: parent.verticalCenter
    spacing: 18
    Text {
      visible: bar.showOutput || System.audioOutput !== "Speaker"
      text: System.audioOutput.toUpperCase()
      font.family: Theme.mono; font.pixelSize: 15
      color: Theme.creamDim
    }
    Row {
      visible: Phone.connected || Phone.unread > 0
      spacing: 6
      anchors.verticalCenter: parent.verticalCenter
      Rectangle {
        visible: Phone.unread > 0
        width: 8; height: 8; radius: 4; color: Theme.copper
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: Phone.connected ? (Phone.kind === "ios" ? "IPHONE" : "PHONE") : String(Phone.unread)
        font.family: Theme.mono; font.pixelSize: 15
        color: Phone.connected ? Theme.textDim : Theme.textMute
      }
    }
    Text {
      text: System.wifi ? "WI-FI" : "WI-FI OFF"
      opacity: System.wifi ? 1 : 0.5
      font.family: Theme.mono; font.pixelSize: 15
      color: Theme.textDim
    }
    Row {
      spacing: 6
      visible: System.hasBattery
      anchors.verticalCenter: parent.verticalCenter
      Rectangle {
        width: 30; height: 14; radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"; border.color: Theme.textDim; border.width: 1.5
        Rectangle {
          x: 3; y: 3; height: parent.height - 6
          width: Math.max(2, (parent.width - 6) * System.battery / 100)
          radius: 1
          color: System.charging ? Theme.copper : (System.battery <= 15 ? "#d0573c" : "#d6d9dd")
        }
        Rectangle { x: parent.width + 1; y: 4; width: 2; height: 6; color: Theme.textDim }
      }
      Text {
        text: System.battery + "%" + (System.charging ? " CHG" : "")
        font.family: Theme.mono; font.pixelSize: 15
        color: Theme.textDim
      }
    }
  }
}
