// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
pragma Singleton
import QtQuick

// One shared clock that ticks every second.
QtObject {
  property date now: new Date()
  readonly property int h: now.getHours()
  readonly property int m: now.getMinutes()
  readonly property int s: now.getSeconds()
  readonly property int h12: (h % 12) || 12
  readonly property var days: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  readonly property var longDays: ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
  readonly property var months: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
  readonly property string dow: days[now.getDay()]
  readonly property string longDow: longDays[now.getDay()]
  readonly property string mon: months[now.getMonth()]
  readonly property int day: now.getDate()
  readonly property string hm: h12 + ":" + pad(m)
  function pad(v) { return (v < 10 ? "0" : "") + v }
  property var timer: Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: now = new Date()
  }
}
