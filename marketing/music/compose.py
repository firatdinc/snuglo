# Snuglo reklamı için özgün, telifsiz neşeli pop parçası (120 BPM, Do majör, 12 ölçü = 24 sn).
# Her şey burada sentezlenir: kick, clap, hi-hat, Karplus-Strong ukulele, marimba melodisi, bas, glockenspiel.
import numpy as np, wave, sys
SR = 48000; BPM = 120; BEAT = 60 / BPM; BAR = 4 * BEAT; BARS = 12
N = int(SR * (BARS * BAR + 1.5))
L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)
def t(n): return np.arange(n) / SR
def mtof(m): return 440 * 2 ** ((m - 69) / 12)
def add(sig, at, pan=0.0, gain=1.0):
    i = int(at * SR); j = min(N, i + len(sig)); s = sig[: j - i] * gain
    L[i:j] += s * np.sqrt(0.5 * (1 - pan)) * 1.41; R[i:j] += s * np.sqrt(0.5 * (1 + pan)) * 1.41
def lp(x, a):  # tek kutuplu alçak geçiren
    y = np.empty_like(x); acc = 0.0
    for k in range(len(x)): acc += a * (x[k] - acc); y[k] = acc
    return y
def kick():
    n = int(0.32 * SR); tt = t(n); f = 50 + 110 * np.exp(-tt * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-tt * 9) + 0.25 * np.exp(-tt * 300) * rng.standard_normal(n) * 0.3
def clap():
    n = int(0.22 * SR); tt = t(n); nz = rng.standard_normal(n)
    nz = nz - lp(nz, 0.25); env = np.exp(-tt * 22)
    for d in (0.0, 0.011, 0.022): env += np.where(tt > d, np.exp(-(tt - d) * 140), 0) * 0.6
    return lp(nz, 0.45) * env * 0.42
def hat(open_=False):
    n = int((0.16 if open_ else 0.045) * SR); tt = t(n); nz = rng.standard_normal(n)
    nz = nz - lp(nz, 0.6); return lp(nz, 0.55) * np.exp(-tt * (25 if open_ else 90)) * 0.16
def uke(m, dur=0.6):  # Karplus-Strong
    n = int(dur * SR); p = int(SR / mtof(m)); buf = rng.uniform(-1, 1, p); out = np.zeros(n)
    for k in range(n):
        out[k] = buf[k % p]; buf[k % p] = 0.5 * (buf[k % p] + buf[(k + 1) % p]) * 0.996
    return out * np.exp(-t(n) * 3)
def marimba(m, dur=0.45):
    n = int(dur * SR); tt = t(n); f = mtof(m)
    return (np.sin(2 * np.pi * f * tt) * np.exp(-tt * 7) + 0.35 * np.sin(2 * np.pi * f * 4 * tt) * np.exp(-tt * 30)
            + 0.15 * np.sin(2 * np.pi * f * 10 * tt) * np.exp(-tt * 60)) * np.minimum(1, tt * 400)
def glock(m, dur=0.9):
    n = int(dur * SR); tt = t(n); f = mtof(m)
    return (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2.76 * tt) * np.exp(-tt * 8)) * np.exp(-tt * 4.5) * 0.5
def bass(m, dur):
    n = int(dur * SR); tt = t(n); f = mtof(m)
    saw = 2 * ((f * tt) % 1) - 1; sq = np.sign(np.sin(2 * np.pi * f * tt))
    x = lp(0.6 * saw + 0.4 * sq, 0.08); return x * np.exp(-tt * 3.5) * np.minimum(1, tt * 300) * 0.9
def riser(dur):
    n = int(dur * SR); tt = t(n); nz = rng.standard_normal(n); out = np.zeros(n); acc = 0.0
    a = 0.02 + 0.5 * (tt / dur) ** 2
    for k in range(n): acc += a[k] * (nz[k] - acc); out[k] = acc
    return out * (tt / dur) ** 2 * 0.5

