// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#include "library.h"

#include <QCollator>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSet>
#include <QXmlStreamReader>
#include <algorithm>

namespace {
QString rocknixRoot() {
  // RGEDC_ROOT lets the shell run against a copy of /storage on a desktop.
  return qEnvironmentVariable("RGEDC_ROOT");
}
QString rooted(const QString &p) { return rocknixRoot() + p; }

const QSet<QString> kSkipSystems = {
    "tools", "ports", "imageviewer", "mplayer", "music", "savestates", "screenshots",
    "favorites", "recordings", "recent", "collections", "bios", "moonlight", "steam",
};

const QSet<QString> kSlotSystems = {"gb", "gbc", "gba"};

// Which cartridge or disc the Games shelf draws for a system.
QString mediaKind(const QString &n) {
  static const QHash<QString, QString> k = {
      {"gb", "gb"}, {"gbh", "gb"}, {"gbc", "gbc"}, {"gbch", "gbc"}, {"gba", "gba"},
      {"nes", "nes"}, {"nesh", "nes"}, {"famicom", "famicom"}, {"fds", "fds"},
      {"snes", "snes"}, {"snesh", "snes"}, {"sfc", "sfc"}, {"satellaview", "sfc"},
      {"sufami", "sfc"}, {"snesmsu1", "snes"}, {"n64", "n64"}, {"64dd", "disc"},
      {"virtualboy", "vb"}, {"pokemini", "pokemini"},
      {"nds", "nds"}, {"3ds", "nds"},
      {"genesis", "genesis"}, {"megadrive", "megadrive"}, {"genh", "genesis"},
      {"sega32x", "s32x"}, {"mastersystem", "sms"}, {"sg-1000", "sms"},
      {"gamegear", "gamegear"}, {"ggh", "gamegear"},
      {"segacd", "disc"}, {"megacd", "disc"}, {"saturn", "disc"}, {"dreamcast", "disc"},
      {"naomi", "arcade"}, {"atomiswave", "arcade"},
      {"atari2600", "atari2600"}, {"atari5200", "atari5200"}, {"atari7800", "atari7800"},
      {"atarilynx", "lynx"}, {"atarijaguar", "jaguar"}, {"atarist", "floppy"},
      {"atari800", "atari5200"}, {"colecovision", "coleco"}, {"intellivision", "intv"},
      {"odyssey2", "odyssey"}, {"vectrex", "vectrex"}, {"channelf", "channelf"},
      {"pcengine", "hucard"}, {"tg16", "hucard"}, {"supergrafx", "hucard"},
      {"pcenginecd", "disc"}, {"tg16cd", "disc"}, {"pcfx", "disc"},
      {"neogeo", "mvs"}, {"neogeocd", "disc"}, {"ngp", "ngp"}, {"ngpc", "ngp"},
      {"wonderswan", "ws"}, {"wonderswancolor", "ws"},
      {"psx", "disc"}, {"ps2", "disc"}, {"psp", "umd"}, {"pspminis", "umd"},
      {"3do", "disc"}, {"cdi", "disc"}, {"amigacd32", "disc"}, {"cdtv", "disc"},
      {"arcade", "arcade"}, {"mame", "arcade"}, {"fbneo", "arcade"}, {"cps1", "arcade"},
      {"cps2", "arcade"}, {"cps3", "arcade"}, {"hbmame", "arcade"},
      {"amiga", "floppy"}, {"c64", "floppy"}, {"msx", "msx"}, {"msx2", "msx"},
      {"zxspectrum", "tape"}, {"amstradcpc", "floppy"}, {"x68000", "floppy"},
      {"pc", "floppy"}, {"dos", "floppy"}, {"scummvm", "floppy"}, {"pc98", "floppy"},
  };
  return k.value(n, "cart");
}

QString shellQuote(const QString &s) {
  QString q = s;
  q.replace('\'', "'\\''");
  return '\'' + q + '\'';
}

// "03 - Clair de Lune.flac" -> "Clair de Lune"
QString titleFromFile(const QString &base) {
  static const QRegularExpression lead(R"(^\s*(\d{1,3}[\s.\-_]+)+)");
  QString t = base;
  t.remove(lead);
  return t.isEmpty() ? base : t;
}

// "Super Metroid (USA, Europe) [!]" -> "Super Metroid"
QString cleanRomName(const QString &base) {
  static const QRegularExpression tags(R"(\s*[\(\[][^\)\]]*[\)\]])");
  QString t = base;
  t.remove(tags);
  t = t.trimmed();
  return t.isEmpty() ? base : t;
}

QString recentsPath() {
  return QFile::exists("/usr/bin/runemu.sh")
             ? "/storage/.config/rgedc/library.json"
             : QDir::homePath() + "/.config/rgedc/library.json";
}
} // namespace

