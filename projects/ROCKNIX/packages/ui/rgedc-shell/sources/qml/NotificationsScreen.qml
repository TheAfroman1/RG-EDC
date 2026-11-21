// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."
import RgEdc 1.0

// Phone notifications, newest first. A opens one, X clears it (on the phone
// too), Y replies (Android), Select clears all.
Item {
  id: ns
  width: 720; height: 720
  property int sel: 0
  property bool expanded: false
  property bool confirmAll: false
  readonly property var items: Phone.notifications
  readonly property var cur: items.length ? items[Math.min(sel, items.length - 1)] : null

  onItemsChanged: if (sel >= items.length) sel = Math.max(0, items.length - 1)
  Component.onCompleted: Phone.markAllRead()
  Connections {
    target: Nav
    function onScreenChanged() { if (Nav.screen === "notifications") { ns.sel = 0; ns.expanded = false; Phone.markAllRead() } }
  }
  Connections {
    target: Phone
    function onNotificationsChanged() { if (Nav.screen === "notifications") Phone.markAllRead() }
  }

  function ago(t) {
    const s = Math.max(0, Date.now() / 1000 - t)
    if (s < 60) return "now"
    if (s < 3600) return Math.floor(s / 60) + " min"
    if (s < 86400) return Math.floor(s / 3600) + " h"
    return Qt.formatDate(new Date(t * 1000), "d MMM")
  }
  // Re-evaluate the "x min" labels every minute.
  property int tick: 0
  Timer { interval: 60000; running: Nav.screen === "notifications"; repeat: true; onTriggered: ns.tick++ }

  Rectangle { anchors.fill: parent; color: Theme.bg }
  StatusBar { label: "NOTIFICATIONS" }

  // Phone line under the status bar
  Text {
    x: 36; y: 64
    text: !Phone.available ? "Bluetooth is off"
        : Phone.connected ? (Phone.kind === "ios" ? "iPhone · " : "Android · ") + Phone.name
        : Phone.known.length ? "Phone not connected" : "No phone paired. Settings › Phone"
    font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 1
    color: Phone.connected ? Theme.creamDim : Theme.textMute
  }

  ListView {
    id: lv
    x: 36; y: 96; width: 648; height: 720 - 96 - 64
    clip: true
    spacing: 10
    model: ns.items
    currentIndex: ns.sel
    highlightMoveDuration: 160
    preferredHighlightBegin: 0; preferredHighlightEnd: height - 140
    highlightRangeMode: ListView.ApplyRange
    visible: ns.items.length > 0 && !ns.expanded
    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.med } }
    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast } }
    displaced: Transition { NumberAnimation { property: "y"; duration: Theme.med; easing.type: Easing.OutCubic } }
    delegate: Rectangle {
      required property var modelData
      required property int index
      readonly property bool on: index === ns.sel
      width: lv.width; height: title.y + title.height + (body.visible ? body.height + 4 : 0) + 20
      radius: 16
      color: on ? "#17181b" : "#0f1012"
      border.color: on ? "#3a3c41" : Theme.panelLine; border.width: 1
      Behavior on color { ColorAnimation { duration: Theme.fast } }
      Walnut {
        visible: parent.on
        x: 0; width: 6; height: parent.height
        topLeftRadius: 16; bottomLeftRadius: 16; topRightRadius: 0; bottomRightRadius: 0
      }
      Text {
        id: app
        x: 24; y: 16
        text: (modelData.app || "Phone").toUpperCase()
        font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 2
        color: modelData.category === "call" || modelData.category === "missed-call" ? Theme.copper : Theme.textMute
      }
      Text {
        anchors.right: parent.right; anchors.rightMargin: 22; y: 16
        text: ns.tick >= 0 ? ns.ago(modelData.time) : ""
        font.family: Theme.mono; font.pixelSize: 12
        color: Theme.textMute
      }
      Text {
        id: title
        x: 24; y: 38; width: parent.width - 48
        text: modelData.title || modelData.app || ""
        elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: 22; font.weight: Font.DemiBold
        color: Theme.text
      }
      Text {
        id: body
        x: 24; y: title.y + title.height + 4; width: parent.width - 48
        text: [modelData.subtitle, modelData.body].filter(s => s).join(" · ")
        visible: text !== ""
        wrapMode: Text.WordWrap; maximumLineCount: parent.on ? 3 : 1; elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: 17; lineHeight: 1.25
        color: Theme.textDim
      }
    }
  }

  // Full text of one notification
  Item {
    anchors.fill: parent
    visible: ns.expanded && ns.cur !== null
    Flickable {
      id: fl
      x: 36; y: 96; width: 648; height: 720 - 96 - 64
      contentHeight: full.height
      clip: true
      Column {
        id: full
        width: parent.width
        spacing: 12
        Text {
          text: ns.cur ? (ns.cur.app || "Phone").toUpperCase() + "   " + Qt.formatDateTime(new Date(ns.cur.time * 1000), "ddd d MMM, hh:mm") : ""
          font.family: Theme.mono; font.pixelSize: 13; font.letterSpacing: 2; color: Theme.copper
        }
        Text {
          width: parent.width; wrapMode: Text.WordWrap
          text: ns.cur ? (ns.cur.title || "") : ""
          font.family: Theme.sans; font.pixelSize: 34; font.weight: Font.Bold; color: Theme.text
        }
        Text {
          width: parent.width; wrapMode: Text.WordWrap
          visible: text !== ""
          text: ns.cur ? (ns.cur.subtitle || "") : ""
          font.family: Theme.sans; font.pixelSize: 20; font.weight: Font.DemiBold; color: Theme.creamDim
        }
        Text {
          width: parent.width; wrapMode: Text.WordWrap
          text: ns.cur ? (ns.cur.body || "") : ""
          font.family: Theme.sans; font.pixelSize: 22; lineHeight: 1.35; color: Theme.textDim
        }
      }
    }
  }

  // Empty
  Column {
    anchors.centerIn: parent
    spacing: 14
    visible: ns.items.length === 0
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "All caught up"
      font.family: Theme.sans; font.pixelSize: 40; font.weight: Font.DemiBold; color: Theme.text
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      horizontalAlignment: Text.AlignHCenter
      text: Phone.connected ? "New notifications from " + Phone.name + "\nshow up here."
                            : "Pair a phone in Settings › Phone\nto see its notifications here."
      font.family: Theme.sans; font.pixelSize: 18; lineHeight: 1.3; color: Theme.textDim
    }
  }

  Hints {
    anchors.bottom: parent.bottom
    model: ns.confirmAll ? ["*SELECT AGAIN TO CLEAR ALL", "B CANCEL"]
         : ns.expanded ? ["↑↓ SCROLL"].concat(ns.canReply ? ["*Y REPLY"] : []).concat(["X CLEAR", "B BACK"])
         : ns.items.length ? ["↑↓ MOVE", "A OPEN"].concat(ns.canReply ? ["*Y REPLY"] : []).concat(["X CLEAR", "SELECT CLEAR ALL"])
         : ["B HOME"]
  }

  ReplySheet { id: reply; z: 5; onDone: ns.expanded = false }
  Connections {
    target: Phone
    function onReplied(id, ok) { ns.toast = ok ? "Reply sent" : "Couldn't send the reply"; toastTimer.restart() }
  }
  property string toast: ""
  Timer { id: toastTimer; interval: 2500; onTriggered: ns.toast = "" }
  Rectangle {
    z: 6
    visible: opacity > 0
    opacity: ns.toast !== "" ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.med } }
    anchors.horizontalCenter: parent.horizontalCenter
    y: 610; width: toastText.width + 48; height: 44; radius: 22
    color: "#1a1b1e"; border.color: Theme.line
    Text { id: toastText; anchors.centerIn: parent; text: ns.toast; font.family: Theme.sans; font.pixelSize: 17; color: Theme.creamDim }
  }

  // Replies go through Gadgetbridge; iPhones don't let accessories reply.
  readonly property bool canReply: cur !== null && cur.reply === true && Phone.connected && Phone.kind === "android"

  function handle(b) {
    if (reply.open) return reply.handle(b)
    if (confirmAll) {
      confirmAll = false
      if (b === "select") Phone.clearAll()
      return true
    }
    if (b === "y" && canReply) { reply.show(cur); return true }
    if (expanded) {
      if (b === "up") { fl.contentY = Math.max(0, fl.contentY - 120); return true }
      if (b === "down") { fl.contentY = Math.min(Math.max(0, fl.contentHeight - fl.height), fl.contentY + 120); return true }
      if (b === "x" && cur) { Phone.dismiss(cur.id); expanded = false; return true }
      if (b === "b" || b === "a") { expanded = false; return true }
      return true
    }
    if (b === "up") { sel = Math.max(0, sel - 1); return true }
    if (b === "down") { sel = Math.min(items.length - 1, sel + 1); return true }
    if (b === "a" && cur) { expanded = true; fl.contentY = 0; return true }
    if (b === "x" && cur) { Phone.dismiss(cur.id); return true }
    if (b === "select" && items.length) { confirmAll = true; return true }
    if (b === "b") { Nav.go("home"); return true }
    return false
  }
}
