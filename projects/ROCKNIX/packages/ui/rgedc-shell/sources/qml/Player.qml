// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
pragma Singleton
import QtQuick
import QtMultimedia
import RgEdc 1.0

// The music player, shared by Music, the watch faces, Home and the visualizer.
QtObject {
  id: p
  property var queue: []
  property int index: -1
  readonly property var current: index >= 0 && index < queue.length ? queue[index] : null
  readonly property string title: current ? current.title : ""
  readonly property string artist: current ? current.artist : ""
  readonly property string album: current ? current.album : ""
  readonly property string format: current ? current.format : ""
  readonly property string cover: current ? current.cover : ""
  // RGEDC_NOAUDIO: pretend to play (screenshots on machines without audio).
  readonly property bool fake: System.env("RGEDC_NOAUDIO") !== ""
  property bool fakePlaying: false
  readonly property bool playing: fake ? fakePlaying : media.playbackState === MediaPlayer.PlayingState
  readonly property bool hasTrack: current !== null
  readonly property real position: media.position
  readonly property real duration: media.duration
  readonly property var media: MediaPlayer {
    audioOutput: AudioOutput { volume: 1.0 }
    onMediaStatusChanged: if (mediaStatus === MediaPlayer.EndOfMedia) p.next()
    onErrorOccurred: (e, s) => console.warn("rgedc-shell: player:", s)
  }

  function playQueue(list, i) {
    queue = list
    playIndex(i)
  }
  function playIndex(i) {
    if (i < 0 || i >= queue.length) return
    index = i
    if (fake) { fakePlaying = true; return }
    media.source = queue[i].url
    media.play()
  }
  function toggle() {
    if (!hasTrack) {
      if (Library.tracks.length) playQueue(Library.tracks, 0)
      return
    }
    if (fake) fakePlaying = !fakePlaying
    else if (playing) media.pause(); else media.play()
  }
  function next() { if (queue.length) playIndex((index + 1) % queue.length) }
  function prev() {
    if (media.position > 3000) { media.position = 0; return }
    if (queue.length) playIndex((index - 1 + queue.length) % queue.length)
  }
  function seek(ms) { media.position = Math.max(0, Math.min(media.duration, media.position + ms)) }
  function stop() { media.stop() }
}
