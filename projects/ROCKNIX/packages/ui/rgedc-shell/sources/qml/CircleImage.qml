// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// An image cut to a circle (or ring), drawn with Canvas so it needs no
// graphical-effects module.
Canvas {
  id: c
  property url source
  property real hole: 0            // inner radius in px
  property color fallback: "#5f3a23"
  renderStrategy: Canvas.Cooperative
  onSourceChanged: { if (source != "") loadImage(source); requestPaint() }
  onImageLoaded: requestPaint()
  onWidthChanged: requestPaint()
  onPaint: {
    var ctx = getContext("2d"); ctx.reset()
    var r = width / 2
    ctx.save()
    ctx.beginPath()
    ctx.arc(r, r, r, 0, Math.PI * 2, false)
    if (hole > 0) ctx.arc(r, r, hole, 0, Math.PI * 2, true)
    ctx.clip()
    if (source != "" && isImageLoaded(source)) ctx.drawImage(source, 0, 0, width, height)
    else { ctx.fillStyle = fallback; ctx.fillRect(0, 0, width, height) }
    ctx.restore()
  }
}
