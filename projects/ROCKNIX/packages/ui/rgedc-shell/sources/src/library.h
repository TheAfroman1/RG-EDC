// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#pragma once

#include <QHash>
#include <QObject>
#include <QVariant>

// The game and music library. Systems come from EmulationStation's
// es_systems.cfg (so every system ROCKNIX ships is covered), games from the
// ROM folders, names and box/label art from scraped gamelist.xml files.
class Library : public QObject {
  Q_OBJECT
  Q_PROPERTY(QVariantList systems READ systems NOTIFY systemsChanged)
  Q_PROPERTY(QVariantList tracks READ tracks NOTIFY tracksChanged)
  Q_PROPERTY(QVariantList recents READ recents NOTIFY recentsChanged)

public:
  explicit Library(QObject *parent = nullptr);

  QVariantList systems() const { return m_systemList; }
  QVariantList tracks() const { return m_tracks; }
  QVariantList recents() const { return m_recents; }

  Q_INVOKABLE void rescan();
  Q_INVOKABLE QVariantList games(const QString &system) const;
  Q_INVOKABLE QVariantMap system(const QString &name) const;
  // {program, args, env} that starts this game, for System.launch().
  Q_INVOKABLE QVariantMap launchSpec(const QString &system, const QString &path,
                                     const QString &padGuid, bool viaSlot) const;
  Q_INVOKABLE void addRecent(const QString &system, const QString &path);
  Q_INVOKABLE void toggleFavorite(const QString &system, const QString &path);
  Q_INVOKABLE bool isFavorite(const QString &path) const;

signals:
  void systemsChanged();
  void tracksChanged();
  void recentsChanged();

private:
  struct System {
    QString name, fullname, manufacturer, hardware, path, command, platform;
    int year = 0;
    QStringList extensions;
    QString emulator, core;
    QVariantList games;
  };
  void loadSystems();
  void scanGames(System &s);
  void scanMusic();
  void loadRecents();
  void saveRecents();
  QVariantMap gameEntry(const QString &system, const QString &path) const;

  QHash<QString, System> m_systems;
  QVariantList m_systemList;
  QVariantList m_tracks;
  QVariantList m_recents;
  QStringList m_favorites;
};
