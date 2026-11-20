// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QTimer>
#include <QVector>

class QMediaPlayer;
class QAudioBuffer;

// Frequency bars for the flipped-screen visualizer. With Qt 6.8+ it taps the
// music player's decoded audio (QAudioBufferOutput); otherwise, or while the
// player is paused, it draws a gentle idle motion.
class Spectrum : public QObject {
  Q_OBJECT
  Q_PROPERTY(QObject *player READ player WRITE setPlayer NOTIFY playerChanged)
  Q_PROPERTY(int bands READ bands WRITE setBands NOTIFY bandsChanged)
  Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
  Q_PROPERTY(QVector<qreal> levels READ levels NOTIFY levelsChanged)
  Q_PROPERTY(bool live READ live NOTIFY liveChanged)

public:
  explicit Spectrum(QObject *parent = nullptr);

  QObject *player() const;
  void setPlayer(QObject *p);
  int bands() const { return m_bands; }
  void setBands(int n);
  bool active() const { return m_active; }
  void setActive(bool a);
  QVector<qreal> levels() const { return m_levels; }
  bool live() const { return m_live; }

signals:
  void playerChanged();
  void bandsChanged();
  void activeChanged();
  void levelsChanged();
  void liveChanged();

private:
  void onBuffer(const QAudioBuffer &b);
  void tick();

  QPointer<QMediaPlayer> m_player;
  QObject *m_tap = nullptr;
  int m_bands = 72;
  bool m_active = false;
  bool m_live = false;
  QVector<float> m_ring;     // mono samples
  int m_rate = 48000;
  QVector<qreal> m_levels;
  QVector<qreal> m_target;
  QTimer m_timer;
  QElapsedTimer m_lastBuffer;
  qint64 m_frame = 0;
};
