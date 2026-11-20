// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import QtQuick.Window
import RgEdc 1.0
import "."

Window {
  id: win
  width: 720; height: 720
  color: "#000000"
  title: "RG EDC"
  // Hidden while a game, slot. or EmulationStation runs, so it gets the screen.
  visible: !(System.busy && System.onDevice)
  onVisibleChanged: if (visible && System.onDevice) showFullScreen()

  readonly property var screens: ["watch", "home", "music", "games", "settings", "visualizer"]
  readonly property var files: ({ watch: "WatchScreen.qml", home: "HomeScreen.qml", music: "MusicScreen.qml",
                                  games: "GamesScreen.qml", settings: "SettingsScreen.qml", visualizer: "VisualizerScreen.qml" })

  Binding { target: Gamepad; property: "paused"; value: System.busy }
  Binding { target: Gamepad; property: "nintendoLayout"; value: System.settingsRevision >= 0 && System.flag("nintendo", true) }
  Binding { target: Spectrum; property: "active"; value: Nav.screen === "visualizer" && !System.busy }
  Component.onCompleted: {
    if (System.onDevice) showFullScreen()
    Spectrum.player = Player.media
    Qt.callLater(Library.rescan)
  }

  // Square content, centered if the window is ever larger (desktop).
  Item {
    id: stage
    width: 720; height: 720
    anchors.centerIn: parent
    scale: Math.min(win.width / 720, win.height / 720)
    focus: true

    Repeater {
      model: win.screens
      delegate: Loader {
        required property string modelData
        readonly property bool current: Nav.screen === modelData
        property bool visited: false
        onCurrentChanged: if (current) visited = true
        Component.onCompleted: if (current) visited = true
        width: 720; height: 720
        active: visited
        source: win.files[modelData]
        visible: opacity > 0
        opacity: current ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        z: current ? 1 : 0
      }
    }

    // Start-up splash: the RG EDC badge, fading into the watch.
    Rectangle {
      id: splash
      anchors.fill: parent
      color: "#000000"
      z: 10
      visible: opacity > 0
      Image {
        anchors.centerIn: parent
        width: 520; height: 520
        source: "images/logo.png"
        smooth: true; mipmap: true
        scale: splash.opacity < 1 ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
      }
      SequentialAnimation on opacity {
        running: System.env("RGEDC_SHOTS") === ""
        PauseAnimation { duration: 1600 }
        NumberAnimation { to: 0; duration: 600; easing.type: Easing.InOutQuad }
      }
      Component.onCompleted: if (System.env("RGEDC_SHOTS") !== "") opacity = 0
    }

    // Keyboard fallback for desktop testing.
    readonly property var keymap: ({
      [Qt.Key_Up]: "up", [Qt.Key_Down]: "down", [Qt.Key_Left]: "left", [Qt.Key_Right]: "right",
      [Qt.Key_Return]: "a", [Qt.Key_Enter]: "a", [Qt.Key_Space]: "a",
      [Qt.Key_Escape]: "b", [Qt.Key_Backspace]: "b",
      [Qt.Key_X]: "x", [Qt.Key_Y]: "y", [Qt.Key_Q]: "l1", [Qt.Key_E]: "r1",
      [Qt.Key_1]: "l2", [Qt.Key_3]: "r2", [Qt.Key_Tab]: "select", [Qt.Key_S]: "start", [Qt.Key_H]: "guide",
    })
    Keys.onPressed: (e) => {
      if (e.key === Qt.Key_F2) { Nav.go(Nav.screen === "visualizer" ? Nav.previous : "visualizer"); return }
      const n = keymap[e.key]
      if (n && !e.isAutoRepeat) { Gamepad.inject(n, true); e.accepted = true }
    }
    Keys.onReleased: (e) => {
      const n = keymap[e.key]
      if (n && !e.isAutoRepeat) { Gamepad.inject(n, false); e.accepted = true }
    }
  }

  // Screenshot tour for development: RGEDC_SHOTS=<dir>.
  Loader {
    active: System.env("RGEDC_SHOTS") !== ""
    source: "ShotTour.qml"
    onLoaded: item.stage = stage
  }

  function currentScreen() {
    for (let i = 0; i < stage.children.length; ++i) {
      const c = stage.children[i]
      if (c.current && c.item) return c.item
    }
    return null
  }

  Connections {
    target: Gamepad
    function onPressed(name) {
      idle.restart()
      if (name === "guide") { Nav.go("home"); return }
      const s = win.currentScreen()
      if (s && s.handle) s.handle(name)
    }
  }

  // Back to the watch after a while with no input (not over music or games).
  Timer {
    id: idle
    interval: Math.max(5, Number(System.settingsRevision >= 0 ? System.setting("idleWatch", 60) : 60)) * 1000
    running: Number(System.setting("idleWatch", 60)) > 0 && !System.busy
    onTriggered: if (Nav.screen === "home" || Nav.screen === "settings") Nav.go("watch")
  }

  // Flip shut: visualizer while music plays, otherwise the normal sleep.
  readonly property bool lidViz: System.settingsRevision >= 0 && System.flag("lidVisualizer", true)
  readonly property bool keepAwake: lidViz && Player.playing
  onKeepAwakeChanged: System.setKeepAwakeOnLid(keepAwake)
  Connections {
    target: System
    function onLidClosedChanged() {
      if (System.lidClosed && win.keepAwake) Nav.go("visualizer")
      else if (!System.lidClosed && Nav.screen === "visualizer") Nav.back()
    }
    function onBusyChanged() {
      if (!System.busy) { stage.forceActiveFocus(); idle.restart() }
    }
  }
}
