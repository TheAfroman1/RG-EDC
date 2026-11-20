// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2026-present RG EDC
#include "spectrum.h"

#include <QAudioBuffer>
#include <QMediaPlayer>
#include <QtGlobal>
#include <cmath>
#include <complex>

#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QAudioBufferOutput>
#define RGEDC_HAVE_TAP 1
#endif

namespace {
constexpr int kFft = 1024;

void fft(std::vector<std::complex<float>> &a) {
  const size_t n = a.size();
  for (size_t i = 1, j = 0; i < n; ++i) {
    size_t bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) std::swap(a[i], a[j]);
  }
  for (size_t len = 2; len <= n; len <<= 1) {
    const float ang = -2.f * float(M_PI) / float(len);
    const std::complex<float> wl(std::cos(ang), std::sin(ang));
    for (size_t i = 0; i < n; i += len) {
      std::complex<float> w(1.f, 0.f);
      for (size_t k = 0; k < len / 2; ++k) {
        const auto u = a[i + k], v = a[i + k + len / 2] * w;
        a[i + k] = u + v;
        a[i + k + len / 2] = u - v;
        w *= wl;
      }
    }
  }
}
} // namespace

Spectrum::Spectrum(QObject *parent) : QObject(parent) {
  m_levels.fill(0.0, m_bands);
  m_target.fill(0.0, m_bands);
  m_timer.setInterval(33);
  connect(&m_timer, &QTimer::timeout, this, &Spectrum::tick);
}

QObject *Spectrum::player() const { return m_player; }

void Spectrum::setPlayer(QObject *p) {
  auto *mp = qobject_cast<QMediaPlayer *>(p);
  if (mp == m_player) return;
  m_player = mp;
#ifdef RGEDC_HAVE_TAP
  if (mp) {
    auto *tap = new QAudioBufferOutput(this);
    connect(tap, &QAudioBufferOutput::audioBufferReceived, this, &Spectrum::onBuffer);
    mp->setAudioBufferOutput(tap);
    m_tap = tap;
  }
#endif
  emit playerChanged();
}

void Spectrum::setBands(int n) {
  n = qBound(8, n, 256);
  if (n == m_bands) return;
  m_bands = n;
  m_levels.fill(0.0, n);
  m_target.fill(0.0, n);
  emit bandsChanged();
  emit levelsChanged();
}

void Spectrum::setActive(bool a) {
  if (a == m_active) return;
  m_active = a;
  if (a) m_timer.start(); else m_timer.stop();
  emit activeChanged();
}

void Spectrum::onBuffer(const QAudioBuffer &b) {
  if (!m_active || !b.isValid()) return;
  const QAudioFormat f = b.format();
  m_rate = f.sampleRate();
  const int ch = qMax(1, f.channelCount());
  const int bpf = f.bytesPerFrame();
  const char *d = b.constData<char>();
  const int frames = b.frameCount();
  for (int i = 0; i < frames; ++i) {
    float s = 0;
    for (int c = 0; c < ch; ++c)
      s += f.normalizedSampleValue(d + i * bpf + c * f.bytesPerSample());
    m_ring.append(s / ch);
  }
  if (m_ring.size() > kFft * 2) m_ring.remove(0, m_ring.size() - kFft);
  m_lastBuffer.start();
  if (m_ring.size() < kFft) return;

  std::vector<std::complex<float>> a(kFft);
  const int off = m_ring.size() - kFft;
  for (int i = 0; i < kFft; ++i) {
    const float w = 0.5f - 0.5f * std::cos(2.f * float(M_PI) * i / (kFft - 1));
    a[i] = {m_ring[off + i] * w, 0.f};
  }
  fft(a);
  // Log-spaced bands from 40 Hz to 16 kHz, in dB mapped to 0..1.
  const double lo = std::log(40.0), hi = std::log(16000.0);
  const double binHz = double(m_rate) / kFft;
  for (int bnd = 0; bnd < m_bands; ++bnd) {
    const double f0 = std::exp(lo + (hi - lo) * bnd / m_bands);
    const double f1 = std::exp(lo + (hi - lo) * (bnd + 1) / m_bands);
    int b0 = qBound(1, int(f0 / binHz), kFft / 2 - 1);
    int b1 = qBound(b0 + 1, int(f1 / binHz) + 1, kFft / 2);
    double peak = 0;
    for (int k = b0; k < b1; ++k) peak = std::max(peak, double(std::abs(a[k])));
    const double db = 20.0 * std::log10(peak / (kFft / 4) + 1e-9);
    m_target[bnd] = qBound(0.0, (db + 60.0) / 60.0, 1.0);
  }
  if (!m_live) { m_live = true; emit liveChanged(); }
}

void Spectrum::tick() {
  ++m_frame;
  const bool fresh = m_lastBuffer.isValid() && m_lastBuffer.elapsed() < 300;
  if (!fresh) {
    if (m_live) { m_live = false; emit liveChanged(); }
    // Idle motion: slow waves, quieter toward the high bands.
    const double f = m_frame * 0.12;
    const bool playing = m_player && m_player->playbackState() == QMediaPlayer::PlayingState;
    const double beat = playing ? 0.55 + 0.45 * std::max(0.0, std::sin(f * 1.3)) : 0.25;
    for (int i = 0; i < m_bands; ++i) {
      const double band = double(i) / m_bands;
      const double v = (0.35 + 0.65 * std::abs(std::sin(f * 0.5 + i * 0.37) * std::cos(f * 0.31 + i * 0.11)));
      m_target[i] = v * (1.0 - band * 0.55) * beat;
    }
  }
  for (int i = 0; i < m_bands; ++i) {
    const double t = m_target[i];
    m_levels[i] = t > m_levels[i] ? t : m_levels[i] * 0.86 + t * 0.14;
  }
  emit levelsChanged();
}
