// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// A cartridge (or card, floppy, tape) drawn to its real-world front-face
// proportions, with the scraped art as its label.
Item {
  id: cart
  property string kind: "cart"
  property string title: ""
  property url art: ""
  readonly property var spec: specs[kind] !== undefined ? specs[kind] : specs.cart
  width: spec.w; height: spec.h

  // label color when there is no scraped art
  function hue(s) { var h = 0; for (var i = 0; i < s.length; ++i) h = (h * 31 + s.charCodeAt(i)) >>> 0; return (h % 360) / 360 }
  readonly property color labelColor: Qt.hsla(hue(title), 0.42, 0.36, 1)

  readonly property var specs: ({
    // w, h; shell top/bottom colors; outline; recess [x,y,w,h]; recess color;
    // ridges: [x,y,w,h,dir]; extras
    gb:   { w: 172, h: 196, c0: "#d6d7da", c1: "#b5b7bb", shape: "notch", r: 10, recess: [14, 36, 144, 122], rc: "#a9abaf", lr: 4,
            ridges: [[12, 9, 120, 18, "h"]], arrow: [75, 170, 22, 13] },
    gbc:  { w: 172, h: 196, c0: "#3a3c41", c1: "#1a1b1e", shape: "notch", r: 10, recess: [14, 36, 144, 122], rc: "#141517", lr: 4,
            ridges: [[12, 9, 120, 18, "h"]], arrow: [75, 170, 22, 13], light: true },
    gba:  { w: 236, h: 142, c0: "#4b4d52", c1: "#2c2d31", shape: "gba", r: 8, recess: [20, 14, 196, 84], rc: "#202124", lr: 3,
            ridges: [[64, 112, 108, 16, "v"]], light: true },
    nds:  { w: 140, h: 160, c0: "#5a5c61", c1: "#3c3e42", shape: "notch", r: 6, recess: [10, 24, 120, 106], rc: "#2a2b2e", lr: 3,
            ridges: [[14, 140, 112, 10, "v"]], light: true },
    nes:  { w: 200, h: 220, c0: "#a5a8ad", c1: "#808388", shape: "rect", r: 3, recess: [16, 20, 168, 128], rc: "#8e9196", lr: 1,
            ridges: [[10, 160, 180, 52, "h"]] },
    famicom: { w: 190, h: 124, c0: "#d4cbb8", c1: "#b9af9a", shape: "rect", r: 6, recess: [16, 12, 158, 76], rc: "#a99f8b", lr: 2,
            ridges: [[16, 98, 158, 16, "v"]] },
    fds:  { w: 170, h: 200, c0: "#e8c547", c1: "#cfa92c", shape: "rect", r: 5, recess: [14, 88, 142, 100], rc: "#d1ac34", lr: 2,
            shutter: [44, 0, 82, 64] },
    snes: { w: 248, h: 170, c0: "#c3c5c9", c1: "#9fa2a7", shape: "snes", r: 26, recess: [46, 22, 156, 112], rc: "#a8abb0", lr: 4,
            ridges: [[70, 144, 108, 16, "h"]], grooves: true },
    sfc:  { w: 248, h: 170, c0: "#cfd0d3", c1: "#a7a9ae", shape: "snes", r: 26, recess: [46, 22, 156, 112], rc: "#b1b3b8", lr: 4,
            ridges: [[70, 144, 108, 16, "h"]], grooves: true },
    n64:  { w: 236, h: 172, c0: "#55575c", c1: "#36383c", shape: "n64", r: 10, recess: [38, 24, 160, 110], rc: "#2b2c30", lr: 3,
            ridges: [[8, 40, 20, 100, "h"], [208, 40, 20, 100, "h"]], light: true },
    vb:   { w: 200, h: 140, c0: "#2a2a2c", c1: "#141415", shape: "rect", r: 8, recess: [16, 12, 168, 92], rc: "#3a0d0d", lr: 3, light: true },
    pokemini: { w: 110, h: 120, c0: "#e9e9ea", c1: "#c8c9cb", shape: "rect", r: 8, recess: [10, 10, 90, 80], rc: "#bbbcbe", lr: 3 },
    genesis: { w: 196, h: 240, c0: "#26272a", c1: "#0f0f10", shape: "rect", r: 6, recess: [14, 14, 168, 150], rc: "#0b0b0c", lr: 2,
            ridges: [[22, 182, 152, 44, "h"]], light: true },
    megadrive: { w: 196, h: 240, c0: "#26272a", c1: "#0f0f10", shape: "rect", r: 6, recess: [14, 14, 168, 150], rc: "#0b0b0c", lr: 2,
            ridges: [[22, 182, 152, 44, "h"]], light: true },
    s32x: { w: 196, h: 250, c0: "#2b2b2e", c1: "#121214", shape: "rect", r: 6, recess: [14, 14, 168, 150], rc: "#0b0b0c", lr: 2,
            ridges: [[22, 186, 152, 50, "h"]], light: true },
    sms:  { w: 206, h: 150, c0: "#232326", c1: "#0f0f10", shape: "rect", r: 5, recess: [14, 12, 178, 98], rc: "#e9e9ea", lr: 2,
            ridges: [[14, 120, 178, 20, "h"]], light: true },
    gamegear: { w: 160, h: 122, c0: "#29292c", c1: "#111113", shape: "rect", r: 8, recess: [12, 10, 136, 84], rc: "#0b0b0c", lr: 3, light: true },
    atari2600: { w: 176, h: 150, c0: "#252527", c1: "#0d0d0e", shape: "rect", r: 4, recess: [12, 10, 152, 92], rc: "#0b0b0c", lr: 2,
            ridges: [[12, 112, 152, 30, "h"]], light: true },
    atari5200: { w: 196, h: 200, c0: "#3a3b3e", c1: "#1d1e20", shape: "rect", r: 6, recess: [16, 14, 164, 124], rc: "#141416", lr: 2,
            ridges: [[16, 150, 164, 40, "h"]], light: true },
    atari7800: { w: 176, h: 150, c0: "#4a4b4e", c1: "#2b2c2e", shape: "rect", r: 4, recess: [12, 10, 152, 92], rc: "#1b1c1e", lr: 2,
            ridges: [[12, 112, 152, 30, "h"]], light: true },
    lynx: { w: 156, h: 112, c0: "#3a3b3e", c1: "#1f2022", shape: "rect", r: 14, recess: [12, 10, 132, 74], rc: "#141416", lr: 6, light: true },
    jaguar: { w: 210, h: 200, c0: "#242426", c1: "#0d0d0e", shape: "rect", r: 12, recess: [18, 40, 174, 124], rc: "#0b0b0c", lr: 3,
            ridges: [[60, 10, 90, 18, "v"]], light: true },
    coleco: { w: 180, h: 190, c0: "#2b2c2e", c1: "#141415", shape: "rect", r: 4, recess: [14, 12, 152, 120], rc: "#0b0b0c", lr: 2,
            ridges: [[14, 146, 152, 34, "h"]], light: true },
    intv: { w: 210, h: 150, c0: "#2b2c2e", c1: "#141415", shape: "rect", r: 5, recess: [14, 12, 182, 96], rc: "#0b0b0c", lr: 2, light: true },
    odyssey: { w: 190, h: 150, c0: "#2b2c2e", c1: "#141415", shape: "rect", r: 5, recess: [14, 12, 162, 96], rc: "#0b0b0c", lr: 2, light: true },
    channelf: { w: 180, h: 200, c0: "#eceae4", c1: "#c9c6bd", shape: "rect", r: 4, recess: [14, 14, 152, 120], rc: "#b9b6ad", lr: 2,
            ridges: [[14, 150, 152, 40, "h"]] },
    vectrex: { w: 200, h: 170, c0: "#2b2c2e", c1: "#141415", shape: "rect", r: 5, recess: [14, 12, 172, 110], rc: "#0b0b0c", lr: 2, light: true },
    hucard: { w: 206, h: 132, c0: "#f4f4f2", c1: "#dcdcd8", shape: "rect", r: 10, recess: [8, 8, 170, 116], rc: "#e4e4e1", lr: 6, contacts: true },
    ngp:  { w: 146, h: 120, c0: "#35363a", c1: "#1c1d20", shape: "rect", r: 8, recess: [10, 10, 126, 82], rc: "#141416", lr: 3,
            ridges: [[34, 100, 78, 12, "v"]], light: true },
    ws:   { w: 156, h: 114, c0: "#4a4d55", c1: "#2c2e33", shape: "rect", r: 8, recess: [10, 10, 136, 78], rc: "#1f2125", lr: 3, light: true },
    mvs:  { w: 270, h: 176, c0: "#242426", c1: "#0d0d0e", shape: "rect", r: 6, recess: [20, 18, 230, 116], rc: "#0b0b0c", lr: 2,
            ridges: [[20, 146, 230, 20, "v"]], light: true },
    arcade: { w: 270, h: 160, c0: "#1d3a26", c1: "#0f2215", shape: "rect", r: 3, recess: [16, 14, 238, 110], rc: "#0b160e", lr: 2,
            contacts: true, light: true },
    floppy: { w: 200, h: 208, c0: "#2b2c30", c1: "#18191b", shape: "floppy", r: 6, recess: [22, 92, 156, 108], rc: "#e9e9ea", lr: 2,
            shutter: [58, 0, 92, 70], light: true },
    msx:  { w: 200, h: 150, c0: "#2b2c2e", c1: "#141415", shape: "rect", r: 5, recess: [14, 12, 172, 100], rc: "#0b0b0c", lr: 2,
            ridges: [[14, 124, 172, 18, "h"]], light: true },
    tape: { w: 240, h: 152, c0: "#3a3b3f", c1: "#202124", shape: "rect", r: 10, recess: [16, 14, 208, 74], rc: "#e9e9ea", lr: 4,
            reels: true, light: true },
    umd:  { w: 180, h: 200, c0: "#2b2c30", c1: "#141416", shape: "rect", r: 24, recess: [16, 16, 148, 128], rc: "#0b0b0c", lr: 12, light: true },
    cart: { w: 190, h: 210, c0: "#2b2c30", c1: "#141416", shape: "rect", r: 6, recess: [14, 14, 162, 134], rc: "#0b0b0c", lr: 3,
            ridges: [[14, 160, 162, 40, "h"]], light: true },
  })

  // Shell
  Canvas {
    id: shell
    anchors.fill: parent
    renderStrategy: Canvas.Cooperative
    Component.onCompleted: requestPaint()
    onPaint: {
      var s = cart.spec, ctx = getContext("2d"), w = width, h = height, r = s.r
      ctx.reset()
      ctx.beginPath()
      if (s.shape === "notch") {
        ctx.moveTo(4, 0); ctx.lineTo(w * 0.84, 0); ctx.lineTo(w, h * 0.11)
        ctx.lineTo(w, h - r); ctx.arcTo(w, h, w - r, h, r)
        ctx.lineTo(r, h); ctx.arcTo(0, h, 0, h - r, r)
        ctx.lineTo(0, 4); ctx.arcTo(0, 0, 4, 0, 4)
      } else if (s.shape === "gba") {
        var b = h * 0.78, i = w * 0.06
        ctx.moveTo(r, 0); ctx.lineTo(w - r, 0); ctx.arcTo(w, 0, w, r, r)
        ctx.lineTo(w, b); ctx.lineTo(w - i, b); ctx.lineTo(w - i, h - r); ctx.arcTo(w - i, h, w - i - r, h, r)
        ctx.lineTo(i + r, h); ctx.arcTo(i, h, i, h - r, r); ctx.lineTo(i, b); ctx.lineTo(0, b)
        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r)
      } else if (s.shape === "snes") {
        ctx.moveTo(r, 0); ctx.lineTo(w - r, 0); ctx.arcTo(w, 0, w, r, r)
        ctx.lineTo(w, h - 6); ctx.arcTo(w, h, w - 6, h, 6)
        ctx.lineTo(6, h); ctx.arcTo(0, h, 0, h - 6, 6)
        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r)
      } else if (s.shape === "n64") {
        ctx.moveTo(18, 0); ctx.lineTo(w - 18, 0); ctx.lineTo(w, 28)
        ctx.lineTo(w, h - r); ctx.arcTo(w, h, w - r, h, r)
        ctx.lineTo(r, h); ctx.arcTo(0, h, 0, h - r, r); ctx.lineTo(0, 28)
      } else if (s.shape === "floppy") {
        ctx.moveTo(r, 0); ctx.lineTo(w - 14, 0); ctx.lineTo(w, 14)
        ctx.lineTo(w, h - r); ctx.arcTo(w, h, w - r, h, r)
        ctx.lineTo(r, h); ctx.arcTo(0, h, 0, h - r, r)
        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r)
      } else {
        ctx.moveTo(r, 0); ctx.lineTo(w - r, 0); ctx.arcTo(w, 0, w, r, r)
        ctx.lineTo(w, h - r); ctx.arcTo(w, h, w - r, h, r)
        ctx.lineTo(r, h); ctx.arcTo(0, h, 0, h - r, r)
        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r)
      }
      ctx.closePath()
      var g = ctx.createLinearGradient(0, 0, 0, h)
      g.addColorStop(0, s.c0); g.addColorStop(1, s.c1)
      ctx.fillStyle = g
      ctx.fill()
      ctx.save(); ctx.clip()
      // edge light and shade
      ctx.strokeStyle = "rgba(255,255,255,0.35)"; ctx.lineWidth = 2
      ctx.beginPath(); ctx.moveTo(0, 1); ctx.lineTo(w, 1); ctx.stroke()
      ctx.strokeStyle = "rgba(0,0,0,0.3)"; ctx.lineWidth = 4
      ctx.beginPath(); ctx.moveTo(0, h - 1); ctx.lineTo(w, h - 1); ctx.stroke()

      var hi = s.light ? "rgba(255,255,255,0.14)" : "rgba(0,0,0,0.22)"
      var lo = s.light ? "rgba(0,0,0,0.35)" : "rgba(255,255,255,0.10)"
      ;(s.ridges || []).forEach(function (rg) {
        var x = rg[0], y = rg[1], rw = rg[2], rh = rg[3]
        if (rg[4] === "h") {
          for (var yy = y; yy < y + rh; yy += 5) {
            ctx.fillStyle = hi; ctx.fillRect(x, yy, rw, 2)
            ctx.fillStyle = lo; ctx.fillRect(x, yy + 2, rw, 1)
          }
        } else {
          for (var xx = x; xx < x + rw; xx += 6) {
            ctx.fillStyle = hi; ctx.fillRect(xx, y, 2, rh)
            ctx.fillStyle = lo; ctx.fillRect(xx + 2, y, 1, rh)
          }
        }
      })
      if (s.grooves) {
        [10, w - 30].forEach(function (gx) {
          var gg = ctx.createLinearGradient(gx, 0, gx + 20, 0)
          gg.addColorStop(0, "rgba(0,0,0,0.28)"); gg.addColorStop(1, "rgba(0,0,0,0.06)")
          ctx.fillStyle = gg
          ctx.beginPath(); ctx.moveTo(gx + 10, 34); ctx.arcTo(gx + 20, 34, gx + 20, 44, 10)
          ctx.lineTo(gx + 20, 128); ctx.arcTo(gx + 20, 138, gx + 10, 138, 10)
          ctx.arcTo(gx, 138, gx, 128, 10); ctx.lineTo(gx, 44); ctx.arcTo(gx, 34, gx + 10, 34, 10)
          ctx.fill()
        })
      }
      if (s.arrow) {
        var a = s.arrow
        ctx.fillStyle = s.light ? "rgba(255,255,255,0.16)" : "rgba(0,0,0,0.2)"
        ctx.beginPath(); ctx.moveTo(a[0] + a[2] / 2, a[1]); ctx.lineTo(a[0] + a[2], a[1] + a[3]); ctx.lineTo(a[0], a[1] + a[3]); ctx.fill()
      }
      if (s.shutter) {
        var sh = s.shutter
        var mg = ctx.createLinearGradient(sh[0], 0, sh[0] + sh[2], 0)
        mg.addColorStop(0, "#9ea2a8"); mg.addColorStop(0.5, "#e6e8eb"); mg.addColorStop(1, "#a9adb3")
        ctx.fillStyle = mg; ctx.fillRect(sh[0], sh[1], sh[2], sh[3])
        ctx.fillStyle = "#1a1a1c"; ctx.fillRect(sh[0] + sh[2] * 0.62, sh[1] + 10, sh[2] * 0.2, sh[3] - 22)
      }
      if (s.contacts) {
        for (var cx = 18; cx < w - 18; cx += 9) {
          ctx.fillStyle = "#c9a54a"; ctx.fillRect(cx, h - 10, 5, 8)
        }
      }
      ctx.restore()
      // recess
      var rc = s.recess
      ctx.fillStyle = s.rc
      ctx.beginPath()
      ctx.moveTo(rc[0] + 6, rc[1]); ctx.arcTo(rc[0] + rc[2], rc[1], rc[0] + rc[2], rc[1] + rc[3], 6)
      ctx.arcTo(rc[0] + rc[2], rc[1] + rc[3], rc[0], rc[1] + rc[3], 6)
      ctx.arcTo(rc[0], rc[1] + rc[3], rc[0], rc[1], 6); ctx.arcTo(rc[0], rc[1], rc[0] + rc[2], rc[1], 6)
      ctx.fill()
      ctx.strokeStyle = "rgba(0,0,0,0.35)"; ctx.lineWidth = 1.5; ctx.stroke()
      if (s.reels) {
        [w * 0.3, w * 0.7].forEach(function (rx) {
          ctx.fillStyle = "#121214"; ctx.beginPath(); ctx.arc(rx, h - 34, 15, 0, Math.PI * 2); ctx.fill()
          ctx.fillStyle = "#e9e9ea"; ctx.beginPath(); ctx.arc(rx, h - 34, 7, 0, Math.PI * 2); ctx.fill()
        })
      }
    }
  }

  // Label
  Item {
    id: label
    x: cart.spec.recess[0] + 5; y: cart.spec.recess[1] + 5
    width: cart.spec.recess[2] - 10; height: cart.spec.recess[3] - 10
    clip: true
    Rectangle {
      anchors.fill: parent
      radius: cart.spec.lr
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(cart.labelColor, 1.35) }
        GradientStop { position: 1.0; color: Qt.darker(cart.labelColor, 1.6) }
      }
    }
    // stripes for art-less labels
    Repeater {
      model: img.status === Image.Ready ? 0 : 8
      Rectangle {
        required property int index
        x: -label.height + index * 34; y: label.height / 2 - 4
        width: label.width * 2; height: 8; rotation: -45
        color: Qt.rgba(1, 1, 1, 0.06)
      }
    }
    Image {
      id: img
      anchors.fill: parent
      source: cart.art
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: width * 2
      smooth: true
    }
    Rectangle {
      visible: img.status !== Image.Ready
      anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
      height: titleText.height + 18
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
      }
      Text {
        id: titleText
        x: 10; y: 9; width: parent.width - 20
        text: cart.title
        wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
        font.family: Theme.sans; font.pixelSize: Math.max(12, Math.min(16, label.width / 9)); font.weight: Font.ExtraBold
        lineHeight: 1.0
        color: "#ffffff"
      }
    }
    // glossy label sheen
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.16) }
        GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, 0.0) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
      }
    }
  }
}
