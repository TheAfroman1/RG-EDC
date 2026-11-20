// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// Oiled walnut: a warm gradient with long, slightly wavy grain lines.
Canvas {
  id: c
  property real radius: 0
  property real topLeftRadius: radius
  property real topRightRadius: radius
  property real bottomLeftRadius: radius
  property real bottomRightRadius: radius
  property int seed: 7
  renderStrategy: Canvas.Cooperative
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  function rnd() { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646 }

  onPaint: {
    var ctx = getContext("2d")
    var w = width, h = height
    ctx.reset()
    if (w <= 0 || h <= 0) return
    var tl = Math.min(topLeftRadius, w / 2, h / 2), tr = Math.min(topRightRadius, w / 2, h / 2)
    var bl = Math.min(bottomLeftRadius, w / 2, h / 2), br = Math.min(bottomRightRadius, w / 2, h / 2)
    ctx.beginPath()
    ctx.moveTo(tl, 0); ctx.lineTo(w - tr, 0); ctx.arcTo(w, 0, w, tr, tr)
    ctx.lineTo(w, h - br); ctx.arcTo(w, h, w - br, h, br)
    ctx.lineTo(bl, h); ctx.arcTo(0, h, 0, h - bl, bl)
    ctx.lineTo(0, tl); ctx.arcTo(0, 0, tl, 0, tl)
    ctx.closePath()
    ctx.clip()

    var g = ctx.createLinearGradient(0, 0, w, h)
    g.addColorStop(0, "#5a3520"); g.addColorStop(0.45, "#80502f"); g.addColorStop(1, "#5f3a23")
    ctx.fillStyle = g
    ctx.fillRect(0, 0, w, h)

    var s0 = seed
    // Grain runs along the long side.
    var along = w >= h
    var len = along ? w : h, span = along ? h : w
    var n = Math.max(6, Math.round(span / 2.6))
    for (var i = 0; i < n; ++i) {
      var p = rnd() * span
      var dark = rnd() < 0.62
      ctx.strokeStyle = dark ? "rgba(30,14,6," + (0.10 + rnd() * 0.22).toFixed(2) + ")"
                             : "rgba(255,220,180," + (0.03 + rnd() * 0.07).toFixed(2) + ")"
      ctx.lineWidth = 0.6 + rnd() * 1.6
      var amp = 1 + rnd() * 4, freq = 0.004 + rnd() * 0.01, ph = rnd() * 6.28
      ctx.beginPath()
      for (var t = -4; t <= len + 4; t += 8) {
        var o = p + Math.sin(t * freq + ph) * amp + t * 0.03
        if (along) { if (t < 0) ctx.moveTo(t, o); else ctx.lineTo(t, o) }
        else { if (t < 0) ctx.moveTo(o, t); else ctx.lineTo(o, t) }
      }
      ctx.stroke()
    }
    seed = s0
    // Top sheen
    var sh = ctx.createLinearGradient(0, 0, 0, Math.min(h, 24))
    sh.addColorStop(0, "rgba(255,255,255,0.16)"); sh.addColorStop(0.12, "rgba(255,255,255,0.0)")
    ctx.fillStyle = sh
    ctx.fillRect(0, 0, w, h)
  }
}
