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

  readonly property var screens: ["watch", "home", "music", "games", "notifications", "settings", "visualizer"]
  readonly property var files: ({ watch: "WatchScreen.qml", home: "HomeScreen.qml", music: "MusicScreen.qml",
                                  games: "GamesScreen.qml", notifications: "NotificationsScreen.qml",
                                  settings: "SettingsScreen.qml", visualizer: "VisualizerScreen.qml" })

  Binding { target: Gamepad; property: "paused"; value: System.busy }
  Binding { target: Gamepad; property: "nintendoLayout"; value: System.settingsRevision >= 0 && System.flag("nintendo", true) }
  Binding { target: Spectrum; property: "active"; value: Nav.screen === "visualizer" && !System.busy }
  Component.onCompleted: {
    if (System.onDevice) showFullScreen()
    System.setKeepAwakeOnLid(keepAwake)
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
    // Flipped shut, the panel faces the other way round: turn everything
    // (touch included) so it reads upright.
    rotation: System.lidClosed ? win.flipRotation : 0
    Behavior on rotation { RotationAnimation { duration: 280; direction: RotationAnimation.Shortest; easing.type: Easing.InOutQuad } }

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

    // Phone: new-notification banner and the incoming call card.
    Banner { z: 8 }
    CallCard { id: callCard; z: 9 }

    // Dimmed while flipped shut and idle (the backlight goes down too).
    Rectangle {
      anchors.fill: parent; z: 9.5
      color: "#000000"
      opacity: win.dimmed ? 0.45 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 600 } }
    }

    Touch {
      objectName: "touch"
      z: 9.8
      target: () => Phone.ringing ? callCard : win.currentScreen()
      onTouched: win.activity()
      onButton: (name) => win.press(name)
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
      if (e.key === Qt.Key_F3) { System.simulateLid(!System.lidClosed); return }
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

  // Any button or touch.
  function activity() {
    idle.restart()
    if (System.lidClosed) lidWake()
  }
  function press(name) {
    activity()
    if (Phone.ringing) { callCard.handle(name); return }
    // Flipped shut it is a lock screen: input only wakes it.
    if (System.lidClosed) return
    if (name === "guide") { Nav.go("home"); return }
    const s = win.currentScreen()
    if (s && s.handle) s.handle(name)
  }
  Connections {
    target: Gamepad
    function onPressed(name) { win.press(name) }
  }

  // Back to the watch after a while with no input (not over music or games).
  Timer {
    id: idle
    interval: Math.max(5, Number(System.settingsRevision >= 0 ? System.setting("idleWatch", 60) : 60)) * 1000
    running: Number(System.setting("idleWatch", 60)) > 0 && !System.busy
    onTriggered: if (["home", "settings", "notifications"].indexOf(Nav.screen) >= 0) Nav.go("watch")
  }

  // Flip shut: the clock (or the visualizer while music plays), then dim,
  // then the normal lid sleep. lidClock 0 sleeps straight away.
  function opt(key, def) { return System.settingsRevision >= 0 ? System.setting(key, def) : def }
  readonly property bool lidViz: System.settingsRevision >= 0 && System.flag("lidVisualizer", true)
  readonly property int lidClock: Number(opt("lidClock", 60))
  readonly property int flipRotation: Number(opt("flipRotation", Number(opt("visualizerRotation", 0)) || 180))
  readonly property bool keepAwake: !System.busy && (lidClock > 0 || (lidViz && Player.playing))
  onKeepAwakeChanged: System.setKeepAwakeOnLid(keepAwake)
  property bool dimmed: false
  readonly property bool showingViz: Nav.screen === "visualizer" && Player.playing

  function setDim(on) { dimmed = on; System.setDimmed(on) }
  function lidWake() {
    if (!System.lidClosed || System.busy) return
    setDim(false)
    dimTimer.stop()
    if (!showingViz && lidClock === 0) { System.sleepNow(); return }
    lidTimer.restart()
  }
  Timer {
    id: lidTimer
    interval: Math.max(5, win.lidClock) * 1000
    onTriggered: {
      if (win.showingViz) { restart(); return }   // stays bright over music
      win.setDim(true)
      dimTimer.restart()
    }
  }
  Timer {
    id: dimTimer
    interval: 30000
    onTriggered: if (System.lidClosed && !System.busy) System.sleepNow()
  }
  Connections {
    target: Player
    function onPlayingChanged() {
      // Music stopped on the flipped screen: back to the clock.
      if (System.lidClosed && !Player.playing && Nav.screen === "visualizer") { Nav.go("watch"); win.lidWake() }
    }
  }
  Connections {
    target: System
    function onLidClosedChanged() {
      if (System.lidClosed) {
        if (System.busy) return
        Nav.go(win.lidViz && Player.playing ? "visualizer" : "watch")
        win.lidWake()
      } else {
        lidTimer.stop(); dimTimer.stop()
        win.setDim(false)
        if (Nav.screen === "visualizer") Nav.back()
      }
    }
    function onBusyChanged() {
      if (!System.busy) { stage.forceActiveFocus(); idle.restart() }
    }
  }
}
