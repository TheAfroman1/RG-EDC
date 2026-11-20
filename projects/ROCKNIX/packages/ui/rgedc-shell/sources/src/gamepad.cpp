// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#include "gamepad.h"

#include <SDL.h>
#include <QFile>

namespace {
// Synthetic codes for the analog parts, after SDL's own button numbers.
enum : int {
  kStickUp = 100, kStickDown, kStickLeft, kStickRight,
  kTriggerLeft, kTriggerRight,
};

class Worker : public QObject {
  Q_OBJECT
public:
  std::atomic<bool> stop{false};

signals:
  void raw(int button, bool down);
  void connected(bool c, QString guid);

public slots:
  void run() {
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    if (SDL_Init(SDL_INIT_GAMECONTROLLER | SDL_INIT_EVENTS) != 0) {
      qWarning("rgedc-shell: SDL_Init failed: %s", SDL_GetError());
      return;
    }
    for (const char *db : {"/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt",
                           "/usr/config/SDL-GameControllerDB/gamecontrollerdb.txt"}) {
      if (QFile::exists(db))
        SDL_GameControllerAddMappingsFromFile(db);
    }
    SDL_GameController *pad = nullptr;
    int stickX = 0, stickY = 0;   // -1, 0, 1
    bool trigL = false, trigR = false;
    const int dead = 16000;

    auto open = [&]() {
      for (int i = 0; i < SDL_NumJoysticks() && !pad; ++i) {
        if (SDL_IsGameController(i)) {
          pad = SDL_GameControllerOpen(i);
          if (pad) {
            char guid[64] = {0};
            SDL_JoystickGetGUIDString(SDL_JoystickGetGUID(SDL_GameControllerGetJoystick(pad)),
                                      guid, sizeof guid);
            emit connected(true, QString::fromLatin1(guid));
          }
        }
      }
    };
    open();

    while (!stop) {
      SDL_Event e;
      if (!SDL_WaitEventTimeout(&e, 100))
        continue;
      switch (e.type) {
      case SDL_CONTROLLERDEVICEADDED:
        if (!pad) open();
        break;
      case SDL_CONTROLLERDEVICEREMOVED:
        if (pad && e.cdevice.which ==
                       SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(pad))) {
          SDL_GameControllerClose(pad);
          pad = nullptr;
          emit connected(false, QString());
          open();
        }
        break;
      case SDL_CONTROLLERBUTTONDOWN:
      case SDL_CONTROLLERBUTTONUP:
        emit raw(e.cbutton.button, e.type == SDL_CONTROLLERBUTTONDOWN);
        break;
      case SDL_CONTROLLERAXISMOTION: {
        const int v = e.caxis.value;
        if (e.caxis.axis == SDL_CONTROLLER_AXIS_LEFTX) {
          int nx = v < -dead ? -1 : v > dead ? 1 : 0;
          if (nx != stickX) {
            if (stickX) emit raw(stickX < 0 ? kStickLeft : kStickRight, false);
            if (nx) emit raw(nx < 0 ? kStickLeft : kStickRight, true);
            stickX = nx;
          }
        } else if (e.caxis.axis == SDL_CONTROLLER_AXIS_LEFTY) {
          int ny = v < -dead ? -1 : v > dead ? 1 : 0;
          if (ny != stickY) {
            if (stickY) emit raw(stickY < 0 ? kStickUp : kStickDown, false);
            if (ny) emit raw(ny < 0 ? kStickUp : kStickDown, true);
            stickY = ny;
          }
        } else if (e.caxis.axis == SDL_CONTROLLER_AXIS_TRIGGERLEFT) {
          bool on = v > dead;
          if (on != trigL) { trigL = on; emit raw(kTriggerLeft, on); }
        } else if (e.caxis.axis == SDL_CONTROLLER_AXIS_TRIGGERRIGHT) {
          bool on = v > dead;
          if (on != trigR) { trigR = on; emit raw(kTriggerRight, on); }
        }
        break;
      }
      default:
        break;
      }
    }
    if (pad) SDL_GameControllerClose(pad);
    SDL_Quit();
  }
};
} // namespace

Gamepad::Gamepad(QObject *parent) : QObject(parent) {
  auto *w = new Worker;
  m_worker = w;
  w->moveToThread(&m_thread);
  connect(&m_thread, &QThread::started, w, &Worker::run);
  connect(&m_thread, &QThread::finished, w, &QObject::deleteLater);
  connect(w, &Worker::raw, this, &Gamepad::onRaw, Qt::QueuedConnection);
  connect(w, &Worker::connected, this, &Gamepad::onConnected, Qt::QueuedConnection);
  m_repeat.setSingleShot(false);
  connect(&m_repeat, &QTimer::timeout, this, &Gamepad::onRepeat);
  m_thread.start();
}

Gamepad::~Gamepad() {
  static_cast<Worker *>(m_worker)->stop = true;
  m_thread.quit();
  m_thread.wait(1000);
}

void Gamepad::setPaused(bool p) {
  if (p == m_paused) return;
  m_paused = p;
  m_repeat.stop();
  m_held.clear();
  emit pausedChanged();
}

void Gamepad::setNintendoLayout(bool n) {
  if (n == m_nintendo) return;
  m_nintendo = n;
  emit nintendoLayoutChanged();
}

QString Gamepad::nameFor(int b) const {
  switch (b) {
  // SDL names buttons by position: A south, B east, X west, Y north.
  case SDL_CONTROLLER_BUTTON_A: return m_nintendo ? "b" : "a";
  case SDL_CONTROLLER_BUTTON_B: return m_nintendo ? "a" : "b";
  case SDL_CONTROLLER_BUTTON_X: return m_nintendo ? "y" : "x";
  case SDL_CONTROLLER_BUTTON_Y: return m_nintendo ? "x" : "y";
  case SDL_CONTROLLER_BUTTON_BACK: return "select";
  case SDL_CONTROLLER_BUTTON_GUIDE: return "guide";
  case SDL_CONTROLLER_BUTTON_START: return "start";
  case SDL_CONTROLLER_BUTTON_LEFTSHOULDER: return "l1";
  case SDL_CONTROLLER_BUTTON_RIGHTSHOULDER: return "r1";
  case SDL_CONTROLLER_BUTTON_DPAD_UP: case kStickUp: return "up";
  case SDL_CONTROLLER_BUTTON_DPAD_DOWN: case kStickDown: return "down";
  case SDL_CONTROLLER_BUTTON_DPAD_LEFT: case kStickLeft: return "left";
  case SDL_CONTROLLER_BUTTON_DPAD_RIGHT: case kStickRight: return "right";
  case kTriggerLeft: return "l2";
  case kTriggerRight: return "r2";
  default: return QString();
  }
}

void Gamepad::onRaw(int button, bool down) {
  const QString n = nameFor(button);
  if (!n.isEmpty()) inject(n, down);
}

void Gamepad::inject(const QString &n, bool down) {
  if (m_paused) return;
  const bool dir = n == "up" || n == "down" || n == "left" || n == "right";
  if (down) {
    emit pressed(n);
    if (dir) {
      m_held = n;
      m_repeat.start(380);
    }
  } else {
    emit released(n);
    if (n == m_held) {
      m_repeat.stop();
      m_held.clear();
    }
  }
}

void Gamepad::onRepeat() {
  if (m_held.isEmpty() || m_paused) { m_repeat.stop(); return; }
  m_repeat.setInterval(85);
  emit pressed(m_held);
}

void Gamepad::onConnected(bool c, const QString &guid) {
  m_connected = c;
  m_guid = guid;
  emit connectedChanged();
}

#include "gamepad.moc"
