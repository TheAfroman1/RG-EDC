// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#include "system.h"

#include <QDir>
#include <QFile>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QTextStream>

#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>

namespace {
const char *kBattery = "/sys/class/power_supply/battery";
const char *kSystemCfg = "/storage/.config/system/configs/system.cfg";
const char *kRunDir = "/run/rgedc";

bool onDeviceCheck() { return QFile::exists("/usr/bin/runemu.sh"); }

QString settingsPath() {
  if (onDeviceCheck())
    return "/storage/.config/rgedc/shell.ini";
  return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) +
         "/rgedc/shell.ini";
}

QString readLine(const QString &path) {
  QFile f(path);
  if (!f.open(QIODevice::ReadOnly)) return {};
  return QString::fromUtf8(f.readLine()).trimmed();
}

bool testBit(const unsigned long *bits, int bit) {
  const int w = 8 * sizeof(unsigned long);
  return (bits[bit / w] >> (bit % w)) & 1UL;
}
} // namespace

System::System(QObject *parent)
    : QObject(parent), m_settings(settingsPath(), QSettings::IniFormat) {
  m_onDevice = onDeviceCheck();
  QFile os("/etc/os-release");
  if (os.open(QIODevice::ReadOnly)) {
    while (!os.atEnd()) {
      const QString l = QString::fromUtf8(os.readLine()).trimmed();
      if (l.startsWith("VERSION="))
        m_version = l.mid(8).remove('"');
    }
  }
  refresh();
  openLid();
  m_poll.setInterval(5000);
  connect(&m_poll, &QTimer::timeout, this, &System::refresh);
  m_poll.start();
}

System::~System() {
  if (m_lidFd >= 0) ::close(m_lidFd);
}

void System::refresh() {
  readBattery();
  readWifi();
  readCfg();
  readAudioOutput();
}

void System::readBattery() {
  const QString cap = readLine(QString(kBattery) + "/capacity");
  const bool has = !cap.isEmpty();
  const int pct = has ? qBound(0, cap.toInt(), 100) : 100;
  const QString st = readLine(QString(kBattery) + "/status");
  const bool chg = st == "Charging" || st == "Full";
  if (has != m_hasBattery || pct != m_battery || chg != m_charging) {
    m_hasBattery = has;
    m_battery = pct;
    m_charging = chg;
    emit batteryChanged();
  }
}

void System::readWifi() {
  bool up = false;
  const QDir net("/sys/class/net");
  for (const QString &n : net.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
    if (QFile::exists(net.filePath(n) + "/wireless") &&
        readLine(net.filePath(n) + "/operstate") == "up")
      up = true;
  }
  if (up != m_wifi) {
    m_wifi = up;
    emit wifiChanged();
  }
}

// Volume and brightness live in ROCKNIX's system.cfg (audio.volume,
// display.brightness); its volume/brightness scripts keep them current.
void System::readCfg() {
  QFile f(kSystemCfg);
  if (!f.open(QIODevice::ReadOnly)) return;
  int vol = m_volume, bri = m_brightness;
  while (!f.atEnd()) {
    const QString l = QString::fromUtf8(f.readLine()).trimmed();
    if (l.startsWith("audio.volume=")) vol = l.mid(13).toInt();
    else if (l.startsWith("display.brightness=")) bri = l.mid(19).toInt();
  }
  if (vol != m_volume) { m_volume = vol; emit volumeChanged(); }
  if (bri != m_brightness) { m_brightness = bri; emit brightnessChanged(); }
}

void System::readAudioOutput() {
  if (!m_onDevice) return;
  auto *p = new QProcess(this);
  connect(p, &QProcess::finished, this, [this, p]() {
    const QString out = QString::fromUtf8(p->readAllStandardOutput());
    p->deleteLater();
    QString o = "Speaker";
    if (out.contains("bluez", Qt::CaseInsensitive)) o = "Bluetooth";
    else if (out.contains("usb", Qt::CaseInsensitive)) o = "USB DAC";
    else if (out.contains("hdmi", Qt::CaseInsensitive)) o = "HDMI";
    if (o != m_audioOutput) {
      m_audioOutput = o;
      emit audioOutputChanged();
    }
  });
  p->start("wpctl", {"inspect", "@DEFAULT_AUDIO_SINK@"});
}

void System::setVolume(int v) {
  v = qBound(0, v, 100);
  if (v == m_volume) return;
  m_volume = v;
  emit volumeChanged();
  if (m_onDevice) runDetached("/usr/bin/volume", {QString::number(v)});
}

void System::setBrightness(int v) {
  v = qBound(5, v, 100);
  if (v == m_brightness) return;
  m_brightness = v;
  emit brightnessChanged();
  if (m_onDevice) runDetached("/usr/bin/brightness", {"set", QString::number(v)});
}

QVariant System::setting(const QString &key, const QVariant &def) const {
  return m_settings.value(key, def);
}

bool System::flag(const QString &key, bool def) const {
  const QVariant v = m_settings.value(key);
  if (!v.isValid()) return def;
  const QString t = v.toString().toLower();
  return t == "true" || t == "1" || t == "on";
}

void System::setSetting(const QString &key, const QVariant &value) {
  m_settings.setValue(key, value);
  m_settings.sync();
  ++m_settingsRev;
  emit settingsChanged();
}

