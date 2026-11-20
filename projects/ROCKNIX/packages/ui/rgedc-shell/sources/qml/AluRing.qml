// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// Brushed aluminum disc or ring (conic highlights), optionally with a hole.
Canvas {
  id: c
  property real hole: 0          // inner radius as a fraction of the outer
  property real angle: 0.35
  renderStrategy: Canvas.Cooperative
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var r = Math.min(width, height) / 2, cx = width / 2, cy = height / 2
    if (r <= 0) return
    var g = ctx.createConicalGradient(cx, cy, angle)
    var stops = ["#8d9197", "#e6e8eb", "#9a9ea4", "#d2d5d9", "#878b91", "#e1e3e6", "#8d9197"]
    for (var i = 0; i < stops.length; ++i) g.addColorStop(i / (stops.length - 1), stops[i])
    ctx.beginPath()
    ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
    if (hole > 0) ctx.arc(cx, cy, r * hole, 0, Math.PI * 2, true)
    ctx.fillStyle = g
    ctx.fill()
    // fine circular brushing
    ctx.lineWidth = 0.6
    for (var k = r * Math.max(hole, 0.05); k < r; k += 1.6) {
      ctx.strokeStyle = (Math.round(k) % 3 === 0) ? "rgba(255,255,255,0.07)" : "rgba(0,0,0,0.05)"
      ctx.beginPath(); ctx.arc(cx, cy, k, 0, Math.PI * 2); ctx.stroke()
    }
    ctx.beginPath(); ctx.arc(cx, cy, r - 0.5, 0, Math.PI * 2)
    ctx.strokeStyle = "rgba(255,255,255,0.35)"; ctx.lineWidth = 1; ctx.stroke()
  }
}
