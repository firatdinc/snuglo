#!/usr/bin/env python3
"""Opak dikey arka plan: son N ekran görüntüsünü (üstten alta) dikey birleştirir.
Kullanım: tools/stitch_v.py <ad> <N> <tam_yükseklik> [maks_genişlik]  -> art/sprites/bg/<ad>.jpg + xcassets"""
import glob, os, sys, json
from PIL import Image
name, n, H = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
mx = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
T = sorted(glob.glob('/var/folders/*/*/T/claude-chrome-screenshots-*'), key=os.path.getmtime)[-1]
fs = sorted(glob.glob(T + '/screenshot-*'), key=lambda f: int(f.rsplit('-', 1)[1].split('.')[0]))[-n:]
ims = [Image.open(f).convert('RGB') for f in fs]
W = ims[0].width; step = ims[0].height
out = Image.new('RGB', (W, H))
for i, im in enumerate(ims):
    y = min(i * step, H - im.height)
    out.paste(im, (0, y))
if W > mx: out = out.resize((mx, round(H * mx / W)), Image.LANCZOS)
root = os.path.join(os.path.dirname(__file__), '..')
os.makedirs(root + '/art/sprites/bg', exist_ok=True)
out.save(root + '/art/sprites/bg/%s.jpg' % name, quality=88)
d = root + '/NumberPuzzle/Assets.xcassets/bg/%s.imageset' % name
os.makedirs(d, exist_ok=True)
json.dump({"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": False}}, open(root + '/NumberPuzzle/Assets.xcassets/bg/Contents.json', 'w'))
out.save(d + '/%s.jpg' % name, quality=88)
json.dump({"images": [{"idiom": "universal", "filename": name + ".jpg"}], "info": {"author": "xcode", "version": 1}}, open(d + '/Contents.json', 'w'))
print(name, out.size)
