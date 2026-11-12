#!/usr/bin/env python3
"""Opak 2x2 kumaş sayfasından 4 doku: son 4 ekran görüntüsü (sol-üst, sağ-üst, sol-alt, sağ-alt),
kenardaki krem boşluk kırpılır. Kullanım: tools/fabric_cut.py <set> <ilk_no>"""
import glob, os, sys
from PIL import Image
st, first = sys.argv[1], int(sys.argv[2])
T = sorted(glob.glob('/var/folders/*/*/T/claude-chrome-screenshots-*'), key=os.path.getmtime)[-1]
fs = sorted(glob.glob(T + '/screenshot-*'), key=lambda f: int(f.rsplit('-', 1)[1].split('.')[0]))[-4:]
os.makedirs('art/fabric/%s' % st, exist_ok=True)
for k, f in enumerate(fs):
    im = Image.open(f).convert('RGB')
    w, h = im.size
    # tile 0: swatch sağ-alt köşeye yaslı; 3: sol-üste. Kenarlardan güvenli pay al.
    m = 22
    im = im.crop((m, m, w - m, h - m)).resize((512, 512), Image.LANCZOS)
    out = 'art/fabric/%s/f%02d.png' % (st, first + k)
    im.save(out)
    print(out)
