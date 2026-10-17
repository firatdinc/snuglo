# Snuglo oyun içi neşeli müzik döngüsü (telifsiz, tamamen burada sentezlenir).
# 104 BPM, Do majör, 24 ölçü: A (8) + B (8) + A' (8). Kuyruk başa sarılır → dikişsiz döngü.
# Kullanım: python3 tools/compose_bgm.py out.wav
import numpy as np, wave, sys
SR = 44100; BPM = 104; BEAT = 60 / BPM; BAR = 4 * BEAT; E8 = BEAT / 2
A_PROG = ["C", "Am", "F", "G", "C", "Am", "F", "G2"]
B_PROG = ["F", "G", "Em", "Am", "F", "G", "C", "C2"]
PROG = A_PROG + B_PROG + A_PROG
SEC = ["A"] * 8 + ["B"] * 8 + ["A2"] * 8
LOOP = int(SR * len(PROG) * BAR)
N = LOOP + int(SR * 3)
L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(11)
def t(n): return np.arange(n) / SR
def mtof(m): return 440 * 2 ** ((m - 69) / 12)
def add(sig, at, pan=0.0, gain=1.0):
    i = int(at * SR); j = min(N, i + len(sig)); s = sig[: j - i] * gain
    L[i:j] += s * np.sqrt(0.5 * (1 - pan)) * 1.41; R[i:j] += s * np.sqrt(0.5 * (1 + pan)) * 1.41
def lp(x, a):
    y = np.empty_like(x); acc = 0.0
    for k in range(len(x)): acc += a * (x[k] - acc); y[k] = acc
    return y
def kick():
    n = int(0.25 * SR); tt = t(n); f = 55 + 90 * np.exp(-tt * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 12)
def snap():
    n = int(0.12 * SR); tt = t(n); nz = rng.standard_normal(n); nz = nz - lp(nz, 0.3)
    body = np.sin(2 * np.pi * 1800 * tt) * np.exp(-tt * 90) * 0.3
    return (lp(nz, 0.5) * np.exp(-tt * 45) + body) * 0.35
def shaker(acc=False):
    n = int(0.06 * SR); tt = t(n); nz = rng.standard_normal(n); nz = nz - lp(nz, 0.7)
    env = np.minimum(1, tt * 300) * np.exp(-tt * 60)
    return lp(nz, 0.45) * env * (0.07 if acc else 0.04)
_c = {}
def cached(key, fn):
    if key not in _c: _c[key] = fn()
    return _c[key]
def uke(m, dur=0.55):
    def mk():
        n = int(dur * SR); p = int(SR / mtof(m)); buf = rng.uniform(-1, 1, p); out = np.zeros(n)
        for k in range(n):
            out[k] = buf[k % p]; buf[k % p] = 0.5 * (buf[k % p] + buf[(k + 1) % p]) * 0.995
        return out * np.exp(-t(n) * 4)
    return cached(("u", m, dur), mk)
def marimba(m, dur=0.5):
    def mk():
        n = int(dur * SR); tt = t(n); f = mtof(m)
        return (np.sin(2 * np.pi * f * tt) * np.exp(-tt * 6) + 0.3 * np.sin(2 * np.pi * f * 4 * tt) * np.exp(-tt * 28)
                + 0.1 * np.sin(2 * np.pi * f * 10 * tt) * np.exp(-tt * 60)) * np.minimum(1, tt * 400)
    return cached(("m", m, dur), mk)
def glock(m, dur=0.8):
    def mk():
        n = int(dur * SR); tt = t(n); f = mtof(m)
        return (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2.76 * tt) * np.exp(-tt * 8)) * np.exp(-tt * 4.5) * 0.5
    return cached(("g", m, dur), mk)
def whistle(m, dur):  # yumuşak flüt/ıslık lead: sinüs + hafif vibrato
    def mk():
        n = int(dur * SR); tt = t(n); f = mtof(m) * (1 + 0.006 * np.sin(2 * np.pi * 5.5 * tt) * np.minimum(1, tt * 4))
        ph = 2 * np.pi * np.cumsum(f) / SR
        env = np.minimum(1, tt * 40) * np.minimum(1, (dur - tt) * 25).clip(0)
        return (np.sin(ph) + 0.12 * np.sin(2 * ph)) * env * 0.5
    return cached(("w", m, dur), mk)
def bass(m, dur):
    def mk():
        n = int(dur * SR); tt = t(n); f = mtof(m)
        x = lp(0.6 * (2 * ((f * tt) % 1) - 1) + 0.4 * np.sign(np.sin(2 * np.pi * f * tt)), 0.1)
        return x * np.exp(-tt * 4) * np.minimum(1, tt * 300) * 0.8
    return cached(("b", m, dur), mk)

