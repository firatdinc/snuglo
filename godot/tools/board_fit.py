#!/usr/bin/env python3
"""Çerçeve görselinin iç (patiska) alanını bulur ve iç alanı tam kare olacak şekilde
yeniden örnekler. Çıktı: art/board/frame.png + art/board/frame.json (iç alan oranı).
Kullanım: tools/board_fit.py <girdi.png>"""
import json, sys
import numpy as np
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGBA')
a = np.asarray(im).astype(int)
H, W = a.shape[:2]
lum = a[..., :3].sum(2)

def edge(line, start, step):
    # merkezden dışa: patiska açık; 8 ardışık piksel merkez parlaklığının %82'sinin altına inince dur
    ref = np.median(line[start - 50:start + 50])
    i = start
    run = 0
    while 0 < i < len(line) - 1:
        run = run + 1 if line[i] < ref * 0.82 else 0
        if run >= 8:
            return i - step * 7
        i += step
    return i

cy, cx = H // 2, W // 2
rows = [lum[y, :] for y in range(cy - 200, cy + 201, 40)]
cols = [lum[:, x] for x in range(cx - 200, cx + 201, 40)]
L = int(np.median([edge(r, cx, -1) for r in rows])) + 1
R = int(np.median([edge(r, cx, 1) for r in rows]))
T = int(np.median([edge(c, cy, -1) for c in cols])) + 1
B = int(np.median([edge(c, cy, 1) for c in cols]))
print('inner', L, T, R, B, R - L, B - T)
ys, xs = np.where(a[..., 3] > 30)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
# Parça parça doğrusal eşleme: dış sınır → iç sınır → iç sınır → dış sınır, iç alan kare olur.
S = 1024
inner = 840
m = (S - inner) / 2
def remap(v0, vi0, vi1, v1, n):
    out = np.zeros(n)
    for k in range(n):
        t = k + 0.5
        if t < m:
            out[k] = v0 + (vi0 - v0) * t / m
        elif t > S - m:
            out[k] = vi1 + (v1 - vi1) * (t - (S - m)) / m
        else:
            out[k] = vi0 + (vi1 - vi0) * (t - m) / inner
    return out
mx = remap(x0, L, R, x1, S)
my = remap(y0, T, B, y1, S)
src = np.asarray(im)
out = src[np.clip(my.astype(int), 0, H - 1)[:, None], np.clip(mx.astype(int), 0, W - 1)[None, :]]
Image.fromarray(out).save('art/board/frame.png')
json.dump({'size': S, 'inner': [m, m, inner, inner]}, open('art/board/frame.json', 'w'))
print('art/board/frame.png', S, 'inner', m, inner)
