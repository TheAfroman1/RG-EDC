// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#pragma once

#include <QObject>
#include <QHash>
#include <QString>
#include <QThread>
#include <QTimer>
#include <atomic>

// Reads the RG Rotate's buttons (InputPlumber's virtual pad, or any pad SDL2
// knows) and turns them into named button presses for QML:
//   a b x y up down left right l1 r1 l2 r2 start select guide
// "a" is the confirm button and "b" the back button. With the Nintendo layout
// (the RG Rotate's printing, and the default) confirm is the east face button.
// D-pad and left stick presses auto-repeat while held.
class Gamepad : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
  Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)
  Q_PROPERTY(bool nintendoLayout READ nintendoLayout WRITE setNintendoLayout NOTIFY nintendoLayoutChanged)
  Q_PROPERTY(QString guid READ guid NOTIFY connectedChanged)

public:
  explicit Gamepad(QObject *parent = nullptr);
  ~Gamepad() override;

  bool connected() const { return m_connected; }
  bool paused() const { return m_paused; }
  void setPaused(bool p);
  bool nintendoLayout() const { return m_nintendo; }
  void setNintendoLayout(bool n);
  QString guid() const { return m_guid; }

  // Keyboard fallback (desktop testing): feed the same names in.
  Q_INVOKABLE void inject(const QString &name, bool pressed);

signals:
  void pressed(const QString &name);
  void released(const QString &name);
  void connectedChanged();
  void pausedChanged();
  void nintendoLayoutChanged();

private slots:
  void onRaw(int button, bool down);
  void onConnected(bool c, const QString &guid);
  void onRepeat();

private:
  QString nameFor(int button) const;
  QThread m_thread;
  QObject *m_worker = nullptr;
  bool m_connected = false;
  bool m_paused = false;
  bool m_nintendo = true;
  QString m_guid;
  QTimer m_repeat;
  QString m_held;
};
