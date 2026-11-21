// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// The cartridge shelf: one shelf per system, oldest first, with recently
// played games up front. A inserts the cart into the walnut slot and starts it.
Item {
  id: games
  readonly property int dragStep: 120
  width: 720; height: 720

  readonly property var shelves: {
    var s = []
    if (Library.recents.length) s.push({ name: "recent", label: "RECENT", fullname: "Recently played", kind: "mixed" })
    for (var i = 0; i < Library.systems.length; ++i) {
      var y = Library.systems[i]
      s.push({ name: y.name, label: shortName(y), fullname: y.fullname, kind: y.kind, year: y.year, maker: y.manufacturer, slot: y.slot })
    }
    return s
  }
  // Shelves are tracked by name so adding the Recent shelf doesn't move you.
  property string shelfName: ""
  readonly property int shelf: Math.max(0, shelves.findIndex(s => s.name === shelfName))
  readonly property var cur: shelves.length ? shelves[shelf] : null
  property var lastIndex: ({})
  function moveShelf(d) {
    if (!shelves.length) return
    shelfName = shelves[(shelf + d + shelves.length) % shelves.length].name
  }
  readonly property var list: cur ? (cur.name === "recent" ? Library.recents : Library.games(cur.name)) : []
  property bool inserting: false
  property bool starting: false
  property string message: ""

  function shortName(y) {
    var m = { "mastersystem": "SMS", "megadrive": "MD", "genesis": "GENESIS", "gamegear": "GG", "segacd": "SEGA CD",
              "sega32x": "32X", "saturn": "SATURN", "dreamcast": "DC", "psx": "PS1", "pcengine": "PCE", "tg16": "TG-16",
              "pcenginecd": "PCE-CD", "atari2600": "2600", "atari5200": "5200", "atari7800": "7800", "atarilynx": "LYNX",
              "wonderswan": "WS", "wonderswancolor": "WSC", "neogeo": "NEO GEO", "neogeocd": "NGCD", "ngp": "NGP", "ngpc": "NGPC",
              "virtualboy": "VB", "colecovision": "COLECO", "intellivision": "INTV", "famicom": "FC", "sg-1000": "SG-1000" }
    return m[y.name] || y.name.toUpperCase()
  }
  function kindOf(g) {
    if (!cur || cur.name !== "recent") return cur ? cur.kind : "cart"
    var s = Library.system(g.system)
    return s.kind || "cart"
  }
  function art(g) { return g.thumbnail || g.image || "" }

  // Jump straight to a recently played game
  function showRecent() { shelfName = "recent"; lv.currentIndex = 0 }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#121215" }
      GradientStop { position: 0.45; color: "#1a1a1e" }
      GradientStop { position: 1.0; color: "#060607" }
    }
  }

  // Shelf tabs
  Item {
    x: 0; y: 0; width: 720; height: 72
    Text { x: 28; anchors.verticalCenter: parent.verticalCenter; text: "L1"; font.family: Theme.mono; font.pixelSize: 13; color: Theme.textMute }
    Text { anchors.right: parent.right; anchors.rightMargin: 28; anchors.verticalCenter: parent.verticalCenter; text: "R1"; font.family: Theme.mono; font.pixelSize: 13; color: Theme.textMute }
    ListView {
      id: tabs
      x: 60; width: 600; height: 36
      anchors.verticalCenter: parent.verticalCenter
      orientation: ListView.Horizontal
      spacing: 8
      clip: true
      model: games.shelves
      currentIndex: games.shelf
      highlightRangeMode: ListView.ApplyRange
      preferredHighlightBegin: 200; preferredHighlightEnd: 400
      highlightMoveDuration: 200
      interactive: false
      delegate: Rectangle {
        required property var modelData
        required property int index
        readonly property bool on: index === games.shelf
        height: 36; width: tabText.width + 28; radius: 18
        function tapAction(x, y) { games.moveShelf(index - games.shelf) }
        color: on ? "#e9ebee" : "transparent"
        border.color: on ? "transparent" : Theme.line; border.width: 1
        Text {
          id: tabText
          anchors.centerIn: parent
          text: modelData.label
          font.family: Theme.mono; font.pixelSize: 14; font.weight: Font.Medium; font.letterSpacing: 1
          color: parent.on ? "#111214" : "#9aa0a7"
        }
      }
    }
  }

  Text {
    y: 84; width: parent.width; horizontalAlignment: Text.AlignHCenter
    text: games.cur ? ((games.cur.maker ? games.cur.maker + " · " : "") + games.cur.fullname + (games.cur.year ? " · " + games.cur.year : "")).toUpperCase() : ""
    font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2; color: "#6e737a"
  }

  // Shelf edge
  Rectangle {
    y: 452; width: 720; height: 2
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 0.2; color: "#3a3c41" }
      GradientStop { position: 0.8; color: "#3a3c41" }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }

  // Walnut console slot the cart drops into
  Rectangle { x: 160; y: 616; width: 400; height: 22; radius: 11; color: "#030304"; border.color: Qt.rgba(1, 1, 1, 0.06) }
  Rectangle {
    x: 170; y: 620; width: 380; height: 10; radius: 5
    color: Theme.copper; opacity: games.inserting ? 0.5 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }
  }

  ListView {
    id: lv
    x: 0; y: 100; width: 720; height: 520
    orientation: ListView.Horizontal
    model: games.list
    interactive: false
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 360 - 130; preferredHighlightEnd: 360 + 130
    highlightMoveDuration: 320
    cacheBuffer: 520
    clip: false
    z: 1
    onModelChanged: currentIndex = Math.min(games.lastIndex[games.shelfName] || 0, Math.max(0, count - 1))
    onCurrentIndexChanged: if (games.cur) games.lastIndex[games.cur.name] = currentIndex
    delegate: Item {
      id: slotItem
      required property var modelData
      required property int index
      width: 260; height: lv.height
      function tapAction(x, y) {
        if (lv.currentIndex === index) games.handle("a")
        else lv.currentIndex = index
      }
      readonly property real dist: (x + width / 2 - lv.contentX - lv.width / 2) / 260
      readonly property real ad: Math.min(Math.abs(dist), 1.5)
      readonly property bool center: index === lv.currentIndex
      readonly property string kind: games.kindOf(modelData)
      z: center ? 2 : 1
      opacity: ad > 1.4 ? 0 : 1 - Math.min(ad, 1) * 0.55
      Item {
        id: holder
        width: loader.item ? loader.item.width : 0
        height: loader.item ? loader.item.height : 0
        x: (260 - width) / 2
        y: 346 - height + (slotItem.center && games.inserting ? 230 : 0)
        scale: 1.22 - Math.min(slotItem.ad, 1) * 0.42
        transformOrigin: Item.Bottom
        Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.InOutCubic } }
        // shadow
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 6
          width: parent.width * 0.9; height: 14; radius: 7; color: "#000"; opacity: slotItem.center ? 0.5 : 0.25
        }
        Loader {
          id: loader
          sourceComponent: slotItem.kind === "disc" ? discC : cartC
        }
        Component {
          id: cartC
          Cart { kind: slotItem.kind === "umd" ? "umd" : slotItem.kind; title: slotItem.modelData.name; art: games.art(slotItem.modelData) }
        }
        Component {
          id: discC
          Disc { title: slotItem.modelData.name; art: games.art(slotItem.modelData); system: slotItem.modelData.system }
        }
      }
    }
  }

  // Title and status
  Column {
    y: 474; width: parent.width; spacing: 6
    z: 2
    Text {
      width: parent.width - 80; anchors.horizontalCenter: parent.horizontalCenter
      horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
      text: lv.currentItem ? lv.currentItem.modelData.name : (games.shelves.length ? "" : "No games found")
      font.family: Theme.sans; font.pixelSize: 30; font.weight: Font.Bold; font.letterSpacing: -0.5
      color: Theme.text
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: games.message !== "" ? games.message
            : games.shelves.length === 0 ? "ADD ROMS TO /storage/roms/<system>"
            : (games.starting ? "STARTING…"
               : (games.cur.label + " · " + (lv.currentIndex + 1) + " OF " + lv.count
                  + (lv.currentItem && Library.isFavorite(lv.currentItem.modelData.path) ? " · FAVORITE" : "")))
      font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 1.5; color: "#9aa0a7"
    }
  }

  Walnut { x: 130; y: 638; width: 460; height: 30; bottomLeftRadius: 14; bottomRightRadius: 14; topLeftRadius: 0; topRightRadius: 0; seed: 3; z: 3 }

  Hints {
    y: 676; height: 44; z: 3
    model: ["←→ BROWSE", "*A INSERT", "Y FAVORITE", "B HOME", (games.cur && games.cur.slot ? ">SELECT SLOT." : ">")]
  }

  Timer { id: msgTimer; interval: 2500; onTriggered: games.message = "" }
  function flash(m) { message = m; msgTimer.restart() }

  Timer {
    id: startTimer
    interval: 480
    onTriggered: {
      var g = lv.currentItem.modelData
      var spec = Library.launchSpec(g.system, g.path, Gamepad.guid, System.flag("gbViaSlot", true))
      games.starting = true
      Library.addRecent(g.system, g.path)
      if (!System.launch(spec.program, spec.args, spec.env)) {
        games.starting = false; games.inserting = false
        flash("COULD NOT START")
      }
    }
  }
  Connections {
    target: System
    function onLaunchFinished(code) {
      games.starting = false
      games.inserting = false
      if (code !== 0 && code !== -1) games.flash("EXITED WITH CODE " + code)
      if (code === -1) games.flash("COULD NOT START")
    }
  }

  function handle(b) {
    if (inserting) return true
    if (b === "left") { lv.decrementCurrentIndex(); return true }
    if (b === "right") { lv.incrementCurrentIndex(); return true }
    if (b === "l1" || b === "up") { moveShelf(-1); return true }
    if (b === "r1" || b === "down") { moveShelf(1); return true }
    if (b === "l2") { lv.currentIndex = Math.max(0, lv.currentIndex - 10); return true }
    if (b === "r2") { lv.currentIndex = Math.min(lv.count - 1, lv.currentIndex + 10); return true }
    if (b === "a") {
      if (!lv.currentItem) return true
      inserting = true
      startTimer.start()
      return true
    }
    if (b === "y" && lv.currentItem) {
      var g = lv.currentItem.modelData
      Library.toggleFavorite(g.system, g.path)
      flash(Library.isFavorite(g.path) ? "ADDED TO FAVORITES" : "REMOVED FROM FAVORITES")
      return true
    }
    if (b === "select" && cur && cur.slot) {
      System.launch("/usr/bin/start_slot.sh", [], { "SLOT_SHELF": cur.name, "SLOT_BACK_EXITS": "1" })
      return true
    }
    if (b === "b") { Nav.go("home"); return true }
    return false
  }
}
