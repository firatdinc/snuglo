#!/usr/bin/env python3
"""Arka plan: tarayıcıda doğal boyutta 4 karo halinde alınan son 4 ekran görüntüsünü (sıra:
(0,0), (-96,0), (0,-391), (-96,-391)) 1536x1024'e birleştirir, 1920x1080'e ölçekleyip kırpar.

Kullanım: tools/stitch_bg.py <ad>   → assets/raw/bg_<ad>.png + assets/bg/<ad>.png
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
name = sys.argv[1]
shots = sorted(glob.glob("/var/folders/*/*/T/claude-chrome-screenshots-*/screenshot-*"), key=lambda f: int(f.rsplit("-", 1)[1].split(".")[0]))[-4:]
c = Image.new("RGB", (1536, 1024))
for f, (x, y) in zip(shots, [(0, 0), (96, 0), (0, 391), (96, 391)]):
    c.paste(Image.open(f).convert("RGB"), (x, y))
c.save(os.path.join(ROOT, "assets", "raw", "bg_%s.png" % name))
out = c.resize((1920, 1280), Image.LANCZOS).crop((0, 120, 1920, 1200))
out.save(os.path.join(ROOT, "assets", "bg", "%s.png" % name))
print("ok", [os.path.basename(s) for s in shots])