CH = {"C": [60, 64, 67, 72], "C2": [60, 64, 67, 72], "G": [59, 62, 67, 71], "G2": [59, 62, 67, 71],
      "Am": [57, 60, 64, 69], "F": [57, 60, 65, 69], "Em": [59, 64, 67, 71]}
ROOT = {"C": 36, "C2": 36, "G": 43, "G2": 43, "Am": 45, "F": 41, "Em": 40}
MEL_A = {
    "C": [(0, 79), (1, 76), (2, 79), (4, 81), (5, 79), (6, 76)],
    "Am": [(0, 76), (1, 72), (2, 76), (4, 79), (6, 76)],
    "F": [(0, 77), (1, 81), (2, 84), (3, 81), (4, 79), (6, 77)],
    "G": [(0, 74), (2, 79), (3, 77), (4, 76), (5, 74), (6, 71)],
    "G2": [(0, 74), (2, 76), (4, 72)],
}
MEL_B = [
    [(0, 84), (2, 81), (3, 84), (4, 86), (6, 84)],
    [(0, 83), (2, 79), (4, 83), (5, 84), (6, 86)],
    [(0, 83), (2, 79), (4, 76), (6, 79)],
    [(0, 81), (1, 79), (2, 76), (4, 72), (6, 76)],
    [(0, 77), (2, 81), (4, 84), (6, 81)],
    [(0, 79), (2, 83), (4, 86), (5, 84), (6, 83)],
    [(0, 84), (2, 79), (4, 76), (6, 79)],
    [(0, 72), (4, 76), (6, 79)],
]
STRUM = [0, 2, 3, 5, 6, 7]
kick_s, snap_s = kick(), snap()
for b, ch in enumerate(PROG):
    t0 = b * BAR; sec = SEC[b]; bi = b % 8
    # Davul: yumuşak kick, 2-4'te snap, 16'lık shaker
    for q in range(4):
        tq = t0 + q * BEAT
        if q in (0, 2): add(kick_s, tq, 0, 0.55)
        if q == 1 and bi % 2 == 1: add(kick_s, tq + E8, 0, 0.3)
        if q in (1, 3): add(snap_s, tq, 0.1, 0.7)
        for s in range(4):
            add(shaker(s == 2), tq + s * BEAT / 4, 0.4 if s % 2 else 0.3, 0.8 if sec == "B" else 0.6)
    # Ukulele strum
    for e in STRUM:
        up = e in (3, 7)
        notes = CH[ch][::-1] if up else CH[ch]
        for k, m in enumerate(notes):
            add(uke(m), t0 + e * E8 + k * 0.007, -0.3 + k * 0.12, 0.16 if up else 0.22)
    # Bas: kök, kısa sekizlikler + oktav zıplaması
    for e in (0, 2, 3, 4, 6, 7):
        m = ROOT[ch] + (12 if e in (3, 7) else 0)
        add(bass(m, E8 * 0.9), t0 + e * E8, 0, 0.5)
    # Melodi
    if sec == "B":
        for e, m in MEL_B[bi]:
            add(marimba(m), t0 + e * E8, 0.15, 0.36)
            add(glock(m + 12, 0.5), t0 + e * E8, -0.25, 0.14)
    else:
        mel = MEL_A[ch]
        for i, (e, m) in enumerate(mel):
            if sec == "A":
                add(marimba(m), t0 + e * E8, 0.15, 0.4)
            else:  # A': ıslık lead + alt marimba
                nxt = mel[i + 1][0] if i + 1 < len(mel) else 8
                add(whistle(m, (nxt - e) * E8 * 0.92), t0 + e * E8, 0.1, 0.32)
                add(marimba(m - 12), t0 + e * E8, -0.15, 0.22)
    # Ölçü başı ışıltı
    if bi in (0, 4) and sec != "A": add(glock(CH[ch][-1] + 12, 1.2), t0, 0.3, 0.12)

# Kuyruğu başa sar → dikişsiz döngü
L[: N - LOOP] += L[LOOP:]; R[: N - LOOP] += R[LOOP:]
mix = np.stack([L[:LOOP], R[:LOOP]], 1)
mix = np.tanh(mix / np.max(np.abs(mix)) * 1.3) * 0.85
out = sys.argv[1] if len(sys.argv) > 1 else "bgm_play.wav"
with wave.open(out, "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype("<i2").tobytes())
print(out, round(LOOP / SR, 2), "sn")
