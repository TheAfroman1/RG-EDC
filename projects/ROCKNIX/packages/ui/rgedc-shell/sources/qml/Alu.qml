// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
import QtQuick
import "."

// Linear brushed aluminum (hands, bars, buttons).
Rectangle {
  gradient: Gradient {
    GradientStop { position: 0.0; color: "#eef0f2" }
    GradientStop { position: 0.55; color: "#aeb2b8" }
    GradientStop { position: 1.0; color: "#d6d9dd" }
  }
}