Library::Library(QObject *parent) : QObject(parent) {
  loadRecents();
}

void Library::rescan() {
  loadSystems();
  scanMusic();
}

void Library::loadSystems() {
  m_systems.clear();
  QString cfg = rooted("/storage/.config/emulationstation/es_systems.cfg");
  if (!QFile::exists(cfg)) cfg = rooted("/usr/config/emulationstation/es_systems.cfg");
  if (!QFile::exists(cfg)) cfg = qEnvironmentVariable("RGEDC_ES_SYSTEMS");
  QFile f(cfg);
  if (!f.open(QIODevice::ReadOnly)) {
    qWarning("rgedc-shell: no es_systems.cfg");
  }
  // ROCKNIX keeps per-system emulator/core choices in system.cfg.
  QHash<QString, QString> cfgVals;
  QFile sc(rooted("/storage/.config/system/configs/system.cfg"));
  if (sc.open(QIODevice::ReadOnly)) {
    while (!sc.atEnd()) {
      const QString l = QString::fromUtf8(sc.readLine()).trimmed();
      const int eq = l.indexOf('=');
      if (eq > 0 && !l.startsWith('#')) cfgVals.insert(l.left(eq), l.mid(eq + 1));
    }
  }

  QXmlStreamReader x(&f);
  System cur;
  QString emu;
  bool inSystem = false;
  while (!x.atEnd() && f.isOpen()) {
    x.readNext();
    if (x.isStartElement()) {
      const auto n = x.name();
      if (n == u"system") { cur = System(); inSystem = true; }
      else if (!inSystem) continue;
      else if (n == u"name") cur.name = x.readElementText().trimmed();
      else if (n == u"fullname") cur.fullname = x.readElementText().trimmed();
      else if (n == u"manufacturer") cur.manufacturer = x.readElementText().trimmed();
      else if (n == u"release") cur.year = x.readElementText().trimmed().left(4).toInt();
      else if (n == u"hardware") cur.hardware = x.readElementText().trimmed();
      else if (n == u"path") cur.path = x.readElementText().trimmed();
      else if (n == u"command") cur.command = x.readElementText().trimmed();
      else if (n == u"platform") cur.platform = x.readElementText().trimmed();
      else if (n == u"extension")
        cur.extensions = x.readElementText().toLower().split(QRegularExpression("[\\s,]+"),
                                                            Qt::SkipEmptyParts);
      else if (n == u"emulator") emu = x.attributes().value("name").toString();
      else if (n == u"core") {
        const bool def = x.attributes().value("default") == u"true";
        const QString core = x.readElementText().trimmed();
        if (cur.emulator.isEmpty() || def) { cur.emulator = emu; cur.core = core; }
      }
    } else if (x.isEndElement() && x.name() == u"system") {
      inSystem = false;
      if (cur.name.isEmpty() || kSkipSystems.contains(cur.name)) continue;
      if (!cur.command.contains("runemu")) continue;
      cur.emulator = cfgVals.value(cur.name + ".emulator", cur.emulator);
      cur.core = cfgVals.value(cur.name + ".core", cur.core);
      scanGames(cur);
      if (!cur.games.isEmpty()) m_systems.insert(cur.name, cur);
    }
  }

  // Oldest hardware first: 70s consoles through PlayStation and Saturn.
  QList<const System *> order;
  for (const auto &s : m_systems) order << &s;
  std::sort(order.begin(), order.end(), [](const System *a, const System *b) {
    if (a->year != b->year) return (a->year ? a->year : 9999) < (b->year ? b->year : 9999);
    return a->name < b->name;
  });
  m_systemList.clear();
  for (const System *s : order) {
    m_systemList << QVariantMap{
        {"name", s->name}, {"fullname", s->fullname}, {"manufacturer", s->manufacturer},
        {"year", s->year}, {"hardware", s->hardware}, {"kind", mediaKind(s->name)},
        {"count", s->games.size()}, {"slot", kSlotSystems.contains(s->name)},
    };
  }
  emit systemsChanged();
}

