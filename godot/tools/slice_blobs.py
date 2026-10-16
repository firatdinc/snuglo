#!/usr/bin/env python3
"""Alfali sheet'i bağlı bileşenlere göre keser (farklı boyutlu öğeler için).

Yakın parçalar (gölge, bant, düğme) `gap` px genişletmeyle aynı öğeye birleşir.
Sıralama: satır satır (üst kenar), satır içinde soldan sağa.

Kullanim: tools/slice_blobs.py <sheet.png> <cikti_dizini> ad1 ad2 ... [--gap 18] [--max 512]
Ad sayısı bulunan öğe sayısıyla tutmazsa hiçbir şey yazmaz.
"""
import argparse
import os

import numpy as np
import scipy.ndimage as ndi
from PIL import Image


def find(alpha, gap, thr=40):
    m = alpha > thr
    grown = ndi.binary_dilation(m, iterations=gap)
    lab, k = ndi.label(grown)
    boxes = []
    for sl in ndi.find_objects(lab):
        ys, xs = sl
        if (ys.stop - ys.start) * (xs.stop - xs.start) < 900:
            continue
        boxes.append((ys.start, ys.stop, xs.start, xs.stop))
    # satırlara grupla: üst kenarı bir öncekinin yüksekliğinin yarısından yakınsa aynı satır
    boxes.sort(key=lambda b: (b[0] + b[1]) / 2)
    rows, cur = [], []
    for b in boxes:
        if cur and (b[0] + b[1]) / 2 - (cur[0][0] + cur[0][1]) / 2 > (cur[0][1] - cur[0][0]) / 2:
            rows.append(cur)
            cur = []
        cur.append(b)
    if cur:
        rows.append(cur)
    return [b for r in rows for b in sorted(r, key=lambda b: b[2])], lab


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet")
    ap.add_argument("outdir")
    ap.add_argument("names", nargs="+")
    ap.add_argument("--gap", type=int, default=18)
    ap.add_argument("--max", type=int, default=512)
    ap.add_argument("--thr", type=int, default=40)
    ap.add_argument("--grid", default="", help="SxR: düzgün ızgarada hücre hücre kes")
    a = ap.parse_args()
    im = Image.open(a.sheet).convert("RGBA")
    src = np.asarray(im)
    if a.grid:
        gc, gr = (int(v) for v in a.grid.lower().split("x"))
        rows = np.nonzero((src[..., 3] > a.thr).any(1))[0]
        cols = np.nonzero((src[..., 3] > a.thr).any(0))[0]
        y0, y1, x0, x1 = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
        ch, cw = (y1 - y0) / gr, (x1 - x0) / gc
        boxes = [(int(y0 + r * ch), int(y0 + (r + 1) * ch), int(x0 + c * cw), int(x0 + (c + 1) * cw))
                 for r in range(gr) for c in range(gc)]
    else:
        boxes, _ = find(src[..., 3], max(a.gap, 1), a.thr)
    if len(boxes) != len(a.names):
        raise SystemExit("%d öğe bulundu, %d ad verildi" % (len(boxes), len(a.names)))
    os.makedirs(a.outdir, exist_ok=True)
    for (y0, y1, x0, x1), name in zip(boxes, a.names):
        arr = src[y0:y1, x0:x1].copy()
        m = arr[..., 3] > (90 if a.grid else 8)
        lab, k = ndi.label(m)
        if k > 1:
            sizes = ndi.sum(m, lab, range(1, k + 1))
            small = [i + 1 for i, v in enumerate(sizes) if v < 0.02 * sizes.max()]
            if a.grid:  # hücre kenarına değen komşu kırıntıları
                edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
                small += [i for i in edge if sizes[i - 1] < 0.15 * sizes.max()]
            arr[np.isin(lab, small), 3] = 0
        if a.grid:  # kalan öğenin çevresi dışındaki soluk gölgeleri sil
            keep = ndi.binary_dilation(arr[..., 3] > 90, iterations=6)
            arr[~keep, 3] = 0
        piece = Image.fromarray(arr, "RGBA")
        bb = piece.split()[3].point(lambda v: 255 if v > 8 else 0).getbbox()
        if bb:
            piece = piece.crop(bb)
        piece.thumbnail((a.max, a.max), Image.LANCZOS)
        piece.save(os.path.join(a.outdir, name + ".png"))
        print("  %s %dx%d" % (name, piece.width, piece.height))


if __name__ == "__main__":
    main()
