#!/usr/bin/env python3
"""Alfali bir sheet'i satir/sutun bosluklarindan kesip sprite'lara ayirir.

Kullanim: tools/slice_sheet.py <sheet.png> <onek> <sutun> <satir> [boyut]
"""
import os
import sys

import numpy as np
import scipy.ndimage as ndi
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")


def bands(counts, thr=2, min_w=20):
    out, st = [], None
    for i, v in enumerate(counts > thr):
        if v and st is None:
            st = i
        elif not v and st is not None:
            out.append((st, i))
            st = None
    if st is not None:
        out.append((st, len(counts)))
    return [b for b in out if b[1] - b[0] > min_w]


def trim(im, pad=4):
    bb = im.split()[3].getbbox()
    if not bb:
        return im
    x0, y0, x1, y1 = bb
    return im.crop((max(0, x0 - pad), max(0, y0 - pad),
                    min(im.width, x1 + pad), min(im.height, y1 + pad)))


def fit(im, size):
    im = im.copy()
    im.thumbnail((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(im, ((size - im.width) // 2, (size - im.height) // 2))
    return out


def main(path, prefix, cols, rows, size=256):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im.split()[3])
    m = a > 120
    xb = bands(m.sum(axis=0))
    yb = bands(m.sum(axis=1))
    if len(xb) != cols or len(yb) != rows:
        raise SystemExit("izgara bulunamadi: %d sutun, %d satir" % (len(xb), len(yb)))
    src = np.asarray(im)
    os.makedirs(SPR, exist_ok=True)
    n = 0
    for (y0, y1) in yb:
        for (x0, x1) in xb:
            pad = 10
            cy0, cy1 = max(0, y0 - pad), min(src.shape[0], y1 + pad)
            cx0, cx1 = max(0, x0 - pad), min(src.shape[1], x1 + pad)
            piece = src[cy0:cy1, cx0:cx1].copy()
            mm = piece[..., 3] > 60
            lab, k = ndi.label(mm)
            if k > 1:
                sizes = ndi.sum(mm, lab, range(1, k + 1))
                keep = int(np.argmax(sizes)) + 1
                piece[..., 3] = np.where(lab == keep, piece[..., 3], 0)
            fit(trim(Image.fromarray(piece, "RGBA")), size).save(
                os.path.join(SPR, "%s_%d.png" % (prefix, n)))
            n += 1
    print("  %s_0..%d.png (%dpx)" % (prefix, n - 1, size))


if __name__ == "__main__":
    p, pre = sys.argv[1], sys.argv[2]
    c, r = int(sys.argv[3]), int(sys.argv[4])
    s = int(sys.argv[5]) if len(sys.argv) > 5 else 256
    main(p, pre, c, r, s)
