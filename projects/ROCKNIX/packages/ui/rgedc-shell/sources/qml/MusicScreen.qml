// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Now playing: a vinyl record or a CD spinning on walnut.
Item {
  id: music
  width: 720; height: 720
  property string disc: System.settingsRevision >= 0 ? System.setting("disc", "vinyl") : "vinyl"
  property bool listOpen: false

  function fmt(ms) {
    if (!(ms > 0)) return "0:00"
    const s = Math.floor(ms / 1000)
    return Math.floor(s / 60) + ":" + Clock.pad(s % 60)
  }

  Rectangle { anchors.fill: parent; color: Theme.bg }

  // Top row
  Item {
    x: 36; y: 36; width: 648; height: 20
    Text { text: "‹ HOME"; font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2; color: Theme.textDim }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Player.hasTrack ? "NOW PLAYING · " + (Player.index + 1) + " OF " + Player.queue.length
                            : (Library.tracks.length + " TRACKS")
      font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2; color: Theme.textMute
    }
    Text { anchors.right: parent.right; text: Clock.hm + "  " + System.battery + "%"; font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2; color: Theme.textMute }
  }

  // Walnut plinth with the spinning disc
  Walnut {
    id: plinth
    x: 36; y: 84; width: 300; height: 300; radius: 14; seed: 31
  }
  Item {
    id: spinner
    anchors.centerIn: plinth
    width: music.disc === "cd" ? 250 : 236; height: width
    RotationAnimator on rotation {
      from: 0; to: 360
      duration: music.disc === "cd" ? 2400 : 12000
      loops: Animation.Infinite
      running: Player.playing
    }
    // Vinyl
    Item {
      anchors.fill: parent
      visible: music.disc !== "cd"
      Rectangle { anchors.fill: parent; radius: width / 2; color: "#0c0c0d" }
      Repeater {
        model: 26
        Rectangle {
          required property int index
          anchors.centerIn: parent
          width: 236 - 10 - index * 5.6; height: width; radius: width / 2
          color: "transparent"; border.width: 1
          border.color: index % 3 === 0 ? "#1d1d20" : "#141416"
        }
      }
      // light sheen across the grooves
      Rectangle {
        anchors.centerIn: parent; width: 236; height: 236; radius: 118
        rotation: 35
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
          GradientStop { position: 0.48; color: Qt.rgba(1, 1, 1, 0.07) }
          GradientStop { position: 0.52; color: Qt.rgba(1, 1, 1, 0.0) }
        }
      }
      CircleImage {
        anchors.centerIn: parent; width: 96; height: 96
        source: Player.cover
        visible: Player.cover !== ""
      }
      AluRing {
        anchors.centerIn: parent; width: 84; height: 84
        visible: Player.cover === ""
      }
      Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "#0a0a0b" }
    }
    // CD
    Item {
      anchors.fill: parent
      visible: music.disc === "cd"
      Canvas {
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d"); ctx.reset()
          var r = width / 2
          var g = ctx.createConicalGradient(r, r, 0)
          var st = ["#d9dce0", "#f6f7f8", "#c9d6e6", "#e8dcf0", "#f4e9d6", "#d9dce0", "#bfc3c8", "#eef0f2", "#cfe1dc", "#ead7ea", "#f6efd9", "#d9dce0", "#b8bcc2", "#d9dce0"]
          for (var i = 0; i < st.length; ++i) g.addColorStop(i / (st.length - 1), st[i])
          ctx.beginPath(); ctx.arc(r, r, r, 0, Math.PI * 2); ctx.fillStyle = g; ctx.fill()
          ctx.lineWidth = 1
          for (var k = 50; k < r; k += 4) {
            ctx.strokeStyle = "rgba(255,255,255,0.08)"
            ctx.beginPath(); ctx.arc(r, r, k, 0, Math.PI * 2); ctx.stroke()
          }
          ctx.strokeStyle = "rgba(255,255,255,0.5)"
          ctx.beginPath(); ctx.arc(r, r, r - 0.5, 0, Math.PI * 2); ctx.stroke()
          // clear hub
          ctx.beginPath(); ctx.arc(r, r, 47, 0, Math.PI * 2)
          ctx.fillStyle = "rgba(230,235,240,0.35)"; ctx.fill()
          ctx.strokeStyle = "rgba(255,255,255,0.6)"; ctx.stroke()
          // reflection streak
          var s = ctx.createLinearGradient(14, r, 74, r)
          s.addColorStop(0, "rgba(255,255,255,0)"); s.addColorStop(0.5, "rgba(255,255,255,0.55)"); s.addColorStop(1, "rgba(255,255,255,0)")
          ctx.fillStyle = s; ctx.fillRect(14, r - 4, 60, 8)
        }
      }
      CircleImage {
        anchors.centerIn: parent; width: 94; height: 94; hole: 18
        source: Player.cover
        visible: Player.cover !== ""
        opacity: 0.9
      }
      Rectangle {
        anchors.centerIn: parent; width: 36; height: 36; radius: 18
        color: Theme.walnutDark; border.color: Qt.rgba(1, 1, 1, 0.5); border.width: 1
      }
    }
  }
  Text {
    x: plinth.x + 12; y: plinth.y + plinth.height - 22
    visible: Player.hasTrack && Player.cover === ""
    text: "NO COVER ART"
    font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1.5; color: "#e9d8c6"
  }

  // Title block
  Column {
    x: 368; width: 316
    anchors.verticalCenter: plinth.verticalCenter
    spacing: 14
    Text {
      width: parent.width
      text: Player.hasTrack ? Player.title : (Library.tracks.length ? "Press A to play" : "No music yet")
      wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
      font.family: Theme.sans; font.pixelSize: 44; font.weight: Font.Bold; font.letterSpacing: -1
      lineHeight: 0.95
      color: Theme.text
    }
    Column {
      width: parent.width; spacing: 4
      Text { width: parent.width; elide: Text.ElideRight; text: Player.artist; font.family: Theme.sans; font.pixelSize: 20; color: "#d3d6da"; visible: text !== "" }
      Text {
        width: parent.width; elide: Text.ElideRight
        text: Player.hasTrack ? Player.album : (Library.tracks.length ? "" : "Copy music to /storage/music")
        font.family: Theme.sans; font.pixelSize: 16; color: Theme.textMute; visible: text !== ""
      }
    }
    Row {
      spacing: 8
      Rectangle {
        visible: Player.format !== ""
        height: 28; width: fmtText.width + 20; radius: 6; color: "#e1e3e6"
        Text { id: fmtText; anchors.centerIn: parent; text: Player.format; font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 1; color: "#111214" }
      }
      Rectangle {
        height: 28; width: outText.width + 20; radius: 6; color: "transparent"; border.color: "#6b4a33"; border.width: 1
        Text { id: outText; anchors.centerIn: parent; text: System.audioOutput.toUpperCase(); font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 1; color: Theme.creamDim }
      }
    }
  }

  // Progress
  Item {
    x: 36; y: 418; width: 648; height: 40
    Rectangle {
      width: parent.width; height: 6; radius: 3; color: "#1d1e21"
      Rectangle {
        height: 6; radius: 3
        width: Player.duration > 0 ? parent.width * Player.position / Player.duration : 0
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: Theme.copperDark }
          GradientStop { position: 1.0; color: Theme.copper }
        }
      }
    }
    Text { y: 16; text: music.fmt(Player.position); font.family: Theme.mono; font.pixelSize: 13; color: "#9aa0a7" }
    Text { y: 16; anchors.right: parent.right; text: music.fmt(Player.duration); font.family: Theme.mono; font.pixelSize: 13; color: "#9aa0a7" }
  }

  // Transport
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 490
    spacing: 40
    component RoundBtn: Rectangle {
      property string glyph
      width: 64; height: 64; radius: 32
      color: "transparent"; border.color: Theme.line; border.width: 1
      anchors.verticalCenter: parent ? parent.verticalCenter : undefined
      Text { anchors.centerIn: parent; text: glyph; font.pixelSize: 22; color: "#d3d6da"; font.family: Theme.mono }
    }
    RoundBtn { glyph: "|‹"; function tapAction(x, y) { Player.prev() } }
    Rectangle {
      width: 96; height: 96; radius: 48
      function tapAction(x, y) { Player.toggle() }
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#eef0f2" }
        GradientStop { position: 0.55; color: "#aeb2b8" }
        GradientStop { position: 1.0; color: "#d6d9dd" }
      }
      // play / pause glyphs
      Row {
        anchors.centerIn: parent; spacing: 8
        visible: Player.playing
        Rectangle { width: 9; height: 30; radius: 2; color: "#121214" }
        Rectangle { width: 9; height: 30; radius: 2; color: "#121214" }
      }
      Canvas {
        anchors.centerIn: parent; anchors.horizontalCenterOffset: 3
        width: 30; height: 32
        visible: !Player.playing
        onPaint: { var c = getContext("2d"); c.reset(); c.fillStyle = "#121214"; c.beginPath(); c.moveTo(2, 1); c.lineTo(28, 16); c.lineTo(2, 31); c.closePath(); c.fill() }
      }
    }
    RoundBtn { glyph: "›|"; function tapAction(x, y) { Player.next() } }
  }

  Hints {
    anchors.bottom: parent.bottom
    model: ["A PLAY", "←→ TRACK", "X LIBRARY", "Y " + (music.disc === "cd" ? "VINYL" : "CD"), "B HOME"]
  }

  // Library list
  Rectangle {
    id: list
    anchors.fill: parent
    color: "#0b0b0d"
    opacity: music.listOpen ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    Text {
      x: 36; y: 30
      text: "LIBRARY · " + Library.tracks.length + " TRACKS"
      font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2; color: Theme.textMute
    }
    ListView {
      id: lv
      x: 24; y: 64; width: 672; height: 720 - 64 - 64
      clip: true
      model: Library.tracks
      currentIndex: Math.max(0, Player.index)
      highlightMoveDuration: 120
      preferredHighlightBegin: height / 2 - 30; preferredHighlightEnd: height / 2 + 30
      highlightRangeMode: ListView.ApplyRange
      section.property: "album"
      section.delegate: Text {
        required property string section
        width: lv.width; height: 44; leftPadding: 12; verticalAlignment: Text.AlignBottom; bottomPadding: 6
        text: section.toUpperCase()
        font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 2; color: Theme.copper
      }
      highlight: Rectangle { radius: 10; color: "#1a1b1e"; border.color: Theme.line }
      delegate: Item {
        required property var modelData
        required property int index
        width: lv.width; height: 52
        function tapAction(x, y) { lv.currentIndex = index; music.handle("a") }
        Text {
          x: 12; width: parent.width - 120; anchors.verticalCenter: parent.verticalCenter
          text: modelData.title; elide: Text.ElideRight
          font.family: Theme.sans; font.pixelSize: 20
          font.weight: Player.current && Player.current.path === modelData.path ? Font.Bold : Font.Normal
          color: lv.currentIndex === index ? Theme.text : Theme.textDim
        }
        Text {
          anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
          text: modelData.artist; width: 100; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
          font.family: Theme.mono; font.pixelSize: 11; color: Theme.textMute
        }
      }
    }
    Hints { anchors.bottom: parent.bottom; model: ["↑↓ MOVE", "L1 R1 PAGE", "A PLAY", "B CLOSE"] }
  }

  function handle(b) {
    if (listOpen) {
      if (b === "up") { lv.decrementCurrentIndex(); return true }
      if (b === "down") { lv.incrementCurrentIndex(); return true }
      if (b === "l1" || b === "left") { lv.currentIndex = Math.max(0, lv.currentIndex - 8); return true }
      if (b === "r1" || b === "right") { lv.currentIndex = Math.min(lv.count - 1, lv.currentIndex + 8); return true }
      if (b === "a") { Player.playQueue(Library.tracks, lv.currentIndex); listOpen = false; return true }
      if (b === "b" || b === "x") { listOpen = false; return true }
      return false
    }
    if (b === "a" || b === "start") { Player.toggle(); return true }
    if (b === "left") { Player.prev(); return true }
    if (b === "right") { Player.next(); return true }
    if (b === "l1") { Player.seek(-10000); return true }
    if (b === "r1") { Player.seek(10000); return true }
    if (b === "x" || b === "down") { listOpen = true; return true }
    if (b === "y") { System.setSetting("disc", disc === "cd" ? "vinyl" : "cd"); return true }
    if (b === "b") { Nav.go("home"); return true }
    return false
  }
}
