// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#include "phone.h"

#include <QJsonDocument>
#include <QJsonObject>

namespace {
QString socketPath() {
  const QString env = qEnvironmentVariable("RGEDC_PHONE_SOCK");
  return env.isEmpty() ? QStringLiteral("/run/rgedc-phone.sock") : env;
}
} // namespace

Phone::Phone(QObject *parent) : QObject(parent) {
  // The service starts and stops with Bluetooth, so keep knocking.
  m_retry.setInterval(3000);
  m_retry.setSingleShot(true);
  connect(&m_retry, &QTimer::timeout, this, &Phone::connectNow);

  connect(&m_sock, &QLocalSocket::readyRead, this, [this]() {
    m_buf += m_sock.readAll();
    int nl;
    while ((nl = m_buf.indexOf('\n')) >= 0) {
      const QByteArray line = m_buf.left(nl);
      m_buf.remove(0, nl + 1);
      if (!line.trimmed().isEmpty()) onLine(line);
    }
  });
  connect(&m_sock, &QLocalSocket::disconnected, this, [this]() {
    m_haveState = false;
    m_buf.clear();
    m_state.clear();
    m_phone.clear();
    if (!m_call.isEmpty()) {
      m_call.clear();
      emit callChanged();
    }
    emit stateChanged();
    m_retry.start();
  });
  connect(&m_sock, &QLocalSocket::errorOccurred, this, [this](QLocalSocket::LocalSocketError) {
    if (m_sock.state() != QLocalSocket::ConnectedState) m_retry.start();
  });
  connectNow();
}

void Phone::connectNow() {
  if (m_sock.state() != QLocalSocket::UnconnectedState) return;
  m_sock.connectToServer(socketPath());
}

void Phone::onLine(const QByteArray &line) {
  const QJsonDocument doc = QJsonDocument::fromJson(line);
  if (!doc.isObject()) return;
  const QVariantMap m = doc.object().toVariantMap();
  const QString t = m.value("t").toString();
  if (t == "state") {
    m_state = m;
    m_phone = m.value("phone").toMap();
    m_haveState = true;
    emit stateChanged();
  } else if (t == "list") {
    m_items = m.value("items").toList();
    emit notificationsChanged();
  } else if (t == "posted") {
    emit posted(m.value("item").toMap());
  } else if (t == "call") {
    m_call = m.value("call").toMap();
    emit callChanged();
  }
}

void Phone::send(const QVariantMap &obj) {
  if (m_sock.state() != QLocalSocket::ConnectedState) return;
  m_sock.write(QJsonDocument(QJsonObject::fromVariantMap(obj)).toJson(QJsonDocument::Compact) + '\n');
  m_sock.flush();
}

int Phone::unread() const {
  int n = 0;
  for (const QVariant &v : m_items)
    if (!v.toMap().value("read").toBool()) ++n;
  return n;
}

void Phone::dismiss(const QString &id) { send({{"t", "dismiss"}, {"id", id}}); }
void Phone::act(const QString &id, bool positive) {
  send({{"t", "action"}, {"id", id}, {"positive", positive}});
}
void Phone::clearAll() { send({{"t", "clear"}}); }
void Phone::markAllRead() {
  if (unread() > 0) send({{"t", "read"}});
}
void Phone::startPairing(const QString &kind) { send({{"t", "pair"}, {"kind", kind}}); }
void Phone::forget() { send({{"t", "forget"}}); }
void Phone::musicCommand(const QString &cmd) { send({{"t", "music"}, {"cmd", cmd}}); }
