// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#pragma once

#include <QObject>
#include <QProcess>
#include <QSettings>
#include <QSocketNotifier>
#include <QTimer>
#include <QVariant>

// Device state and actions for QML: battery, Wi-Fi, audio output, volume,
// brightness, the lid, settings, and running other programs (games, slot.,
// EmulationStation) while the shell waits.
class System : public QObject {
  Q_OBJECT
  Q_PROPERTY(int battery READ battery NOTIFY batteryChanged)
  Q_PROPERTY(bool charging READ charging NOTIFY batteryChanged)
  Q_PROPERTY(bool hasBattery READ hasBattery NOTIFY batteryChanged)
  Q_PROPERTY(bool wifi READ wifi NOTIFY wifiChanged)
  Q_PROPERTY(QString audioOutput READ audioOutput NOTIFY audioOutputChanged)
  Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
  Q_PROPERTY(bool lidClosed READ lidClosed NOTIFY lidClosedChanged)
  Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
  Q_PROPERTY(bool onDevice READ onDevice CONSTANT)
  Q_PROPERTY(QString version READ version CONSTANT)
  // Bumped on every setSetting(), so bindings that read settings re-run.
  Q_PROPERTY(int settingsRevision READ settingsRevision NOTIFY settingsChanged)

public:
  explicit System(QObject *parent = nullptr);
  ~System() override;

  int battery() const { return m_battery; }
  bool charging() const { return m_charging; }
  bool hasBattery() const { return m_hasBattery; }
  bool wifi() const { return m_wifi; }
  QString audioOutput() const { return m_audioOutput; }
  int volume() const { return m_volume; }
  void setVolume(int v);
  int brightness() const { return m_brightness; }
  void setBrightness(int v);
  bool lidClosed() const { return m_lidClosed; }
  bool busy() const { return m_proc != nullptr; }
  bool onDevice() const { return m_onDevice; }
  QString version() const { return m_version; }
  int settingsRevision() const { return m_settingsRev; }

  Q_INVOKABLE QVariant setting(const QString &key, const QVariant &def = {}) const;
  Q_INVOKABLE bool flag(const QString &key, bool def) const;
  Q_INVOKABLE void setSetting(const QString &key, const QVariant &value);

  // Runs a program and waits for it; the shell hides meanwhile. env adds to
  // the shell's own environment. Returns false if something is already running.
  Q_INVOKABLE bool launch(const QString &program, const QStringList &args = {},
                          const QVariantMap &env = {});
  Q_INVOKABLE void openEmulationStation();
  // Boot into EmulationStation from now on (the escape hatch), or back.
  Q_INVOKABLE void setBootToEmulationStation(bool on);
  Q_INVOKABLE void powerOff();
  Q_INVOKABLE void reboot();
  // While set, closing the lid keeps the device awake (music visualizer).
  Q_INVOKABLE void setKeepAwakeOnLid(bool on);
  Q_INVOKABLE void refresh();
  Q_INVOKABLE QString env(const QString &name) const { return qEnvironmentVariable(qPrintable(name)); }

signals:
  void batteryChanged();
  void wifiChanged();
  void audioOutputChanged();
  void volumeChanged();
  void brightnessChanged();
  void lidClosedChanged();
  void busyChanged();
  void launchFinished(int exitCode);
  void settingsChanged();

private:
  void readBattery();
  void readWifi();
  void readAudioOutput();
  void readCfg();
  void openLid();
  void onLidEvent();
  void runDetached(const QString &program, const QStringList &args);

  QSettings m_settings;
  QTimer m_poll;
  QProcess *m_proc = nullptr;
  QSocketNotifier *m_lidNotifier = nullptr;
  int m_lidFd = -1;
  int m_battery = 100;
  bool m_charging = false;
  bool m_hasBattery = false;
  bool m_wifi = false;
  QString m_audioOutput = "Speaker";
  int m_volume = 50;
  int m_brightness = 50;
  bool m_lidClosed = false;
  bool m_onDevice = false;
  QString m_version;
  int m_settingsRev = 0;
};
