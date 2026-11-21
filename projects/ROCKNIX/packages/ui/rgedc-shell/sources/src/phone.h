// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#pragma once

#include <QLocalSocket>
#include <QObject>
#include <QTimer>
#include <QVariant>

// The phone link for QML: notifications, calls and pairing, from the
// rgedc-phone service over /run/rgedc-phone.sock (one JSON object per line).
class Phone : public QObject {
  Q_OBJECT
  // The service is running (Bluetooth on).
  Q_PROPERTY(bool available READ available NOTIFY stateChanged)
  Q_PROPERTY(bool bluetooth READ bluetooth NOTIFY stateChanged)
  Q_PROPERTY(bool connected READ connected NOTIFY stateChanged)
  Q_PROPERTY(QString kind READ kind NOTIFY stateChanged)           // "ios", "android" or ""
  Q_PROPERTY(QString name READ name NOTIFY stateChanged)
  Q_PROPERTY(QString pairing READ pairing NOTIFY stateChanged)     // "", "ios", "android"
  Q_PROPERTY(QString note READ note NOTIFY stateChanged)
  Q_PROPERTY(QString error READ error NOTIFY stateChanged)
  Q_PROPERTY(QVariantList known READ known NOTIFY stateChanged)
  Q_PROPERTY(QVariantMap music READ music NOTIFY stateChanged)
  // Quick replies set up in Gadgetbridge (Android).
  Q_PROPERTY(QStringList canned READ canned NOTIFY stateChanged)
  Q_PROPERTY(QVariantList notifications READ notifications NOTIFY notificationsChanged)
  Q_PROPERTY(int count READ count NOTIFY notificationsChanged)
  Q_PROPERTY(int unread READ unread NOTIFY notificationsChanged)
  Q_PROPERTY(QVariantMap call READ call NOTIFY callChanged)
  Q_PROPERTY(bool ringing READ ringing NOTIFY callChanged)

public:
  explicit Phone(QObject *parent = nullptr);

  bool available() const { return m_sock.state() == QLocalSocket::ConnectedState && m_haveState; }
  bool bluetooth() const { return m_state.value("bt").toBool(); }
  bool connected() const { return m_phone.value("connected").toBool(); }
  QString kind() const { return m_phone.value("kind").toString(); }
  QString name() const { return m_phone.value("name").toString(); }
  QString pairing() const { return m_state.value("pairing").toString(); }
  QString note() const { return m_state.value("note").toString(); }
  QString error() const { return m_state.value("adv").toString(); }
  QVariantList known() const { return m_state.value("known").toList(); }
  QVariantMap music() const { return m_state.value("music").toMap(); }
  QStringList canned() const { return m_state.value("canned").toStringList(); }
  QVariantList notifications() const { return m_items; }
  int count() const { return m_items.size(); }
  int unread() const;
  QVariantMap call() const { return m_call; }
  bool ringing() const { return !m_call.isEmpty(); }

  Q_INVOKABLE void dismiss(const QString &id);
  Q_INVOKABLE void act(const QString &id, bool positive);
  Q_INVOKABLE void answer(bool accept) { act(QStringLiteral("call"), accept); }
  Q_INVOKABLE void clearAll();
  Q_INVOKABLE void markAllRead();
  Q_INVOKABLE void startPairing(const QString &kind);
  Q_INVOKABLE void stopPairing() { startPairing(QString()); }
  Q_INVOKABLE void forget();
  Q_INVOKABLE void musicCommand(const QString &cmd);
  // Android only: ANCS gives accessories no way to reply.
  Q_INVOKABLE void reply(const QString &id, const QString &text);

signals:
  void stateChanged();
  void notificationsChanged();
  void callChanged();
  // A new notification worth a banner.
  void posted(const QVariantMap &item);
  void replied(const QString &id, bool ok);

private:
  void connectNow();
  void onLine(const QByteArray &line);
  void send(const QVariantMap &obj);

  QLocalSocket m_sock;
  QTimer m_retry;
  QByteArray m_buf;
  bool m_haveState = false;
  QVariantMap m_state;
  QVariantMap m_phone;
  QVariantList m_items;
  QVariantMap m_call;
};
