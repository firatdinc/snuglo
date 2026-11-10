#!/usr/bin/env python3
"""Snuglo Noel müziği (özgün beste, telifsiz, tamamen burada sentezlenir).
Sıcak, neşeli kış havası: kızak çanları, müzik kutusu/celesta melodisi, pizzicato bas,
yumuşak yaylı pad, fırça davul. 112 BPM, Fa majör, 32 ölçü (A8 B8 A'8 C8), dikişsiz döngü.
Kullanım: ~/asset-tools/.venv/bin/python tools/compose_xmas_bgm.py [audio/music/bgm_xmas.wav]"""
import os
import sys
import wave

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
BPM = 112
BEAT = 60 / BPM
BAR = 4 * BEAT
E8 = BEAT / 2
rng = np.random.default_rng(1225)

# Akorlar (Fa majör): I vi IV V, ii V I, vb.
A = ["F", "Dm", "Bb", "C", "F", "Dm", "Gm", "C7"]
B = ["Bb", "C", "Am", "Dm", "Gm", "C", "F", "C7"]
C = ["Dm", "Bb", "F", "C", "Gm", "Bb", "C7", "F"]
PROG = A + B + A + C
SEC = ["A"] * 8 + ["B"] * 8 + ["A2"] * 8 + ["C"] * 8
LOOP = int(SR * len(PROG) * BAR)
N = LOOP + int(SR * 3)
L = np.zeros(N)
R = np.zeros(N)

CH = {"F": [53, 57, 60, 65], "Dm": [50, 57, 62, 65], "Bb": [50, 53, 58, 62], "C": [52, 55, 60, 64],
      "C7": [52, 58, 60, 64], "Gm": [50, 55, 58, 62], "Am": [52, 57, 60, 64]}
ROOT = {"F": 41, "Dm": 38, "Bb": 34, "C": 36, "C7": 36, "Gm": 43, "Am": 45}


def t(n):
    return np.arange(n) / SR


def mtof(m):
    return 440 * 2 ** ((m - 69) / 12)


def lp(x, f):
    return sosfilt(butter(2, f, btype="low", fs=SR, output="sos"), x)


def bp(x, lo, hi):
    return sosfilt(butter(2, [lo, hi], btype="band", fs=SR, output="sos"), x)


def add(sig, at, pan=0.0, gain=1.0):
    i = int(at * SR)
    j = min(N, i + len(sig))
    s = sig[: j - i] * gain
    L[i:j] += s * np.sqrt(0.5 * (1 - pan)) * 1.41
    R[i:j] += s * np.sqrt(0.5 * (1 + pan)) * 1.41


_c = {}


def cached(key, fn):
    if key not in _c:
        _c[key] = fn()
    return _c[key]


def celesta(m, dur=1.2):
    def mk():
        n = int(dur * SR)
        tt = t(n)
        f = mtof(m)
        x = (np.sin(2 * np.pi * f * tt) * np.exp(-tt * 3.2)
             + 0.35 * np.sin(2 * np.pi * f * 4.0 * tt) * np.exp(-tt * 14)
             + 0.12 * np.sin(2 * np.pi * f * 7.1 * tt) * np.exp(-tt * 30))
        return x * np.minimum(1, tt * 600) * 0.5
    return cached(("cel", m, dur), mk)


def musicbox(m, dur=0.9):
    def mk():
        n = int(dur * SR)
        tt = t(n)
        f = mtof(m)
        x = np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(2 * np.pi * f * 3.0 * tt) * np.exp(-tt * 9)
        return x * np.exp(-tt * 5) * np.minimum(1, tt * 900) * 0.35
    return cached(("mb", m, dur), mk)


def pizz(m, dur=0.5):
    def mk():
        n = int(dur * SR)
        p = max(2, int(SR / mtof(m)))
        buf = rng.uniform(-1, 1, p)
        out = np.zeros(n)
        for k in range(n):
            out[k] = buf[k % p]
            buf[k % p] = 0.5 * (buf[k % p] + buf[(k + 1) % p]) * 0.992
        return lp(out, 1800) * np.exp(-t(n) * 5) * 0.9
    return cached(("pz", m, dur), mk)


def pad(notes, dur):
    def mk():
        n = int(dur * SR)
        tt = t(n)
        x = np.zeros(n)
        for m in notes:
            f = mtof(m)
            for d in (-0.003, 0.0, 0.003):  # hafif koro
                x += np.sin(2 * np.pi * f * (1 + d) * tt + rng.uniform(0, 6.28))
        env = np.minimum(1, tt / 0.5) * np.minimum(1, (dur - tt) / 0.6).clip(0)
        return lp(x, 1400) * env * 0.05
    return cached(("pad", tuple(notes), dur), mk)


def sleigh(acc=False):
    n = int(0.12 * SR)
    tt = t(n)
    x = np.zeros(n)
    for k in range(5):
        f = rng.uniform(5200, 7600)
        x += np.sin(2 * np.pi * f * tt + rng.uniform(0, 6)) * np.exp(-tt * rng.uniform(35, 60))
    x += bp(rng.standard_normal(n), 7000, 12000) * np.exp(-tt * 50) * 0.6
    return x * np.minimum(1, tt * 800) * (0.06 if acc else 0.035)


