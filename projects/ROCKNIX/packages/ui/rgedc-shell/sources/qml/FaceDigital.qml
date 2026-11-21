// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Walnut spine with the date, tall condensed aluminum numerals.
Item {
  width: 720; height: 720
  Rectangle { anchors.fill: parent; color: "#070708" }

  Walnut {
    id: spine
    width: 112; height: 720
    seed: 11
  }
  Rectangle { x: 112; width: 1; height: 720; color: "#ffffff"; opacity: 0.12 }
  Item {
    x: 0; y: 48; width: 112; height: spineText.implicitWidth
    Text {
      id: spineText
      anchors.centerIn: parent
      rotation: -90
      text: "RG EDC"
      font.family: Theme.sans; font.pixelSize: 20; font.weight: Font.Bold; font.letterSpacing: 8
      color: Theme.cream
    }
  }
  Column {
    anchors.horizontalCenter: spine.horizontalCenter
    anchors.bottom: parent.bottom; anchors.bottomMargin: 48
    spacing: 2
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Clock.dow; font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 3; color: Theme.cream }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Clock.day; font.family: Theme.mono; font.pixelSize: 40; font.weight: Font.Medium; color: Theme.cream }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Clock.mon; font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 3; color: Theme.cream }
  }

  Column {
    x: 160; width: 512
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8
    Text {
      text: "LOCAL TIME"
      font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 4
      color: Theme.textMute
    }
    Column {
      spacing: -34
      Repeater {
        model: [Clock.pad(Clock.h12), Clock.pad(Clock.m)]
        delegate: Text {
          required property string modelData
          text: modelData
          font.family: Theme.condensed; font.pixelSize: 236; font.weight: Font.Light
          font.letterSpacing: -4
          lineHeight: 0.86
          color: "#dfe2e5"
        }
      }
    }
    Rectangle {
      width: parent.width; height: 4; radius: 2; color: "#1c1d20"
      Rectangle {
        height: 4; radius: 2; color: Theme.copper
        width: parent.width * Clock.s / 59
        Behavior on width { NumberAnimation { duration: 900 } }
      }
    }
    Item { width: 1; height: 20 }
    Row {
      spacing: 12
      component Tile: Rectangle {
        property string label; property string value; property int size: 26
        width: 162; height: 84; radius: 10
        color: Theme.panel; border.color: Theme.panelLine; border.width: 1
        Column {
          x: 14; y: 14; spacing: 4; width: parent.width - 28
          Text { text: label; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2; color: Theme.textMute }
          Text { width: parent.width; text: value; elide: Text.ElideRight; font.family: Theme.sans; font.pixelSize: size; font.weight: Font.DemiBold; color: Theme.text }
        }
      }
      Tile { label: System.charging ? "CHARGING" : "BATTERY"; value: System.battery + "%" }
      Tile { label: "WI-FI"; value: System.wifi ? "On" : "Off" }
      Tile { label: Player.playing ? "PLAYING" : "MUSIC"; value: Player.hasTrack ? Player.title : "—"; size: 18 }
    }
  }
}
