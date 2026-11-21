// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
//
// RG EDC shell: the first screen the RG Rotate boots into. Watch faces, the
// home menu, music, cartridge shelves for every system, settings, and the
// flipped-screen visualizer. The QML lives in /usr/share/rgedc-shell/qml so it
// can be tweaked on the device without a rebuild.
#include <QDir>
#include <QFileInfo>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>

#include "gamepad.h"
#include "library.h"
#include "phone.h"
#include "spectrum.h"
#include "system.h"

namespace {
QString findDir(const char *envVar, const QString &rel) {
  const QString env = qEnvironmentVariable(envVar);
  if (!env.isEmpty()) return env;
  const QString installed =
      QCoreApplication::applicationDirPath() + "/../share/rgedc-shell/" + rel;
  if (QFileInfo::exists(installed)) return QDir::cleanPath(installed);
#ifdef RGEDC_SOURCE_DIR
  return QStringLiteral(RGEDC_SOURCE_DIR "/") + rel;
#else
  return installed;
#endif
}
} // namespace

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);
  app.setApplicationName("rgedc-shell");
  app.setOrganizationName("rgedc");

  const QString fonts = findDir("RGEDC_FONTS", "fonts");
  for (const QString &f : QDir(fonts).entryList({"*.ttf", "*.otf"}))
    if (QFontDatabase::addApplicationFont(fonts + "/" + f) < 0)
      qWarning("rgedc-shell: could not load font %s", qPrintable(f));
  QFont base("Archivo");
  base.setPixelSize(16);
  app.setFont(base);

  System sys;
  Library lib;
  Gamepad pad;
  Spectrum spec;
  Phone phone;
  qmlRegisterSingletonInstance("RgEdc", 1, 0, "System", &sys);
  qmlRegisterSingletonInstance("RgEdc", 1, 0, "Library", &lib);
  qmlRegisterSingletonInstance("RgEdc", 1, 0, "Gamepad", &pad);
  qmlRegisterSingletonInstance("RgEdc", 1, 0, "Spectrum", &spec);
  qmlRegisterSingletonInstance("RgEdc", 1, 0, "Phone", &phone);

  QQmlApplicationEngine engine;
  const QString qml = findDir("RGEDC_QML", "qml");
  QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                   []() { QCoreApplication::exit(1); }, Qt::QueuedConnection);
  engine.load(QUrl::fromLocalFile(qml + "/Main.qml"));
  return app.exec();
}
