// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Shown when the screen is flipped shut while music plays: a ring of bars
// around the clock and the track. Controls are hidden; flip open to return.
Item {
  id: viz
  width: 720; height: 720
  readonly property int n: Spectrum.bands
  property int rot: System.settingsRevision >= 0 ? Number(System.setting("visualizerRotation", 0)) : 0

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#0d0906" }
      GradientStop { position: 0.6; color: "#000000" }
    }
  }

  Item {
    id: stage
    anchors.fill: parent
    rotation: viz.rot

    Repeater {
      model: viz.n
      delegate: Item {
        required property int index
        readonly property real v: Spectrum.levels[index] || 0
        x: 360; y: 360; width: 0; height: 0
        rotation: index / viz.n * 360 + 180
        Rectangle {
          x: -4; y: 140
          width: 8; radius: 4
          height: 18 + parent.v * 170
          opacity: 0.55 + parent.v * 0.45
          gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.walnutDark }
            GradientStop { position: 0.55; color: Theme.copper }
            GradientStop { position: 1.0; color: "#f0e2d2" }
          }
        }
      }
    }

    Rectangle {
      x: 230; y: 230; width: 260; height: 260; radius: 130
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#141416" }
        GradientStop { position: 1.0; color: "#060607" }
      }
      border.color: Theme.panelLine; border.width: 1
      Column {
        anchors.centerIn: parent
        width: 220
        spacing: 6
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Clock.hm
          font.family: Theme.condensed; font.pixelSize: 64; font.weight: Font.Light
          color: "#e4e6e9"
        }
        Text {
          width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
          text: Player.title
          font.family: Theme.sans; font.pixelSize: 17; font.weight: Font.DemiBold
          color: Theme.text
        }
        Text {
          width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
          text: Player.artist.toUpperCase()
          font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2
          color: Theme.textMute
        }
      }
    }
  }

  function handle(b) {
    // Buttons are covered while flipped; from the menu (testing) any button returns.
    if (System.lidClosed) return true
    if (b === "x") { System.setSetting("visualizerRotation", (rot + 90) % 360); return true }
    Nav.back()
    return true
  }
}
