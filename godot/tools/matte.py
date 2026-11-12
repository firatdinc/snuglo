#!/usr/bin/env python3
"""Beyaz + siyah zemin ekran goruntusunden gercek alfa cikarir.

Kompozisyon: C = a*F + (1-a)*B
  beyaz zemin (B=1): Cw = a*F + 1 - a
  siyah zemin (B=0): Cb = a*F
  => a = 1 - (Cw - Cb),  F = Cb / a

Ekran goruntusu JPEG olsa bile iki kareyi cikarmak gurultuyu buyuk olcude
goturur; sonrasinda kucultme kalani temizler.

Kullanim:
  tools/matte.py <beyaz.png> <siyah.png> <cikti.png> [x y w h]
"""
import sys

import numpy as np
from PIL import Image


def matte(white_path, black_path, crop=None):
    w = Image.open(white_path).convert("RGB")
    b = Image.open(black_path).convert("RGB")
    if w.size != b.size:
        b = b.resize(w.size, Image.LANCZOS)
    if crop:
        w = w.crop(crop)
        b = b.crop(crop)
    W = np.asarray(w).astype(np.float32) / 255.0
    B = np.asarray(b).astype(np.float32) / 255.0

    a = 1.0 - np.clip(W - B, 0.0, 1.0)
    alpha = a.mean(axis=-1)
    alpha = np.clip((alpha - 0.02) / 0.96, 0.0, 1.0)

    safe = np.maximum(alpha, 1e-3)[..., None]
    fg = np.clip(B / safe, 0.0, 1.0)

    out = np.concatenate([fg * 255.0, (alpha * 255.0)[..., None]], axis=-1)
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")


if __name__ == "__main__":
    wp, bp, op = sys.argv[1], sys.argv[2], sys.argv[3]
    crop = None
    if len(sys.argv) > 7:
        x, y, cw, ch = (int(v) for v in sys.argv[4:8])
        crop = (x, y, x + cw, y + ch)
    matte(wp, bp, crop).save(op)
    print("yazildi", op)
