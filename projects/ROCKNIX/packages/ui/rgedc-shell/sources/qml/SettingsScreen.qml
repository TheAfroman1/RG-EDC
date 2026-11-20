// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

Item {
  id: settings
  width: 720; height: 720
  property int sel: 0
  property string confirm: ""
  property bool showAbout: false      // row key waiting for a second A press
  property string pairKind: ""        // pairing guide showing: "ios" or "android"
  property bool pairDone: false
  property string pairFrom: ""        // phone already connected when the guide opened

  function opt(key, def) { return System.settingsRevision >= 0 ? System.setting(key, def) : def }
  function on(key, def) { return System.settingsRevision >= 0 && System.flag(key, def) }

  readonly property var rows: [
    { key: "watchFace", label: "Watch face", kind: "choice", values: ["analog", "digital", "nixie"], names: ["Analog", "Digital", "Nixie"], value: opt("watchFace", "analog") },
    { key: "nixieSeconds", label: "Nixie shows seconds", kind: "toggle", value: on("nixieSeconds", true) },
    { key: "disc", label: "Music spins a", kind: "choice", values: ["vinyl", "cd"], names: ["Vinyl record", "CD"], value: opt("disc", "vinyl") },
    { key: "lidVisualizer", label: "Flip shut while playing", kind: "choice", values: ["true", "false"], names: ["Visualizer", "Sleep"], value: String(on("lidVisualizer", true)) },
    { key: "phone", label: "Phone", kind: "info",
      value: !Phone.available ? "Bluetooth off" : Phone.connected ? Phone.name : Phone.known.length ? "Not connected" : "None paired" },
    { key: "pairIos", label: "Pair an iPhone", kind: "action" },
    { key: "pairAndroid", label: "Pair an Android phone", kind: "action" },
    { key: "notifBanners", label: "Notification banners", kind: "toggle", value: on("notifBanners", true) },
    { key: "forgetPhone", label: "Forget paired phones", kind: "action", danger: true },
    { key: "volume", label: "Volume", kind: "level", value: System.volume },
    { key: "brightness", label: "Brightness", kind: "level", value: System.brightness },
    { key: "nintendo", label: "Confirm button", kind: "choice", values: ["true", "false"], names: ["A (right)", "A (bottom)"], value: String(on("nintendo", true)) },
    { key: "gbViaSlot", label: "Game Boy games open in", kind: "choice", values: ["true", "false"], names: ["slot.", "RetroArch"], value: String(on("gbViaSlot", true)) },
    { key: "idleWatch", label: "Watch after idle", kind: "choice", values: ["0", "30", "60", "120", "300"], names: ["Never", "30 s", "1 min", "2 min", "5 min"], value: String(opt("idleWatch", "60")) },
    { key: "rescan", label: "Rescan games and music", kind: "action" },
    { key: "es", label: "Open EmulationStation", kind: "action" },
    { key: "bootEs", label: "Start in EmulationStation", kind: "action", danger: true },
    { key: "reboot", label: "Restart", kind: "action", danger: true },
    { key: "poweroff", label: "Power off", kind: "action", danger: true },
    { key: "about", label: "About", kind: "info", value: "RG EDC " + (System.version || "dev") },
  ]

  Rectangle { anchors.fill: parent; color: Theme.bg }
  StatusBar { label: "SETTINGS"; showOutput: true }

  ListView {
    id: lv
    x: 36; y: 72; width: 648; height: 720 - 72 - 64
    clip: true
    model: settings.rows
    currentIndex: settings.sel
    highlightMoveDuration: 140
    preferredHighlightBegin: 160; preferredHighlightEnd: height - 160
    highlightRangeMode: ListView.ApplyRange
    highlight: Rectangle {
      radius: 12; color: "#16171a"; border.color: Theme.line
      Walnut { x: 0; width: 6; height: parent.height; topLeftRadius: 12; bottomLeftRadius: 12; topRightRadius: 0; bottomRightRadius: 0 }
    }
    delegate: Item {
      required property var modelData
      required property int index
      readonly property bool on: index === settings.sel
      width: lv.width; height: 60
      Text {
        x: 24; anchors.verticalCenter: parent.verticalCenter
        text: settings.confirm === modelData.key ? "Press A again to confirm" : modelData.label
        font.family: Theme.sans; font.pixelSize: 22
        font.weight: parent.on ? Font.DemiBold : Font.Normal
        color: settings.confirm === modelData.key ? Theme.copper : parent.on ? Theme.text : Theme.textDim
      }
      // value
      Row {
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Text {
          visible: modelData.kind === "choice" || modelData.kind === "info"
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.kind === "choice" ? (parent.parent.on ? "‹ " : "") + modelData.names[Math.max(0, modelData.values.indexOf(String(modelData.value)))] + (parent.parent.on ? " ›" : "")
                                            : (modelData.value !== undefined ? String(modelData.value) : "")
          font.family: Theme.mono; font.pixelSize: 15; color: Theme.creamDim
        }
        Text {
          visible: modelData.kind === "toggle"
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.value ? "ON" : "OFF"
          font.family: Theme.mono; font.pixelSize: 15; color: modelData.value ? Theme.creamDim : Theme.textMute
        }
        Rectangle {
          visible: modelData.kind === "level"
          anchors.verticalCenter: parent.verticalCenter
          width: 200; height: 6; radius: 3; color: "#1d1e21"
          Rectangle {
            width: parent.width * (modelData.value || 0) / 100; height: 6; radius: 3
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0.0; color: Theme.copperDark }
              GradientStop { position: 1.0; color: Theme.copper }
            }
          }
        }
        Text {
          visible: modelData.kind === "level"
          anchors.verticalCenter: parent.verticalCenter
          width: 40; horizontalAlignment: Text.AlignRight
          text: modelData.value !== undefined ? String(modelData.value) : ""
          font.family: Theme.mono; font.pixelSize: 15; color: Theme.creamDim
        }
      }
    }
  }

  Hints { anchors.bottom: parent.bottom; model: ["↑↓ MOVE", "←→ CHANGE", "A SELECT", "B HOME"] }

  // About: the badge and credits
  Rectangle {
    id: about
    anchors.fill: parent
    color: "#050506"
    visible: settings.showAbout
    Image { x: 160; y: 40; width: 400; height: 400; source: "images/logo.png"; smooth: true; mipmap: true }
    Column {
      x: 60; y: 462; width: 600; spacing: 8
      Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "RG EDC " + (System.version || "dev"); font.family: Theme.sans; font.pixelSize: 26; font.weight: Font.Bold; color: Theme.text }
      Text {
        width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        text: "Built on ROCKNIX. Game Boy shelves by slot. (GPL-3.0) with cartridge art by Markus.\nArchivo and IBM Plex Mono under the SIL Open Font License."
        font.family: Theme.sans; font.pixelSize: 15; lineHeight: 1.3; color: Theme.textDim
      }
    }
    Hints { anchors.bottom: parent.bottom; model: ["B BACK"] }
  }

  // Pairing guide
  Rectangle {
    anchors.fill: parent
    color: "#050506"
    visible: settings.pairKind !== ""
    Column {
      x: 60; y: 110; width: 600; spacing: 22
      Text {
        text: settings.pairKind === "ios" ? "PAIR AN IPHONE" : "PAIR AN ANDROID PHONE"
        font.family: Theme.mono; font.pixelSize: 14; font.letterSpacing: 4; color: Theme.copper
      }
      Text {
        width: parent.width; wrapMode: Text.WordWrap
        text: settings.pairDone ? "Paired with " + Phone.name
            : !Phone.available ? "Turn Bluetooth on first"
            : settings.pairKind === "ios" ? "Look for “RG EDC” on your iPhone" : "Look for “Espruino RG EDC” in Gadgetbridge"
        font.family: Theme.sans; font.pixelSize: 36; font.weight: Font.Bold; lineHeight: 1.1; color: Theme.text
      }
      Repeater {
        model: settings.pairDone ? ["Its notifications now show up on the watch and under Phone."]
             : settings.pairKind === "ios"
             ? ["1   On the iPhone, open Settings › Bluetooth.",
                "2   Tap RG EDC under Other Devices.",
                "3   Tap Pair, then allow RG EDC to show notifications.",
                "RG EDC also takes the time from the iPhone."]
             : ["1   Install Gadgetbridge from F-Droid.",
                "2   Tap + and pick Espruino RG EDC (it pairs as a Bangle.js).",
                "3   Give Gadgetbridge notification access when it asks.",
                "Calls, music and the time come through Gadgetbridge too."]
        Text {
          required property string modelData
          required property int index
          width: 600; wrapMode: Text.WordWrap
          text: modelData
          font.family: Theme.sans; font.pixelSize: 20; lineHeight: 1.3
          color: index === 3 || settings.pairDone ? Theme.textMute : Theme.textDim
        }
      }
    }
    Row {
      x: 60; y: 600; spacing: 12
      visible: !settings.pairDone && Phone.available
      Repeater {
        model: 3
        Rectangle {
          required property int index
          width: 10; height: 10; radius: 5; color: Theme.copper
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            running: settings.pairKind !== "" && !settings.pairDone; loops: Animation.Infinite
            PauseAnimation { duration: index * 250 }
            NumberAnimation { from: 1; to: 0.2; duration: 600 }
            NumberAnimation { from: 0.2; to: 1; duration: 600 }
            PauseAnimation { duration: (2 - index) * 250 }
          }
        }
      }
      Text { text: "Waiting for the phone"; font.family: Theme.mono; font.pixelSize: 14; color: Theme.textMute }
    }
    Hints { anchors.bottom: parent.bottom; model: [settings.pairDone ? "B DONE" : "B STOP"] }
  }
  Connections {
    target: Phone
    function onStateChanged() {
      if (settings.pairKind !== "" && Phone.connected && Phone.kind === settings.pairKind && Phone.name !== settings.pairFrom)
        settings.pairDone = true
    }
  }
  Timer { interval: 3500; running: settings.pairDone; onTriggered: { settings.pairKind = ""; settings.pairDone = false } }

  function change(r, d) {
    if (r.kind === "choice") {
      var i = r.values.indexOf(String(r.value))
      i = (i + d + r.values.length) % r.values.length
      System.setSetting(r.key, r.values[i])
      if (r.key === "nintendo") Gamepad.nintendoLayout = r.values[i] === "true"
    } else if (r.kind === "toggle") {
      System.setSetting(r.key, !r.value)
    } else if (r.kind === "level") {
      if (r.key === "volume") System.volume = System.volume + d * 5
      else System.brightness = System.brightness + d * 5
    }
  }

  function act(r) {
    if (r.key === "about") { showAbout = true; return }
    if (r.key === "pairIos" || r.key === "pairAndroid") {
      pairKind = r.key === "pairIos" ? "ios" : "android"
      pairDone = false
      pairFrom = Phone.connected ? Phone.name : ""
      Phone.startPairing(pairKind)
      return
    }
    if (r.kind !== "action") { change(r, 1); return }
    if (r.danger && confirm !== r.key) { confirm = r.key; return }
    confirm = ""
    if (r.key === "rescan") Library.rescan()
    else if (r.key === "forgetPhone") Phone.forget()
    else if (r.key === "es") System.openEmulationStation()
    else if (r.key === "bootEs") { System.setBootToEmulationStation(true); Qt.quit() }
    else if (r.key === "reboot") System.reboot()
    else if (r.key === "poweroff") System.powerOff()
  }

  function handle(b) {
    if (showAbout) { if (b === "b" || b === "a") showAbout = false; return true }
    if (pairKind !== "") {
      if (b === "b" || (b === "a" && pairDone)) {
        if (!pairDone) Phone.stopPairing()
        pairKind = ""
        pairDone = false
      }
      return true
    }
    var r = rows[sel]
    if (b !== "a") confirm = ""
    if (b === "up") { sel = Math.max(0, sel - 1); return true }
    if (b === "down") { sel = Math.min(rows.length - 1, sel + 1); return true }
    if (b === "left") { change(r, -1); return true }
    if (b === "right") { change(r, 1); return true }
    if (b === "a") { act(r); return true }
    if (b === "b") { Nav.go("home"); return true }
    return false
  }
}
