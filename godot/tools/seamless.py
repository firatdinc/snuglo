#!/usr/bin/env python3
"""Dikey dikişsiz döngü karosu — en az görünür dikiş (min-cut) yöntemi.

Görselin alt `ov` pikseli ile üst `ov` pikseli üst üste bindirilir. Bu bindirme bandında,
iki görselin en çok benzediği yerlerden geçen soldan sağa bir dikiş eğrisi dinamik
programlamayla bulunur (nesneleri kesmek yerine aralarından dolanır). Eğrinin üstü alt
banttan, altı üst banttan alınır; birkaç piksel yumuşatılır. Sonuç: karo yüksekliği H-ov,
ters çevirmeden art arda dizildiğinde kenarlar birebir devam eder.
Kullanım: tools/seamless.py <girdi> <çıktı> [ov_oranı=0.18]"""
import sys
import numpy as np
from PIL import Image
import scipy.ndimage as ndi

src, dst = sys.argv[1], sys.argv[2]
r = float(sys.argv[3]) if len(sys.argv) > 3 else 0.18
a = np.asarray(Image.open(src).convert('RGB')).astype(np.float32)
H, W = a.shape[:2]
ov = int(H * r)
A = a[H - ov:]          # bindirmenin üst katmanı: görselin alt bandı (önceki karonun sonu)
B = a[:ov]              # alt katman: görselin üst bandı (sonraki karonun başı)
cost = np.abs(A - B).sum(axis=2)
cost = ndi.uniform_filter(cost, 5)
# Dikiş: her sütunda bir satır seç, komşu sütunlar arası en fazla ±1 satır. Uçlardan uzak dur.
cost[:4] += 1e6; cost[-4:] += 1e6
acc = cost.copy()
back = np.zeros_like(acc, dtype=np.int8)
for x in range(1, W):
    prev = acc[:, x - 1]
    up = np.r_[np.inf, prev[:-1]]; dn = np.r_[prev[1:], np.inf]
    stack = np.vstack([up, prev, dn])
    k = np.argmin(stack, axis=0)
    acc[:, x] += stack[k, np.arange(ov)]
    back[:, x] = k - 1
seam = np.zeros(W, dtype=int)
seam[-1] = int(np.argmin(acc[:, -1]))
for x in range(W - 1, 0, -1):
    seam[x - 1] = seam[x] + back[seam[x], x]
# Maske: satır < dikiş -> A (üst), aksi B; 6 px yumuşak geçiş.
rows = np.arange(ov)[:, None]
m = np.clip((rows - seam[None, :] + 3) / 6.0, 0, 1)[..., None]
blend = A * (1 - m) + B * m
# Karo: [üst bant yerine karışım] + [ov .. H-ov arası]
out = np.concatenate([blend, a[ov:H - ov]], axis=0)
Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(dst, quality=92)
print(f'{dst} dikiş maliyeti {cost[seam, np.arange(W)].mean():.1f} -> {W}x{out.shape[0]}')
