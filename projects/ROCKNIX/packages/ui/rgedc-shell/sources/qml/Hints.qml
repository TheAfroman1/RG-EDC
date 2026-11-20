// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// Footer button hints: model is a list of strings; "*text" is highlighted,
// ">text" is pushed to the right edge.
Item {
  id: h
  property var model: []
  width: parent ? parent.width : 720
  height: 64
  Row {
    anchors.left: parent.left; anchors.leftMargin: 36
    anchors.verticalCenter: parent.verticalCenter
    spacing: 28
    Repeater {
      model: h.model.filter(s => s[0] !== ">")
      Text {
        required property string modelData
        text: modelData[0] === "*" ? modelData.slice(1) : modelData
        font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 1
        color: modelData[0] === "*" ? Theme.creamDim : Theme.textMute
      }
    }
  }
  Row {
    anchors.right: parent.right; anchors.rightMargin: 36
    anchors.verticalCenter: parent.verticalCenter
    spacing: 28
    Repeater {
      model: h.model.filter(s => s[0] === ">")
      Text {
        required property string modelData
        text: modelData.slice(1)
        font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 1
        color: Theme.textMute
      }
    }
  }
}