CH = {"C": [60, 64, 67, 72], "G": [59, 62, 67, 71], "Am": [57, 60, 64, 69], "F": [57, 60, 65, 69]}
ROOT = {"C": 36, "G": 31, "Am": 33, "F": 29}
PROG = ["C", "G", "Am", "F"] * 3
# Melodi: (vuruş içi 8'lik indeks, midi) — her akor için akılda kalan zıplayan motif
MEL = {
    "C": [(0, 76), (1, 79), (2, 84), (3, 79), (5, 81), (6, 79), (7, 76)],
    "G": [(0, 74), (1, 79), (2, 83), (3, 79), (5, 81), (6, 83), (7, 86)],
    "Am": [(0, 81), (1, 76), (2, 72), (3, 76), (5, 79), (6, 76), (7, 72)],
    "F": [(0, 77), (1, 81), (2, 84), (4, 86), (5, 84), (6, 81), (7, 79)],
}
kick_s, clap_s = kick(), clap()
uke_cache = {}
for b, ch in enumerate(PROG):
    t0 = b * BAR
    intro = b < 2; final = b == BARS - 1
    # Davul
    for q in range(4):
        tq = t0 + q * BEAT
        if not intro or (b == 1 and q >= 2):
            add(kick_s, tq, 0, 0.95)
        if (q % 2 == 1) and (b >= 1):
            add(clap_s, tq, 0.05, 0.75)
        for e in range(2):
            if not intro or e == 1:
                add(hat(open_=(e == 1 and q == 3)), tq + e * BEAT / 2, 0.35, 0.8 if e == 1 else 0.5)
        if b >= 4 and b % 4 in (2, 3):  # 16'lık hi-hat enerjisi
            add(hat(), tq + BEAT / 4, -0.3, 0.35); add(hat(), tq + 3 * BEAT / 4, -0.3, 0.35)
    # Ukulele stab'ları (ara vuruşlarda, sidechain hissi için kick'ten sonra)
    for e in range(8):
        if e % 2 == 1 or intro:
            for k, m in enumerate(CH[ch]):
                key = (m, 0.5)
                if key not in uke_cache: uke_cache[key] = uke(m, 0.5)
                add(uke_cache[key], t0 + e * BEAT / 2 + k * 0.008, -0.25 + k * 0.15, 0.28 if not intro else 0.22)
    # Bas: kök + oktav zıplaması
    if not intro:
        for e in range(8):
            m = ROOT[ch] + (12 if e % 4 == 3 else 0)
            add(bass(m, BEAT / 2 * 0.95), t0 + e * BEAT / 2, 0, 0.55)
    # Melodi (marimba), 2. yarıda glock ile katlanır
    if b >= 0:
        for e, m in MEL[ch]:
            add(marimba(m), t0 + e * BEAT / 2, 0.15, 0.42)
            if b >= 6: add(glock(m + 12, 0.5), t0 + e * BEAT / 2, -0.2, 0.18)
    if b in (1, 5, 9): add(riser(BAR * 0.9), t0 + BAR * 0.1, 0, 0.5)
# Final: büyük akor + glock arpej
tf = BARS * BAR
add(kick_s, tf, 0, 1.0); add(clap_s, tf, 0, 0.8)
for k, m in enumerate([60, 64, 67, 72, 76]):
    add(uke(m, 1.4), tf + k * 0.012, -0.3 + k * 0.15, 0.35)
for k, m in enumerate([84, 88, 91, 96]): add(glock(m), tf + k * 0.07, 0.2, 0.3)
mix = np.stack([L, R], 1)
mix = np.tanh(mix / np.max(np.abs(mix)) * 1.6) * 0.89
fade = int(0.08 * SR); mix[-fade:] *= np.linspace(1, 0, fade)[:, None]
out = sys.argv[1] if len(sys.argv) > 1 else "snuglo_jingle.wav"
with wave.open(out, "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype("<i2").tobytes())
print(out, len(mix) / SR)
