// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// A new phone notification drops in from the top for a few seconds.
Item {
  id: banner
  width: 720; height: 720
  property var item: ({})
  property bool shown: false
  readonly property bool enabled_: System.settingsRevision >= 0 && System.flag("notifBanners", true)

  Connections {
    target: Phone
    function onPosted(it) {
      if (!banner.enabled_ || Nav.screen === "notifications") return
      banner.item = it
      banner.shown = true
      hide.restart()
    }
  }
  Timer { id: hide; interval: 5000; onTriggered: banner.shown = false }

  Rectangle {
    id: card
    x: 36; width: 648; height: col.height + 44
    y: banner.shown ? 22 : -height - 30
    Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
    radius: 22
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#1d1e22" }
      GradientStop { position: 1.0; color: "#111214" }
    }
    border.color: "#34363b"; border.width: 1
    opacity: banner.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.slow } }

    Walnut { x: 0; y: 0; width: 8; height: parent.height; topLeftRadius: 22; bottomLeftRadius: 22; topRightRadius: 0; bottomRightRadius: 0; seed: 11 }

    Column {
      id: col
      x: 34; y: 22; width: parent.width - 60
      spacing: 6
      Row {
        spacing: 12
        Text {
          text: (banner.item.app || "Phone").toUpperCase()
          font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2
          color: Theme.copper
        }
        Text {
          text: "NOW"
          font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2
          color: Theme.textMute
        }
      }
      Text {
        width: parent.width
        visible: text !== ""
        text: banner.item.title || ""
        elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: 26; font.weight: Font.DemiBold
        color: Theme.text
      }
      Text {
        width: parent.width
        visible: text !== ""
        text: [banner.item.subtitle, banner.item.body].filter(s => s).join(" · ")
        wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: 18; lineHeight: 1.25
        color: Theme.textDim
      }
    }
  }
}
