#!/usr/bin/env python3
"""Son 8 ekran görüntüsü (2x2 karo 512x768, beyaz/siyah) -> 1024x1536 alfa sayfa -> 4 hap.
Her hap: sol yarısı aynalanarak tam simetrik yapılır, ayrıca kare varyantı (<ad>_sq) üretilir.
Kullanım: tools/pills.py ad1 ad2 ad3 ad4"""
import glob, os, sys, subprocess
import numpy as np
import scipy.ndimage as ndi
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from capture_import import build
names = sys.argv[1:]
T = sorted(glob.glob('/var/folders/*/*/T/claude-chrome-screenshots-*'), key=os.path.getmtime)[-1]
fs = sorted(glob.glob(T + '/screenshot-*'), key=lambda f: int(f.rsplit('-', 1)[1].split('.')[0]))[-8:]
root = os.path.join(os.path.dirname(__file__), '..')
sheet = build(root + '/art/raw/pills_%s.png' % names[0], 2, 2, 512, 768, [(fs[i], fs[i + 1]) for i in range(0, 8, 2)])
a = np.asarray(sheet)
m = a[..., 3] > 40
lab, k = ndi.label(ndi.binary_dilation(m, iterations=3))
objs = sorted([s for s in ndi.find_objects(lab) if (s[0].stop - s[0].start) * (s[1].stop - s[1].start) > 20000], key=lambda s: s[0].start)
assert len(objs) == len(names), len(objs)
out = root + '/art/sprites/ui'
for n, (ys, xs) in zip(names, objs):
    im = a[ys.start:ys.stop, xs.start:xs.stop].copy()
    h, w = im.shape[:2]
    left = im[:, : (w + 1) // 2]
    im = np.concatenate([left, left[:, ::-1][:, (w + 1) // 2 * 2 - w:]], axis=1)
    Image.fromarray(im).save(f'{out}/{n}.png')
    print(n, im.shape[1], im.shape[0])
