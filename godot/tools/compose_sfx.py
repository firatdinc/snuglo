#!/usr/bin/env python3
"""Snuglo ASMR kumaş + Noel efektleri (telifsiz, tamamen burada sentezlenir).
Kullanım: ~/asset-tools/.venv/bin/python tools/compose_sfx.py [çıktı_klasörü=audio/sfx]
Üretir: stitch rustle felt_pop scissors bell jingle crackle paper_fold ribbon bow icing
        sprinkle snow_roll snow_pack twinkle chime  (mono 16-bit 44.1 kHz wav)
Hepsi yumuşak, düşük tepe seviyeli (≈-6 dBFS), saldırısı törpülü — rahatlatıcı katman."""
import os
import sys
import wave

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
rng = np.random.default_rng(2026)


def t(sec):
    return np.arange(int(sec * SR)) / SR


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)


def lp(x, f, order=2):
    return sosfilt(butter(order, f, btype="low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return sosfilt(butter(order, f, btype="high", fs=SR, output="sos"), x)


def env(n, a=0.004, d=0.1, curve=1.0):
    tt = np.arange(n) / SR
    e = np.minimum(1.0, tt / max(a, 1e-4)) * np.exp(-np.maximum(0, tt - a) / d) ** curve
    return e


def noise(sec):
    return rng.standard_normal(int(sec * SR))


def place(dst, sig, at):
    i = int(at * SR)
    j = min(len(dst), i + len(sig))
    dst[i:j] += sig[: j - i]


def norm(x, peak=0.5):
    x = x - np.mean(x)
    m = np.max(np.abs(x)) or 1.0
    # kısa fade-in/out: tık sesi olmasın
    f = min(len(x) // 4, int(0.004 * SR))
    if f > 0:
        x[:f] *= np.linspace(0, 1, f)
        x[-f:] *= np.linspace(1, 0, f)
    return x / m * peak


def bell_tone(f, sec, decay=0.6, partials=((1, 1), (2.76, 0.4), (5.4, 0.2), (8.9, 0.08))):
    tt = t(sec)
    out = np.zeros_like(tt)
    for k, a in partials:
        out += a * np.sin(2 * np.pi * f * k * tt) * np.exp(-tt / (decay / k ** 0.6))
    return out


# ------------------------------------------------------------------ kumaş

def stitch():
    # iğne kumaşa girip çıkar: iki kısa, yumuşak "çıt" + iplik sürtünmesi
    out = np.zeros(int(0.42 * SR))
    for at, f in ((0.0, 3200), (0.16, 2600)):
        n = noise(0.05)
        place(out, bp(n, f * 0.7, f * 1.3) * env(len(n), 0.001, 0.012), at)
    thr = noise(0.22)
    place(out, bp(thr, 1800, 5200) * env(len(thr), 0.03, 0.08) * 0.35, 0.05)
    return norm(out, 0.45)


def rustle():
    # kumaş hışırtısı: düzensiz genlik modülasyonlu bant gürültü
    sec = 0.5
    n = noise(sec)
    mod = lp(np.abs(noise(sec)), 18)
    mod = mod / (mod.max() or 1)
    x = bp(n, 900, 6000) * mod * env(len(n), 0.06, 0.25)
    return norm(x, 0.4)


def felt_pop():
    # keçe "pof": boğuk alçak darbe + yumuşak hava
    tt = t(0.22)
    f = 140 + 160 * np.exp(-tt * 40)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 22)
    air = lp(noise(0.22), 1200) * np.exp(-tt * 35) * 0.5
    return norm(body + air, 0.55)


def scissors():
    # iki makas kesişi: metalik sürtünme + kapanış tıkı
    out = np.zeros(int(0.7 * SR))
    for at in (0.0, 0.32):
        sw = noise(0.2)
        place(out, bp(sw, 3000, 9000) * env(len(sw), 0.02, 0.06) * 0.5, at)
        place(out, bell_tone(4200, 0.08, 0.02) * 0.4, at + 0.18)
    return norm(out, 0.42)


def paper_fold():
    # kâğıt/kumaş katlama: kısa sürtünme + yumuşak bastırma
    out = np.zeros(int(0.45 * SR))
    sw = noise(0.3)
    sweep = np.linspace(1, 0.3, len(sw))
    place(out, bp(sw, 700, 4500) * env(len(sw), 0.05, 0.12) * sweep, 0.0)
    place(out, felt_pop() * 0.5, 0.26)
    return norm(out, 0.45)


def ribbon():
    # saten kurdele çekme: tiz, pürüzsüz sürtünme yükselen perde
    sec = 0.6
    n = noise(sec)
    x = np.zeros_like(n)
    for k in range(6):
        seg = slice(k * len(n) // 6, (k + 1) * len(n) // 6)
        lo = 2000 + k * 300
        x[seg] = bp(n[seg], lo, lo * 2.2)
    return norm(x * env(len(n), 0.08, 0.3), 0.35)


def bow():
    # fiyonk: iki ilmek hışırtı + küçük zil
    out = np.zeros(int(0.8 * SR))
    place(out, rustle() * 0.7, 0.0)
    place(out, rustle() * 0.6, 0.18)
    place(out, bell_tone(1568, 0.6, 0.35) * 0.35, 0.36)
    return norm(out, 0.45)


# ------------------------------------------------------------------ Noel

def bell():
    return norm(bell_tone(1318.5, 1.4, 0.7), 0.42)


def chime():
    out = np.zeros(int(1.6 * SR))
    for i, f in enumerate((1046.5, 1318.5, 1568.0)):
        place(out, bell_tone(f, 1.2, 0.5) * (0.8 - i * 0.15), i * 0.09)
    return norm(out, 0.42)


def twinkle():
    # ışık yanışı: minik yüksek kristal
    out = np.zeros(int(0.7 * SR))
    for i, f in enumerate((2093, 2637)):
        place(out, bell_tone(f, 0.5, 0.18, ((1, 1), (3.01, 0.25))) * (0.7 - i * 0.2), i * 0.05)
    return norm(out, 0.32)


def jingle():
    # kızak çanı salkımı: rastgele zamanlı küçük metal çıngıraklar
    out = np.zeros(int(1.1 * SR))
    for k in range(14):
        f = rng.uniform(3800, 5600)
        at = 0.02 + abs(rng.normal(0.18, 0.12))
        tone = bell_tone(f, 0.25, 0.05, ((1, 1), (1.51, 0.6), (2.3, 0.3))) * rng.uniform(0.4, 1.0)
        place(out, tone, min(at, 0.8))
    shake = bp(noise(0.5), 6000, 11000) * env(int(0.5 * SR), 0.05, 0.15) * 0.25
    place(out, shake, 0.05)
    return norm(out, 0.38)


def crackle():
    # şömine çıtırtısı (2 sn, döngüye uygun): uğultu + düzensiz çıtlar
    sec = 2.0
    out = lp(noise(sec), 300) * 0.25
    for k in range(int(sec * 9)):
        at = rng.uniform(0, sec - 0.03)
        n = noise(0.012)
        place(out, hp(n, 1500) * env(len(n), 0.0005, 0.004) * rng.uniform(0.3, 1.0), at)
    f = int(0.05 * SR)
    out[:f] *= np.linspace(0, 1, f)
    out[-f:] *= np.linspace(1, 0, f)
    return norm(out, 0.35)


# ------------------------------------------------------------------ kurabiye / kar

def icing():
    # krema sıkma: yumuşak, ıslak, alçak frekans akış
    sec = 0.7
    n = noise(sec)
    wob = 0.6 + 0.4 * np.sin(2 * np.pi * 7 * t(sec))
    return norm(bp(n, 180, 900) * wob * env(len(n), 0.06, 0.4), 0.4)


def sprinkle():
    out = np.zeros(int(0.6 * SR))
    for k in range(18):
        n = noise(0.01)
        place(out, bp(n, 3000, 8000) * env(len(n), 0.0005, 0.005) * rng.uniform(0.3, 1), rng.uniform(0, 0.45))
    return norm(out, 0.35)


def snow_roll():
    # kar topu yuvarlama: boğuk sıkışan kar "gıcırtısı" (döngüye uygun 0.8 sn)
    sec = 0.8
    n = noise(sec)
    grain = lp(np.abs(noise(sec)), 40)
    x = bp(n, 300, 2500) * (0.5 + grain / (grain.max() or 1))
    f = int(0.04 * SR)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return norm(x, 0.35)


def snow_pack():
    tt = t(0.3)
    crunch = bp(noise(0.3), 400, 3000) * np.exp(-tt * 18)
    thud = np.sin(2 * np.pi * 110 * tt) * np.exp(-tt * 25) * 0.7
    return norm(crunch + thud, 0.5)


# ------------------------------------------------------------------ fırın

def knob_click():
    # döner düğme kademesi: kısa plastik/kil tık + minik yay
    n = noise(0.03)
    x = bp(n, 1800, 5000) * env(len(n), 0.0005, 0.006)
    x = np.concatenate([x, np.zeros(int(0.02 * SR))])
    return norm(x, 0.4)


def timer_wind():
    # mekanik zamanlayıcı kurma: hızlı cırcır dizisi (0.5 sn)
    out = np.zeros(int(0.55 * SR))
    for k in range(11):
        n = noise(0.012)
        place(out, bp(n, 2500, 7000) * env(len(n), 0.0003, 0.003) * (0.6 + 0.4 * (k % 2)), k * 0.045)
    return norm(out, 0.38)


def tick():
    # tik-tak için tek tik (oyun 0.5 sn aralıkla tekrarlar)
    n = noise(0.03)
    x = bp(n, 3000, 6000) * env(len(n), 0.0003, 0.004) + bell_tone(3400, 0.03, 0.008)[: len(n)] * 0.3
    return norm(x, 0.28)


def oven_hum():
    # ısınan fırın uğultusu (2 sn döngü): alçak sinüs + fan gürültüsü
    sec = 2.0
    tt = t(sec)
    hum = np.sin(2 * np.pi * 60 * tt) * 0.5 + np.sin(2 * np.pi * 120 * tt) * 0.25
    fan = lp(noise(sec), 500) * 0.6
    x = hum + fan
    f = int(0.05 * SR)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return norm(x, 0.3)


def oven_door():
    # fırın kapağı: menteşe gıcırtısı + yumuşak tok kapanma
    out = np.zeros(int(0.7 * SR))
    tt = t(0.35)
    f = 700 + 300 * np.sin(2 * np.pi * 3 * tt)
    creak = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(tt), 0.05, 0.15) * 0.25
    creak += bp(noise(0.35), 600, 2500) * env(len(tt), 0.05, 0.12) * 0.3
    place(out, creak, 0.0)
    tt2 = t(0.25)
    thud = np.sin(2 * np.pi * 95 * tt2) * np.exp(-tt2 * 20) + lp(noise(0.25), 800) * np.exp(-tt2 * 30) * 0.4
    place(out, thud, 0.38)
    return norm(out, 0.5)


def ding():
    # zamanlayıcı zili: parlak tek çan + hafif titreşimli kuyruk
    return norm(bell_tone(1760, 1.6, 0.8, ((1, 1), (2.0, 0.35), (3.01, 0.15), (5.2, 0.06))), 0.45)


SOUNDS = {
    "knob_click": knob_click, "timer_wind": timer_wind, "tick": tick, "oven_hum": oven_hum,
    "oven_door": oven_door, "ding": ding,
    "stitch": stitch, "rustle": rustle, "felt_pop": felt_pop, "scissors": scissors,
    "paper_fold": paper_fold, "ribbon": ribbon, "bow": bow, "bell": bell, "chime": chime,
    "twinkle": twinkle, "jingle": jingle, "crackle": crackle, "icing": icing,
    "sprinkle": sprinkle, "snow_roll": snow_roll, "snow_pack": snow_pack,
}


def write(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == "__main__":
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")
    for name, fn in SOUNDS.items():
        p = os.path.join(out_dir, name + ".wav")
        write(p, fn())
        print("yazıldı", os.path.normpath(p))