bool System::launch(const QString &program, const QStringList &args, const QVariantMap &env) {
  if (m_proc) return false;
  m_proc = new QProcess(this);
  QProcessEnvironment pe = QProcessEnvironment::systemEnvironment();
  pe.remove("PULSE_LATENCY_MSEC");  // only meant for the shell's own music
  for (auto it = env.begin(); it != env.end(); ++it)
    pe.insert(it.key(), it.value().toString());
  m_proc->setProcessEnvironment(pe);
  m_proc->setProcessChannelMode(QProcess::ForwardedChannels);
  connect(m_proc, &QProcess::finished, this, [this](int code, QProcess::ExitStatus) {
    m_proc->deleteLater();
    m_proc = nullptr;
    emit busyChanged();
    emit launchFinished(code);
    refresh();
  });
  connect(m_proc, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
    if (e != QProcess::FailedToStart) return;
    qWarning("rgedc-shell: could not start %s", qPrintable(m_proc->program()));
    m_proc->deleteLater();
    m_proc = nullptr;
    emit busyChanged();
    emit launchFinished(-1);
  });
  qInfo("rgedc-shell: launch %s %s", qPrintable(program), qPrintable(args.join(' ')));
  m_proc->start(program, args);
  emit busyChanged();
  return true;
}

void System::openEmulationStation() {
  launch("/usr/bin/start_es.sh");
}

void System::setBootToEmulationStation(bool on) {
  const QString flag = "/storage/.config/rgedc/boot_es";
  if (on) {
    QDir().mkpath("/storage/.config/rgedc");
    QFile f(flag);
    f.open(QIODevice::WriteOnly);
  } else {
    QFile::remove(flag);
  }
}

void System::powerOff() { runDetached("systemctl", {"poweroff"}); }
void System::reboot() { runDetached("systemctl", {"reboot"}); }

void System::setKeepAwakeOnLid(bool on) {
  if (!m_onDevice) return;
  const QString flag = QString(kRunDir) + "/lid-awake";
  if (on) {
    QDir().mkpath(kRunDir);
    QFile f(flag);
    f.open(QIODevice::WriteOnly);
  } else {
    QFile::remove(flag);
  }
}

void System::setDimmed(bool on) {
  if (!m_onDevice || on == m_dimmed) return;
  if (m_backlight.isEmpty()) {
    const QDir bl("/sys/class/backlight");
    const QStringList d = bl.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    if (d.isEmpty()) return;
    m_backlight = bl.filePath(d.first());
  }
  QFile f(m_backlight + "/brightness");
  if (on) {
    m_backlightSaved = readLine(m_backlight + "/brightness");
    const int max = readLine(m_backlight + "/max_brightness").toInt();
    const int low = qMax(1, max * 6 / 100);
    if (m_backlightSaved.toInt() <= low) { m_dimmed = true; return; }
    if (f.open(QIODevice::WriteOnly)) f.write(QByteArray::number(low));
  } else if (!m_backlightSaved.isEmpty()) {
    if (f.open(QIODevice::WriteOnly)) f.write(m_backlightSaved.toUtf8());
  }
  m_dimmed = on;
}

void System::sleepNow() {
  if (!m_onDevice) { qInfo("rgedc-shell: (desktop) sleep"); return; }
  setDimmed(false);
  // input_sense skipped the lid-close sleep for us; let the lid-open event
  // wake the device normally.
  QFile::remove(QString(kRunDir) + "/lid-skipped");
  runDetached("/usr/bin/rocknix-fake-suspend", {"lid", "close"});
}

void System::simulateLid(bool closed) {
  if (m_onDevice || closed == m_lidClosed) return;
  m_lidClosed = closed;
  emit lidClosedChanged();
}

void System::runDetached(const QString &program, const QStringList &args) {
  QProcess::startDetached(program, args);
}

// The lid is an EV_SW/SW_LID switch on one of the input devices. Read it
// without grabbing, so input_sense still sees it too.
void System::openLid() {
  const QDir dev("/dev/input");
  for (const QString &n : dev.entryList({"event*"}, QDir::System)) {
    const int fd = ::open(qPrintable(dev.filePath(n)), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) continue;
    unsigned long sw[(SW_MAX + 8 * sizeof(long)) / (8 * sizeof(long))] = {0};
    if (ioctl(fd, EVIOCGBIT(EV_SW, sizeof sw), sw) >= 0 && testBit(sw, SW_LID)) {
      unsigned long state[sizeof sw / sizeof(long)] = {0};
      if (ioctl(fd, EVIOCGSW(sizeof state), state) >= 0)
        m_lidClosed = testBit(state, SW_LID);
      m_lidFd = fd;
      m_lidNotifier = new QSocketNotifier(fd, QSocketNotifier::Read, this);
      connect(m_lidNotifier, &QSocketNotifier::activated, this, &System::onLidEvent);
      qInfo("rgedc-shell: lid switch on %s, %s", qPrintable(n), m_lidClosed ? "closed" : "open");
      return;
    }
    ::close(fd);
  }
}

void System::onLidEvent() {
  input_event ev[16];
  for (;;) {
    const ssize_t r = ::read(m_lidFd, ev, sizeof ev);
    if (r <= 0) break;
    for (size_t i = 0; i < size_t(r) / sizeof(input_event); ++i) {
      if (ev[i].type == EV_SW && ev[i].code == SW_LID) {
        const bool c = ev[i].value != 0;
        if (c != m_lidClosed) {
          m_lidClosed = c;
          emit lidClosedChanged();
        }
      }
    }
  }
}
