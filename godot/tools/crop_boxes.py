#!/usr/bin/env python3
"""Sheet'ten elle verilen kutularla keser: ad=x0,y0,x1,y1 ... ; sonra kırıntı temizliği + kırpma.
Kullanım: tools/crop_boxes.py <sheet.png> <çıktı_dizini> ad=x0,y0,x1,y1 ..."""
import os
import sys
import numpy as np
import scipy.ndimage as ndi
from PIL import Image

src = Image.open(sys.argv[1]).convert("RGBA")
out = sys.argv[2]
for spec in sys.argv[3:]:
    name, box = spec.split("=")
    x0, y0, x1, y1 = (int(v) for v in box.split(","))
    a = np.asarray(src.crop((x0, y0, x1, y1))).copy()
    m = a[..., 3] > 20
    lab, k = ndi.label(ndi.binary_dilation(m, iterations=2))
    if k > 1:
        sizes = ndi.sum(m, lab, range(1, k + 1))
        H, W = m.shape
        for j in range(1, k + 1):
            ys, xs = np.nonzero(lab == j)
            edge = ys.min() == 0 or xs.min() == 0 or ys.max() == H - 1 or xs.max() == W - 1
            if sizes[j - 1] < 0.08 * sizes.max() or (edge and sizes[j - 1] < 0.3 * sizes.max()):
                a[lab == j] = 0
    i = Image.fromarray(a)
    i = i.crop(i.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox())
    i.save(os.path.join(out, name + ".png"))
    print(name, i.size, end="  ")
print()
