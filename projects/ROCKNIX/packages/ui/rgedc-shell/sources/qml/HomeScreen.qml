// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Big type menu on the left, a card for the selected item on the right.
Item {
  id: home
  width: 720; height: 720
  property int sel: 0
  readonly property int dragStep: 80

  readonly property var lastGame: Library.recents.length ? Library.recents[0] : null
  readonly property var items: [
    { key: "music", label: "Music",
      kicker: Player.hasTrack ? (Player.playing ? "NOW PLAYING" : "PAUSED") : "MUSIC",
      title: Player.hasTrack ? Player.title : (Library.tracks.length ? Library.tracks.length + " tracks" : "No music yet"),
      sub: Player.hasTrack ? [Player.artist, Player.album].filter(s => s).join(" · ") + "\n" + Player.format + " · " + System.audioOutput
                           : (Library.tracks.length ? "From /storage/music" : "Copy albums to the music folder\nover Wi-Fi or the SD card"),
      action: "Open player" },
    { key: "games", label: "Games",
      kicker: lastGame ? "CONTINUE" : "GAMES",
      title: lastGame ? lastGame.name : Library.systems.length + " systems",
      sub: lastGame ? (Library.system(lastGame.system).fullname || lastGame.system) + "\nLast played"
                    : "Cartridges and discs from the\nROM folders, oldest systems first",
      action: lastGame ? "Open shelf" : "Open shelves" },
    { key: "notifications", label: "Phone",
      kicker: Phone.unread ? Phone.unread + " NEW" : (Phone.connected ? "CONNECTED" : "PHONE"),
      title: Phone.count ? (Phone.notifications[0].title || Phone.notifications[0].app)
                         : (Phone.connected ? "All caught up" : (Phone.known.length ? "Not connected" : "No phone yet")),
      sub: Phone.count ? (Phone.notifications[0].app || "") + "\n" + Phone.count + " notification" + (Phone.count === 1 ? "" : "s")
                       : (Phone.connected ? Phone.name : (Phone.available ? "Pair an iPhone or Android phone\nin Settings › Phone" : "Turn Bluetooth on to\nlink a phone")),
      action: Phone.count ? "Open notifications" : "Open" },
    { key: "watch", label: "Watch",
      kicker: "WATCH FACE",
      title: ({ analog: "Analog, aluminum", digital: "Digital, walnut", nixie: "Nixie tubes" })[System.settingsRevision >= 0 ? System.setting("watchFace", "analog") : "analog"],
      sub: "Shown when idle.\n←→ on the watch changes the face.",
      action: "Show watch" },
    { key: "settings", label: "Settings",
      kicker: "SYSTEM",
      title: "Display, sound, buttons",
      sub: "Output: " + System.audioOutput + "\nWi-Fi " + (System.wifi ? "connected" : "off"),
      action: "Open settings" },
  ]
  readonly property var cur: items[sel]

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#16161a" }
      GradientStop { position: 0.6; color: "#08080a" }
    }
  }

  StatusBar { id: status }

  Column {
    id: menu
    x: 0; y: 64 + (720 - 128 - height) / 2
    width: 360
    spacing: 6
    Repeater {
      model: home.items
      delegate: Item {
        required property var modelData
        required property int index
        readonly property bool on: index === home.sel
        width: 360; height: 92
        function tapAction(x, y) { home.sel = index; home.handle("a") }
        Walnut {
          width: parent.on ? 14 : 0; height: 64
          anchors.verticalCenter: parent.verticalCenter
          topRightRadius: 4; bottomRightRadius: 4; topLeftRadius: 0; bottomLeftRadius: 0
          Behavior on width { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
        }
        Text {
          x: 34 + (parent.on ? 12 : 0)
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.label
          font.family: Theme.sans; font.pixelSize: 72
          font.weight: parent.on ? Font.Bold : Font.Normal
          font.letterSpacing: parent.on ? -2 : 0
          color: parent.on ? Theme.text : Theme.textOff
          scale: parent.on ? 1 : 40 / 72
          transformOrigin: Item.Left
          Behavior on x { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
          Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
        }
      }
    }
  }

  // Card
  Rectangle {
    x: 384; y: 64 + (720 - 128 - 400) / 2; width: 300; height: 400; radius: 22
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#1a1b1e" }
      GradientStop { position: 1.0; color: "#0e0e10" }
    }
    border.color: Theme.line; border.width: 1
    Text {
      x: 28; y: 28
      text: home.cur.kicker
      font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 3
      color: Theme.textMute
    }
    Column {
      x: 28; width: parent.width - 56
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: -10
      spacing: 10
      Text {
        width: parent.width
        text: home.cur.title
        wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: 30; font.weight: Font.DemiBold
        lineHeight: 1.05
        color: Theme.text
      }
      Text {
        width: parent.width
        text: home.cur.sub
        wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: 16; lineHeight: 1.3
        color: Theme.textDim
      }
    }
    Walnut {
      id: pill
      x: 28; y: parent.height - 28 - 52; width: parent.width - 56; height: 52; radius: 26; seed: 5
    }
    Row {
      anchors.centerIn: pill
      spacing: 10
      Rectangle {
        width: 26; height: 26; radius: 13; color: Theme.cream
        anchors.verticalCenter: parent.verticalCenter
        Text { anchors.centerIn: parent; text: "A"; font.family: Theme.mono; font.pixelSize: 14; font.weight: Font.Medium; color: "#4a2b18" }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: home.cur.action
        font.family: Theme.sans; font.pixelSize: 17; font.weight: Font.DemiBold
        color: "#f6ece2"
      }
    }
  }

  Hints {
    anchors.bottom: parent.bottom
    model: ["↑↓ MOVE", "A OPEN", "B WATCH", ">FLIP: VISUALIZER"]
  }

  function handle(b) {
    if (b === "up") { sel = (sel + items.length - 1) % items.length; return true }
    if (b === "down") { sel = (sel + 1) % items.length; return true }
    if (b === "a" || b === "right") { Nav.go(cur.key); return true }
    if (b === "b") { Nav.go("watch"); return true }
    if (b === "start") { Player.toggle(); return true }
    return false
  }
}