void Library::scanGames(System &s) {
  const QString dir = rooted(s.path);
  if (!QFileInfo(dir).isDir()) return;

  // Scraped metadata: <game><path>./x.zip</path><name/><image/><thumbnail/>...
  QHash<QString, QVariantMap> meta;
  QFile gl(dir + "/gamelist.xml");
  if (gl.open(QIODevice::ReadOnly)) {
    QXmlStreamReader x(&gl);
    QVariantMap g;
    while (!x.atEnd()) {
      x.readNext();
      if (x.isStartElement()) {
        const QString n = x.name().toString();
        if (n == "game") g.clear();
        else if (n == "path" || n == "name" || n == "image" || n == "thumbnail" ||
                 n == "marquee" || n == "desc" || n == "releasedate" || n == "developer")
          g.insert(n, x.readElementText().trimmed());
      } else if (x.isEndElement() && x.name() == u"game") {
        const QString p = QDir::cleanPath(dir + "/" + g.value("path").toString());
        meta.insert(p, g);
      }
    }
  }
  auto art = [&](const QString &rel) -> QString {
    if (rel.isEmpty()) return {};
    const QString p = QDir::cleanPath(rel.startsWith('/') ? rel : dir + "/" + rel);
    return QFile::exists(p) ? QUrl::fromLocalFile(p).toString() : QString();
  };

  QSet<QString> extSet(s.extensions.begin(), s.extensions.end());
  QSet<QString> m3uDirs;
  QStringList files;
  QDirIterator it(dir, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
  while (it.hasNext()) {
    const QString p = it.next();
    const QString rel = p.mid(dir.size() + 1);
    if (rel.count('/') > 1) continue;  // two levels deep is enough
    const QString first = rel.section('/', 0, 0).toLower();
    if (rel.contains('/') && (first == "images" || first == "videos" || first == "manuals" ||
                              first == "media" || first == "downloaded_images"))
      continue;
    const QString ext = '.' + QFileInfo(p).suffix().toLower();
    if (!extSet.contains(ext)) continue;
    if (ext == ".m3u") m3uDirs.insert(QFileInfo(p).absolutePath());
    files << p;
  }
  // Multi-disc games: when a folder has an .m3u, show only that.
  files.erase(std::remove_if(files.begin(), files.end(),
                             [&](const QString &p) {
                               return m3uDirs.contains(QFileInfo(p).absolutePath()) &&
                                      !p.endsWith(".m3u", Qt::CaseInsensitive);
                             }),
              files.end());

  QList<QVariantMap> out;
  for (const QString &p : files) {
    const QVariantMap m = meta.value(QDir::cleanPath(p));
    QString name = m.value("name").toString();
    if (name.isEmpty()) name = cleanRomName(QFileInfo(p).completeBaseName());
    out << QVariantMap{
        {"path", p}, {"name", name}, {"system", s.name},
        {"image", art(m.value("image").toString())},
        {"thumbnail", art(m.value("thumbnail").toString())},
        {"marquee", art(m.value("marquee").toString())},
        {"developer", m.value("developer")},
        {"year", m.value("releasedate").toString().left(4)},
    };
  }
  QCollator coll;
  coll.setNumericMode(true);
  coll.setCaseSensitivity(Qt::CaseInsensitive);
  std::sort(out.begin(), out.end(), [&](const QVariantMap &a, const QVariantMap &b) {
    return coll.compare(a.value("name").toString(), b.value("name").toString()) < 0;
  });
  s.games.clear();
  for (const auto &g : out) s.games << g;
}

QVariantList Library::games(const QString &system) const {
  return m_systems.value(system).games;
}

QVariantMap Library::system(const QString &name) const {
  for (const QVariant &v : m_systemList)
    if (v.toMap().value("name") == name) return v.toMap();
  return {};
}

QVariantMap Library::launchSpec(const QString &system, const QString &path,
                                const QString &padGuid, bool viaSlot) const {
  const System s = m_systems.value(system);
  if (viaSlot && kSlotSystems.contains(system) && QFile::exists("/usr/bin/start_slot.sh")) {
    return {
        {"program", "/usr/bin/start_slot.sh"},
        {"args", QStringList{}},
        {"env", QVariantMap{{"SLOT_SHELF", system}, {"SLOT_INSERT", path},
                            {"SLOT_BACK_EXITS", "1"}}},
    };
  }
  // Same expansion EmulationStation does for <command>.
  QString cmd = s.command.isEmpty()
                    ? QStringLiteral("/usr/bin/runemu.sh %ROM% -P%SYSTEM% --core=%CORE% "
                                     "--emulator=%EMULATOR% --controllers=\"%CONTROLLERSCONFIG%\"")
                    : s.command;
  const QFileInfo fi(path);
  QString controllers;
  if (!padGuid.isEmpty())
    controllers = QStringLiteral("-p1index 0 -p1guid %1 -p1name RG-Rotate").arg(padGuid);
  cmd.replace("%ROM%", shellQuote(path));
  cmd.replace("%ROM_RAW%", path);
  cmd.replace("%BASENAME%", shellQuote(fi.completeBaseName()));
  cmd.replace("%SYSTEM%", system);
  cmd.replace("%CORE%", s.core);
  cmd.replace("%EMULATOR%", s.emulator);
  cmd.replace("%CONTROLLERSCONFIG%", controllers);
  cmd.replace("%GAMENAME%", shellQuote(fi.completeBaseName()));
  cmd.replace(QRegularExpression("%[A-Z_]+%"), QString());
  return {
      {"program", "/bin/bash"},
      {"args", QStringList{"-c", cmd}},
      {"env", QVariantMap{}},
  };
}

QVariantMap Library::gameEntry(const QString &system, const QString &path) const {
  for (const QVariant &g : m_systems.value(system).games)
    if (g.toMap().value("path") == path) return g.toMap();
  return {};
}

void Library::addRecent(const QString &system, const QString &path) {
  QVariantMap g = gameEntry(system, path);
  if (g.isEmpty()) return;
  for (int i = 0; i < m_recents.size(); ++i) {
    if (m_recents[i].toMap().value("path") == path) { m_recents.removeAt(i); break; }
  }
  m_recents.prepend(g);
  while (m_recents.size() > 20) m_recents.removeLast();
  saveRecents();
  emit recentsChanged();
}

void Library::toggleFavorite(const QString &, const QString &path) {
  if (m_favorites.contains(path)) m_favorites.removeAll(path);
  else m_favorites << path;
  saveRecents();
}

bool Library::isFavorite(const QString &path) const { return m_favorites.contains(path); }

void Library::loadRecents() {
  QFile f(recentsPath());
  if (!f.open(QIODevice::ReadOnly)) return;
  const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
  m_recents = o.value("recents").toArray().toVariantList();
  for (const auto &v : o.value("favorites").toArray()) m_favorites << v.toString();
}

void Library::saveRecents() {
  QDir().mkpath(QFileInfo(recentsPath()).absolutePath());
  QFile f(recentsPath());
  if (!f.open(QIODevice::WriteOnly)) return;
  QJsonObject o;
  o.insert("recents", QJsonArray::fromVariantList(m_recents));
  o.insert("favorites", QJsonArray::fromStringList(m_favorites));
  f.write(QJsonDocument(o).toJson());
}

void Library::scanMusic() {
  static const QSet<QString> exts = {"flac", "mp3", "ogg", "opus", "m4a", "aac", "wav", "alac", "ape", "wv"};
  QStringList roots = {rooted("/storage/music"), rooted("/storage/roms/music")};
  if (!qEnvironmentVariable("RGEDC_MUSIC").isEmpty())
    roots = {qEnvironmentVariable("RGEDC_MUSIC")};
  QList<QVariantMap> out;
  QHash<QString, QString> covers;
  auto coverFor = [&](const QString &dir) -> QString {
    if (covers.contains(dir)) return covers.value(dir);
    QString c;
    for (const char *n : {"cover.jpg", "cover.png", "folder.jpg", "folder.png", "front.jpg",
                          "Cover.jpg", "Folder.jpg", "AlbumArt.jpg", "album.jpg"}) {
      if (QFile::exists(dir + "/" + n)) { c = QUrl::fromLocalFile(dir + "/" + n).toString(); break; }
    }
    covers.insert(dir, c);
    return c;
  };
  for (const QString &root : roots) {
    if (!QFileInfo(root).isDir()) continue;
    QDirIterator it(root, QDir::Files, QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
    while (it.hasNext()) {
      const QString p = it.next();
      const QFileInfo fi(p);
      if (!exts.contains(fi.suffix().toLower())) continue;
      const QString dir = fi.absolutePath();
      const QString rel = dir.mid(root.size());
      const QStringList parts = rel.split('/', Qt::SkipEmptyParts);
      out << QVariantMap{
          {"path", p}, {"url", QUrl::fromLocalFile(p).toString()},
          {"title", titleFromFile(fi.completeBaseName())},
          {"album", parts.isEmpty() ? QString() : parts.last()},
          {"artist", parts.size() >= 2 ? parts[parts.size() - 2] : QString()},
          {"format", fi.suffix().toUpper()},
          {"cover", coverFor(dir)},
      };
    }
  }
  QCollator coll;
  coll.setNumericMode(true);
  std::sort(out.begin(), out.end(), [&](const QVariantMap &a, const QVariantMap &b) {
    return coll.compare(a.value("path").toString(), b.value("path").toString()) < 0;
  });
  m_tracks.clear();
  for (const auto &t : out) m_tracks << t;
  emit tracksChanged();
}
