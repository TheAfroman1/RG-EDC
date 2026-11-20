// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import RgEdc 1.0
import "."

// Development aid: walks the screens and saves a PNG of each to $RGEDC_SHOTS.
// Steps: "go:<screen>", "key:<button>", "set:<key>=<value>", "shot:<name>".
Item {
  id: tour
  property Item stage
  readonly property string dir: System.env("RGEDC_SHOTS")
  property var steps: (System.env("RGEDC_TOUR") ||
    "go:watch,wait,shot:watch-analog,set:watchFace=digital,wait,shot:watch-digital,set:watchFace=nixie,wait,shot:watch-nixie," +
    "go:home,wait,shot:home,key:down,wait,shot:home-games,go:music,key:a,wait,wait,shot:music-vinyl,key:y,wait,shot:music-cd,key:x,wait,shot:music-list,key:b," +
    "go:games,wait,wait,shot:games-1,key:r1,wait,shot:games-2,key:r1,wait,shot:games-3,key:r1,wait,shot:games-4,key:r1,wait,shot:games-5,key:r1,wait,shot:games-6," +
    "key:r1,wait,shot:games-7,key:r1,wait,shot:games-8,key:r1,wait,shot:games-9,key:r1,wait,shot:games-10,key:r1,wait,shot:games-11,key:r1,wait,shot:games-12,key:r1,wait,shot:games-13,key:r1,wait,shot:games-14," +
    "go:settings,wait,shot:settings,go:visualizer,wait,wait,shot:visualizer,quit").split(",")
  property int i: 0
  Timer {
    interval: 700; running: true; repeat: true
    onTriggered: {
      if (tour.i >= tour.steps.length) { stop(); return }
      const s = tour.steps[tour.i++]
      const [op, arg] = [s.split(":")[0], s.slice(s.indexOf(":") + 1)]
      if (op === "go") Nav.go(arg)
      else if (op === "key") { Gamepad.inject(arg, true); Gamepad.inject(arg, false) }
      else if (op === "set") { const kv = arg.split("="); System.setSetting(kv[0], kv[1]) }
      else if (op === "shot") tour.stage.grabToImage(r => r.saveToFile(tour.dir + "/" + arg + ".png"))
      else if (op === "quit") Qt.quit()
    }
  }
}
