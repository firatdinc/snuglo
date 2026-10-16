#!/usr/bin/env python3
"""Tarayici yakalamalarindan (beyaz+siyah zemin) alfali sprite sheet kurar.

ChatGPT gorseli tarayicida karo karo buyutulup iki zeminde ekran goruntusu
alinir; burada karolar birlestirilip matte ile gercek alfa cikarilir.

Kullanim:
  tools/capture_import.py <cikti.png> <tileX> <tileY> <cropW> <cropH> \
      w00 b00 w10 b10 w01 b01 w11 b11
Dosya sirasi: satir satir, her karo icin once beyaz sonra siyah.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from matte import matte  # noqa: E402
from PIL import Image  # noqa: E402


def build(out_path, tx, ty, cw, ch, pairs):
    sheet = Image.new("RGBA", (cw * tx, ch * ty), (0, 0, 0, 0))
    k = 0
    for j in range(ty):
        for i in range(tx):
            wp, bp = pairs[k]
            k += 1
            tile = matte(wp, bp, (0, 0, cw, ch))
            sheet.paste(tile, (i * cw, j * ch))
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    sheet.save(out_path)
    print("%s  %dx%d" % (out_path, sheet.width, sheet.height))
    return sheet


if __name__ == "__main__":
    out = sys.argv[1]
    tx, ty, cw, ch = (int(v) for v in sys.argv[2:6])
    files = sys.argv[6:]
    pairs = [(files[i], files[i + 1]) for i in range(0, len(files), 2)]
    build(out, tx, ty, cw, ch, pairs)