def brush():
    n = int(0.14 * SR)
    tt = t(n)
    return bp(rng.standard_normal(n), 1500, 6000) * np.exp(-tt * 25) * 0.12


def kick():
    n = int(0.25 * SR)
    tt = t(n)
    f = 50 + 70 * np.exp(-tt * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 14) * 0.6


# Özgün melodi (sekizlik konum, MIDI). A: zıplayan, B: yükselen, C: tatlı kapanış.
MEL_A = [
    [(0, 72), (2, 69), (3, 72), (4, 77), (6, 76)],
    [(0, 74), (2, 72), (4, 69), (6, 72)],
    [(0, 70), (1, 72), (2, 74), (4, 77), (6, 74)],
    [(0, 72), (2, 76), (4, 79), (6, 76)],
    [(0, 77), (2, 76), (3, 74), (4, 72), (6, 69)],
    [(0, 74), (2, 77), (4, 81), (6, 77)],
    [(0, 79), (2, 77), (4, 74), (5, 72), (6, 70)],
    [(0, 72), (4, 76), (6, 79)],
]
MEL_B = [
    [(0, 74), (2, 77), (4, 82), (6, 81)],
    [(0, 79), (2, 76), (4, 72), (6, 76)],
    [(0, 76), (2, 72), (4, 69), (6, 72)],
    [(0, 74), (1, 76), (2, 77), (4, 81), (6, 77)],
    [(0, 79), (2, 82), (4, 79), (6, 74)],
    [(0, 76), (2, 79), (4, 84), (6, 79)],
    [(0, 81), (2, 77), (4, 72), (6, 77)],
    [(0, 76), (2, 79), (4, 82), (6, 84)],
]
MEL_C = [
    [(0, 81), (2, 77), (4, 74), (6, 77)],
    [(0, 82), (2, 77), (4, 74), (6, 70)],
    [(0, 72), (2, 77), (4, 81), (6, 84)],
    [(0, 84), (2, 82), (3, 81), (4, 79), (6, 76)],
    [(0, 79), (2, 82), (4, 79), (6, 74)],
    [(0, 77), (2, 74), (4, 70), (6, 74)],
    [(0, 76), (2, 79), (4, 82), (6, 79)],
    [(0, 77), (4, 72), (6, 77)],
]
MEL = {"A": MEL_A, "A2": MEL_A, "B": MEL_B, "C": MEL_C}

kick_s = kick()
for b, ch in enumerate(PROG):
    t0 = b * BAR
    sec = SEC[b]
    bi = b % 8
    # Pad: ölçü başına akor
    add(pad(CH[ch], BAR + 0.4), t0, 0.0, 1.0)
    # Kızak çanları: sekizlikler, vuruşlarda vurgu (A'da ve C'de daha dolu)
    for e in range(8):
        if sec == "A" and bi < 2 and e % 2:
            continue
        add(sleigh(e % 2 == 0), t0 + e * E8 + (0.012 if e % 2 else 0), 0.35, 1.0)
    # Davul: yumuşak kick 1-3, fırça 2-4
    if sec != "A" or bi >= 2:
        for q in range(4):
            if q in (0, 2):
                add(kick_s, t0 + q * BEAT, 0, 0.5)
            else:
                add(brush(), t0 + q * BEAT, -0.15, 1.0)
    # Pizzicato bas: kök - beşli yürüyüş
    root = ROOT[ch]
    for q, iv in enumerate((0, 7, 12, 7)):
        add(pizz(root + iv, BEAT * 0.9), t0 + q * BEAT, -0.1, 0.45)
    # Müzik kutusu arpej (sekizlik, akor notalarının oktav üstü)
    arp = [n + 12 for n in CH[ch]]
    for e in range(8):
        add(musicbox(arp[(e * 3 + bi) % 4] + (12 if e % 4 == 3 else 0)), t0 + e * E8, -0.35, 0.22)
    # Melodi: celesta, B ve C'de üst oktav ikizi
    for e, m in MEL[sec][bi]:
        add(celesta(m), t0 + e * E8, 0.18, 0.42)
        if sec in ("B", "C"):
            add(celesta(m + 12, 0.8), t0 + e * E8, 0.3, 0.12)

# Kuyruğu başa sar → dikişsiz döngü
L[:N - LOOP] += L[LOOP:]
R[:N - LOOP] += R[LOOP:]
L = L[:LOOP]
R = R[:LOOP]
# Hafif oda yankısı (çoklu gecikme)
for d, g in ((0.031, 0.18), (0.067, 0.12), (0.113, 0.08)):
    k = int(d * SR)
    L2 = np.roll(R, k) * g
    R2 = np.roll(L, k) * g
    L += L2
    R += R2
pk = max(np.max(np.abs(L)), np.max(np.abs(R)))
L = L / pk * 0.8
R = R / pk * 0.8

out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "audio", "music", "bgm_xmas.wav")
pcm = (np.stack([L, R], axis=1).clip(-1, 1) * 32767).astype("<i2")
with wave.open(out, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("yazıldı", os.path.normpath(out), "%.1f sn" % (LOOP / SR))
