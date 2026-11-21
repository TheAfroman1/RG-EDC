// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// Touch, so the shell works without the buttons. Everything becomes the
// same button presses the screens already handle:
//   tap                  the item under the finger (or A)
//   drag                 the content follows the finger: one step per
//                        `dragStep` pixels (screens may set it), e.g. drag
//                        up = down, drag left = right
//   swipe in from left   back (B)
//   swipe down from top  home
//   press and hold       X
// A screen can mark a tappable item with a `tapAction(x, y)` function.
MouseArea {
  id: t
  anchors.fill: parent
  pressAndHoldInterval: 550

  property var target: null          // function returning the item that gets taps
  signal button(string name)
  signal touched()

  readonly property int edge: 48
  property point start
  property string axis: ""
  property int steps: 0
  property bool moved: false
  property bool held: false

  function stepFor(s) { return s && s.dragStep ? s.dragStep : 90 }

  function findTap(item, x, y) {
    let best = null
    let cur = item
    while (cur) {
      if (typeof cur.tapAction === "function") best = { item: cur, x: x, y: y }
      const c = cur.childAt(x, y)
      if (!c) break
      const p = cur.mapToItem(c, x, y)
      cur = c; x = p.x; y = p.y
    }
    return best
  }

  // Same as a tap at (x, y) in this item (testing).
  function tapAt(x, y) {
    const s = target ? target() : null
    if (s) {
      const p = t.mapToItem(s, x, y)
      const hit = findTap(s, p.x, p.y)
      if (hit) { hit.item.tapAction(hit.x, hit.y); return }
    }
    button("a")
  }

  onPressed: (m) => {
    start = Qt.point(m.x, m.y)
    axis = ""; steps = 0; moved = false; held = false
    touched()
  }

  onPositionChanged: (m) => {
    const dx = m.x - start.x, dy = m.y - start.y
    if (!moved) {
      if (Math.hypot(dx, dy) < 24) return
      moved = true
      axis = Math.abs(dx) > Math.abs(dy) ? "x" : "y"
    }
    // Edge swipes are decided on release.
    if ((axis === "x" && start.x < edge) || (axis === "y" && start.y < edge)) return
    const d = axis === "x" ? dx : dy
    const n = Math.trunc(d / stepFor(target ? target() : null))
    while (steps < n) { steps++; button(axis === "x" ? "left" : "up") }
    while (steps > n) { steps--; button(axis === "x" ? "right" : "down") }
  }

  onPressAndHold: {
    if (moved) return
    held = true
    button("x")
  }

  onReleased: (m) => {
    const dx = m.x - start.x, dy = m.y - start.y
    if (held) return
    if (moved) {
      if (axis === "x" && start.x < edge) { if (dx > 90) button("b"); return }
      if (axis === "y" && start.y < edge) { if (dy > 90) button("guide"); return }
      // A short flick still counts as one step.
      const d = axis === "x" ? dx : dy
      if (steps === 0 && Math.abs(d) > 40)
        button(axis === "x" ? (d > 0 ? "left" : "right") : (d > 0 ? "up" : "down"))
      return
    }
    tapAt(m.x, m.y)
  }
}
