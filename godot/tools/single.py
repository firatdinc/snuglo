#!/usr/bin/env python3
"""Tek öğeli 1254² sayfa: verilen 8 ekran görüntüsünden (2x2 karo, beyaz/siyah sırayla) alfalı görsel,
alfa sınırına kırpılır, sol yarısı aynalanıp tam simetrik yapılır (isteğe bağlı üst/alt da).
Kullanım: tools/single.py <çıktı.png> [--sym x|xy|none] f1 f2 ... f8   (f yoksa son 8 png)"""
import argparse
import glob
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from capture_import import build  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument('out')
ap.add_argument('--sym', default='x')
ap.add_argument('files', nargs='*')
a = ap.parse_args()
fs = a.files
if not fs:
    T = sorted(glob.glob('/var/folders/*/*/T/claude-chrome-screenshots-*'), key=os.path.getmtime)[-1]
    fs = sorted(glob.glob(T + '/screenshot-*.png'), key=lambda f: int(f.rsplit('-', 1)[1].split('.')[0]))[-8:]
sheet = build(a.out, 2, 2, 627, 627, [(fs[i], fs[i + 1]) for i in range(0, 8, 2)])
bb = sheet.getchannel('A').point(lambda v: 255 if v > 30 else 0).getbbox()
arr = np.asarray(sheet.crop(bb)).copy()
if 'x' in a.sym:
    w = arr.shape[1]
    l = arr[:, :(w + 1) // 2]
    arr = np.concatenate([l, l[:, ::-1][:, (w + 1) // 2 * 2 - w:]], axis=1)
Image.fromarray(arr).save(a.out)
print(a.out, arr.shape[1], arr.shape[0])
