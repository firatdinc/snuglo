# "Gece" videosu için özgün müzik kutusu ninnisi (La minör, 72 BPM). Tamamı sentez, telifsiz.
import numpy as np, wave, os
SR = 44100
BEAT = 60 / 72
DUR = 20.0
N = int(SR * DUR)
out = np.zeros(N)

def bell(m, d=2.4, g=1.0):
    f = 440 * 2 ** ((m - 69) / 12)
    t = np.arange(int(SR * d)) / SR
    return g * (np.sin(2 * np.pi * f * t) + 0.32 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t * 3)
                + 0.14 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 7)) * np.exp(-t * 2.2) * np.minimum(t / 0.002, 1)

def add(sig, at):
    i = int(at * SR)
    if i >= N:
        return
    j = min(N, i + len(sig))
    out[i:j] += sig[: j - i]

MEL = [(76, 1), (72, 1), (69, 1), (72, .5), (76, .5), (77, 1), (76, 1), (72, 2),
       (74, 1), (71, 1), (68, 1), (71, .5), (74, .5), (76, 1), (74, 1), (69, 2),
       (76, 1), (72, 1), (69, 1), (72, .5), (76, .5), (81, 1), (80, 1), (76, 2),
       (77, 1), (76, 1), (74, 1), (71, 1), (69, 4)]
BASS = [45, 52, 57, 52, 41, 48, 53, 48, 44, 52, 56, 52, 45, 52, 57, 52]

t = 0.0
for m, b in MEL:
    add(bell(m, g=0.55), t)
    t += b * BEAT
t = 0.0
k = 0
while t < DUR:
    add(bell(BASS[k % len(BASS)], g=0.26), t)
    t += BEAT
    k += 1

# Oda yankısı
for d, g in [(0.19, .28), (0.31, .2), (0.47, .13), (0.71, .08)]:
    n = int(d * SR)
    out[n:] += out[:-n] * g

# Alttan kısık uğultu
tt = np.arange(N) / SR
out += 0.045 * np.sin(2 * np.pi * 55 * tt) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.11 * tt))
out = out / np.max(np.abs(out)) * 0.85
out *= np.minimum((DUR - tt) / 1.0, 1)

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ad-video", "public", "night_box.wav")
with wave.open(path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((out * 32767).astype(np.int16).tobytes())
print(path)
