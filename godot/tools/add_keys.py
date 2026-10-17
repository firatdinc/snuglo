#!/usr/bin/env python3
"""i18n/strings.csv'ye anahtar ekle (yinelenen anahtarı atlar). Eşzamanlı ajan güvenli (flock).
Kullanım: python3 tools/add_keys.py key "EN" "TR" "ES" [key "EN" "TR" "ES" ...]
Sonra: Godot --headless --path . --import  (çeviriler yeniden derlenir)"""
import csv, sys, pathlib, fcntl, io
p = pathlib.Path(__file__).parent.parent / "i18n/strings.csv"
args = sys.argv[1:]
if len(args) % 4:
    sys.exit("4'lü gruplar: key en tr es")
with open(p, "r+", encoding="utf-8", newline="") as f:
    fcntl.flock(f, fcntl.LOCK_EX)
    rows = list(csv.reader(f))
    have = {r[0] for r in rows[1:]}
    add = []
    for i in range(0, len(args), 4):
        k = args[i]
        if k in have:
            print("var:", k); continue
        have.add(k); add.append(args[i:i+4])
    f.seek(0, 2)
    if add:
        f.seek(f.tell() - 1); last = f.read(1)
        if last != "\n": f.write("\n")
        w = csv.writer(f, lineterminator="\n")
        for r in add: w.writerow(r); print("+", r[0])
    fcntl.flock(f, fcntl.LOCK_UN)
