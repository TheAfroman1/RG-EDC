// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Reply to an Android notification through Gadgetbridge: pick a quick reply or
// write one on the keyboard. Works with the buttons and by touch.
Rectangle {
  id: rs
  width: 720; height: 720
  color: "#050506"
  visible: open
  property bool open: false
  property var item: ({})
  property string mode: "pick"        // "pick" or "type"
  property int sel: 0
  property string text: ""
  property bool shift: true
  property bool emojiPage: false
  property int kr: 0                  // keyboard row and column
  property int kc: 0
  signal done()

  readonly property var defaults: ["OK 👍", "On my way", "Can't talk now, I'll call you later", "Sounds good!", "Yes", "No", "❤️"]
  readonly property var choices: ["Write a reply…"].concat(Phone.canned.length ? Phone.canned : defaults)

  readonly property var letterRows: [
    "1234567890".split(""), "qwertyuiop".split(""), "asdfghjkl'".split(""), "zxcvbnm,.?".split("")]
  readonly property var emojiRows: [
    ["😀", "😂", "😊", "😍", "😘", "😎", "🤔", "😅", "😢", "😡"],
    ["👍", "👎", "👌", "🙏", "👏", "🙌", "💪", "🤞", "👋", "✌️"],
    ["❤️", "🔥", "🎉", "✨", "💯", "✅", "❌", "⭐", "☕", "🍕"],
    ["🚗", "🏠", "⏰", "📍", "🎮", "🎵", "🌮", "🍺", "😴", "🙈"]]
  readonly property var bottomRow: ["shift", "emoji", "space", "del", "send"]
  readonly property var rows: (emojiPage ? emojiRows : letterRows).concat([bottomRow])

  function show(it) {
    item = it; mode = "pick"; sel = 0; text = ""; shift = true; emojiPage = false; kr = 1; kc = 0
    open = true
  }
  function close() { open = false; done() }
  function send(t) {
    if (!t.trim().length) return
    Phone.reply(item.id, t.trim())
    close()
  }
  function press(k) {
    if (k === "shift") shift = !shift
    else if (k === "emoji") { emojiPage = !emojiPage; kc = Math.min(kc, rows[kr].length - 1) }
    else if (k === "space") text += " "
    else if (k === "del") text = text.slice(0, -1)
    else if (k === "send") send(text)
    else {
      text += shift ? k.toUpperCase() : k
      if (shift && !emojiPage) shift = false
    }
  }
  function label(k) {
    return ({ shift: "⇧", emoji: rs.emojiPage ? "ABC" : "😀", space: "space", del: "⌫", send: "Send" })[k]
        || (rs.shift ? k.toUpperCase() : k)
  }

  // Header: who we're answering
  Column {
    x: 40; y: 34; width: 640; spacing: 6
    Text {
      text: "REPLY · " + (rs.item.app || "").toUpperCase()
      font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 3; color: Theme.copper
    }
    Text {
      width: parent.width; elide: Text.ElideRight
      text: rs.item.title || ""
      font.family: Theme.sans; font.pixelSize: 26; font.weight: Font.DemiBold; color: Theme.text
    }
    Text {
      width: parent.width; elide: Text.ElideRight; maximumLineCount: 1
      text: rs.item.body || ""
      font.family: Theme.sans; font.pixelSize: 17; color: Theme.textMute
    }
  }

  // Quick replies
  ListView {
    id: pick
    visible: rs.mode === "pick"
    x: 40; y: 150; width: 640; height: 720 - 150 - 64
    clip: true; spacing: 8
    model: rs.choices
    currentIndex: rs.sel
    highlightMoveDuration: 120
    delegate: Rectangle {
      required property string modelData
      required property int index
      readonly property bool on: index === rs.sel
      width: pick.width; height: 58; radius: 14
      color: on ? "#17181b" : "#0f1012"
      border.color: on ? "#3a3c41" : Theme.panelLine
      Walnut { visible: parent.on; width: 6; height: parent.height; topLeftRadius: 14; bottomLeftRadius: 14; topRightRadius: 0; bottomRightRadius: 0 }
      Text {
        x: 24; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 48
        elide: Text.ElideRight
        text: modelData
        font.family: Theme.sans; font.pixelSize: 21
        font.italic: index === 0
        color: index === 0 ? Theme.creamDim : Theme.text
      }
      MouseArea {
        anchors.fill: parent
        onClicked: { rs.sel = index; rs.choose() }
      }
    }
  }

  // Typing
  Item {
    visible: rs.mode === "type"
    anchors.fill: parent
    Rectangle {
      x: 40; y: 150; width: 640; height: 140; radius: 16
      color: "#0f1012"; border.color: Theme.panelLine
      Text {
        id: typed
        x: 20; y: 16; width: parent.width - 40; height: parent.height - 32
        wrapMode: Text.Wrap; elide: Text.ElideLeft
        verticalAlignment: Text.AlignBottom
        text: rs.text.length ? rs.text : "Write a reply"
        font.family: Theme.sans; font.pixelSize: 24
        color: rs.text.length ? Theme.text : Theme.textOff
      }
      Rectangle {
        visible: rs.text.length > 0
        width: 2; height: 28; color: Theme.copper
        anchors.right: parent.right; anchors.rightMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
        SequentialAnimation on opacity { running: rs.open && rs.mode === "type"; loops: Animation.Infinite
          NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
      }
    }
    Column {
      x: 40; y: 310; width: 640; spacing: 8
      Repeater {
        model: rs.rows
        delegate: Row {
          id: krow
          required property var modelData
          required property int index
          readonly property int r: index
          spacing: 8
          anchors.horizontalCenter: parent.horizontalCenter
          Repeater {
            model: krow.modelData
            delegate: Rectangle {
              required property string modelData
              required property int index
              readonly property bool on: rs.kr === krow.r && rs.kc === index
              readonly property bool wide: modelData === "space"
              readonly property bool special: ["shift", "emoji", "del", "send"].indexOf(modelData) >= 0
              width: wide ? 250 : special ? 88 : 56; height: 56; radius: 10
              color: on ? "#2a2b30" : (modelData === "send" ? "transparent" : "#141518")
              border.color: on ? Theme.copper : "#26282c"; border.width: on ? 2 : 1
              Walnut { anchors.fill: parent; radius: 10; visible: modelData === "send"; seed: 4 }
              Text {
                anchors.centerIn: parent
                text: rs.label(modelData)
                font.family: parent.special || parent.wide ? Theme.mono : Theme.sans
                font.pixelSize: parent.special || parent.wide ? 16 : 24
                color: modelData === "send" ? "#f6ece2" : (modelData === "shift" && rs.shift ? Theme.copper : Theme.text)
              }
              MouseArea {
                anchors.fill: parent
                onClicked: { rs.kr = krow.r; rs.kc = index; rs.press(modelData) }
              }
            }
          }
        }
      }
    }
  }

  Hints {
    anchors.bottom: parent.bottom
    model: rs.mode === "pick" ? ["↑↓ MOVE", "A SEND", "B CANCEL"]
                              : ["A TYPE", "B DELETE", "X SPACE", "Y SHIFT", "*START SEND"]
  }

  function choose() {
    if (sel === 0) { mode = "type"; kr = 1; kc = 0; return }
    send(choices[sel])
  }

  function handle(b) {
    if (mode === "pick") {
      if (b === "up") sel = Math.max(0, sel - 1)
      else if (b === "down") sel = Math.min(choices.length - 1, sel + 1)
      else if (b === "a") choose()
      else if (b === "b") close()
      return true
    }
    const row = rows[kr]
    if (b === "left") kc = (kc + row.length - 1) % row.length
    else if (b === "right") kc = (kc + 1) % row.length
    else if (b === "up" || b === "down") {
      const nr = b === "up" ? Math.max(0, kr - 1) : Math.min(rows.length - 1, kr + 1)
      if (nr !== kr) {
        // Keep roughly the same spot when rows differ in length.
        kc = Math.min(rows[nr].length - 1, Math.round(kc * (rows[nr].length - 1) / Math.max(1, row.length - 1)))
        kr = nr
      }
    }
    else if (b === "a") press(row[kc])
    else if (b === "b") { if (text.length) text = text.slice(0, -1); else mode = "pick" }
    else if (b === "x") text += " "
    else if (b === "y") shift = !shift
    else if (b === "l1") emojiPage = !emojiPage
    else if (b === "start") send(text)
    return true
  }
}
