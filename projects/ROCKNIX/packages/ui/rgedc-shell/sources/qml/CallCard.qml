// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Incoming call on the paired phone: A answers on the phone, B declines.
// Main.qml routes the buttons here while Phone.ringing.
Rectangle {
  id: cc
  width: 720; height: 720
  color: "#050506"
  visible: opacity > 0
  opacity: Phone.ringing ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: Theme.med } }

  // Keeps the last call on screen while the card fades out.
  property var call: ({})
  Connections {
    target: Phone
    function onCallChanged() { if (Phone.ringing) cc.call = Phone.call }
  }

  // Slow pulse rings behind the name
  Repeater {
    model: 3
    Rectangle {
      required property int index
      anchors.centerIn: parent; anchors.verticalCenterOffset: -60
      width: 260; height: 260; radius: 130
      color: "transparent"; border.color: Theme.copper; border.width: 2
      opacity: 0
      SequentialAnimation on scale {
        running: Phone.ringing; loops: Animation.Infinite
        PauseAnimation { duration: index * 600 }
        NumberAnimation { from: 0.6; to: 1.9; duration: 1800; easing.type: Easing.OutCubic }
      }
      SequentialAnimation on opacity {
        running: Phone.ringing; loops: Animation.Infinite
        PauseAnimation { duration: index * 600 }
        NumberAnimation { from: 0.7; to: 0; duration: 1800 }
      }
    }
  }

  Column {
    anchors.centerIn: parent; anchors.verticalCenterOffset: -60
    spacing: 12
    width: 600
    Text {
      width: parent.width; horizontalAlignment: Text.AlignHCenter
      text: "INCOMING CALL"
      font.family: Theme.mono; font.pixelSize: 14; font.letterSpacing: 4
      color: Theme.copper
    }
    Text {
      width: parent.width; horizontalAlignment: Text.AlignHCenter
      text: cc.call.name || cc.call.number || "Unknown"
      elide: Text.ElideRight
      font.family: Theme.sans; font.pixelSize: 52; font.weight: Font.Bold; font.letterSpacing: -1
      color: Theme.text
    }
    Text {
      width: parent.width; horizontalAlignment: Text.AlignHCenter
      visible: text !== ""
      text: cc.call.name ? (cc.call.number || "") : ""
      font.family: Theme.mono; font.pixelSize: 18
      color: Theme.textDim
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 540
    spacing: 28
    Repeater {
      model: [
        { key: "B", label: cc.call.neg || "Decline", warm: false },
        { key: "A", label: cc.call.pos || "Answer", warm: true },
      ]
      delegate: Item {
        required property var modelData
        width: 240; height: 64
        Rectangle {
          anchors.fill: parent; radius: 32
          visible: !modelData.warm
          color: "#1a1b1e"; border.color: Theme.line
        }
        Walnut { anchors.fill: parent; radius: 32; visible: modelData.warm; seed: 3 }
        Row {
          anchors.centerIn: parent
          spacing: 10
          Rectangle {
            width: 28; height: 28; radius: 14
            color: modelData.warm ? Theme.cream : "#2a2b2f"
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: modelData.key; font.family: Theme.mono; font.pixelSize: 14; font.weight: Font.Medium; color: modelData.warm ? "#4a2b18" : Theme.text }
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            font.family: Theme.sans; font.pixelSize: 20; font.weight: Font.DemiBold
            color: modelData.warm ? "#f6ece2" : Theme.text
          }
        }
      }
    }
  }
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 626
    text: "Answering picks up on " + (Phone.name || "the phone")
    font.family: Theme.sans; font.pixelSize: 15
    color: Theme.textMute
  }

  function handle(b) {
    if (b === "a") { Phone.answer(true); return true }
    if (b === "b") { Phone.answer(false); return true }
    return true
  }
}
