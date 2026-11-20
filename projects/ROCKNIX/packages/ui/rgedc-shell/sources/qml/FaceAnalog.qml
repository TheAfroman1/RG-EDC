// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Aluminum bezel, walnut 12 marker, date window, battery subdial.
Item {
  id: face
  width: 720; height: 720

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#141417" }
      GradientStop { position: 0.6; color: "#0a0a0b" }
      GradientStop { position: 1.0; color: "#050506" }
    }
  }
  AluRing { x: 50; y: 50; width: 620; height: 620 }
  Rectangle {
    x: 76; y: 76; width: 568; height: 568; radius: 284
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#1b1b1e" }
      GradientStop { position: 0.7; color: "#0c0c0d" }
      GradientStop { position: 1.0; color: "#070708" }
    }
    border.color: "#000"; border.width: 2
  }

  Repeater {
    model: 60
    delegate: Item {
      required property int index
      visible: index !== 0
      readonly property bool major: index % 5 === 0
      x: 360; y: 360; width: 0; height: 0
      rotation: index * 6
      Rectangle {
        width: parent.major ? 10 : 3
        height: parent.major ? 40 : 14
        radius: 2
        x: -width / 2
        y: -(parent.major ? 236 : 250) - height / 2
        color: parent.major ? "#d6d8dc" : "#5b5f65"
        gradient: parent.major ? alu : null
      }
    }
  }
  Gradient {
    id: alu
    GradientStop { position: 0.0; color: "#f0f1f3" }
    GradientStop { position: 1.0; color: "#a9adb3" }
  }

  Walnut { x: 352; y: 96; width: 16; height: 46; radius: 3 }

  Column {
    y: 196; width: parent.width; spacing: 4
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "RG EDC"
      font.family: Theme.sans; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: 6
      color: "#d9dcdf"
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "EVERYDAY CARRY"
      font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 3
      color: Theme.textMute
    }
  }

  // Date window
  Rectangle {
    x: 486; y: 340; height: 40; width: dateRow.width + 24; radius: 6
    color: "#0e0e10"; border.color: "#3a3c40"; border.width: 1
    Row {
      id: dateRow
      anchors.centerIn: parent
      spacing: 8
      Text { text: Clock.dow; font.family: Theme.mono; font.pixelSize: 16; color: "#9aa0a7" }
      Text { text: Clock.day; font.family: Theme.mono; font.pixelSize: 16; font.weight: Font.Medium; color: Theme.textBright }
    }
  }

  // Battery subdial
  Rectangle {
    x: 300; y: 436; width: 120; height: 120; radius: 60
    color: "#0d0d0f"; border.color: "#34363a"; border.width: 1
    Canvas {
      id: batt
      anchors.centerIn: parent; width: 96; height: 96
      property real v: System.battery / 100
      onVChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        ctx.lineWidth = 5; ctx.lineCap = "round"
        ctx.strokeStyle = "#26282b"
        ctx.beginPath(); ctx.arc(48, 48, 42, 0, Math.PI * 2); ctx.stroke()
        ctx.strokeStyle = System.charging ? "#d9a46f" : Theme.copper
        ctx.beginPath(); ctx.arc(48, 48, 42, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v); ctx.stroke()
      }
    }
    Column {
      anchors.centerIn: parent
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: System.battery; font.family: Theme.mono; font.pixelSize: 22; font.weight: Font.Medium; color: Theme.textBright }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: System.charging ? "CHARGING" : "BATT %"; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 2; color: Theme.textMute }
    }
  }

  Text {
    y: 584; width: parent.width
    horizontalAlignment: Text.AlignHCenter
    visible: Player.hasTrack
    text: (Player.title + (Player.artist ? " · " + Player.artist : "")).toUpperCase()
    elide: Text.ElideRight
    font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 2
    color: Theme.textMute
  }

  // Hands
  component Hand: Item {
    id: hand
    property real w; property real len; property real tail; property real angle
    property alias fill: body.color
    property bool metal: true
    x: 360; y: 360
    rotation: angle
    Behavior on rotation { enabled: hand.metal; RotationAnimation { duration: 300; direction: RotationAnimation.Clockwise; easing.type: Easing.OutBack } }
    Rectangle { x: -hand.w / 2 + 3; y: -hand.len + 6; width: hand.w; height: hand.len + hand.tail; radius: hand.w / 2; color: "#000"; opacity: 0.45 }
    Rectangle {
      id: body
      x: -hand.w / 2; y: -hand.len; width: hand.w; height: hand.len + hand.tail; radius: hand.w / 2
      gradient: hand.metal ? handGrad : null
    }
  }
  Gradient {
    id: handGrad
    orientation: Gradient.Horizontal
    GradientStop { position: 0.0; color: "#aeb2b8" }
    GradientStop { position: 0.45; color: "#f3f4f6" }
    GradientStop { position: 1.0; color: "#9a9ea4" }
  }
  Hand { w: 14; len: 150; tail: 24; angle: (Clock.h % 12 + Clock.m / 60) * 30 }
  Hand { w: 10; len: 222; tail: 28; angle: (Clock.m + Clock.s / 60) * 6 }
  Hand { w: 3; len: 230; tail: 50; angle: Clock.s * 6; metal: false; fill: Theme.copper }
  AluRing { x: 349; y: 349; width: 22; height: 22 }
  Rectangle { x: 356; y: 356; width: 8; height: 8; radius: 4; color: Theme.copper }
}
