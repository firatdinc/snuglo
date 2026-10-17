#!/usr/bin/env python3
"""i18n/strings.csv denetimi: her anahtarın en/tr/es değeri var mı, yer tutucu paritesi
(%s/%d sırası ve sayısı) aynı mı, yinelenen anahtar var mı. Hata varsa çıkış kodu 1.
Kullanım: python3 tools/check_i18n.py [yol]"""
import csv, re, sys, pathlib

path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).parent.parent / "i18n/strings.csv")
SPEC = re.compile(r"%(?:%|[-+ 0#]*\d*(?:\.\d+)?[sdifxXc])")
BAD = re.compile(r"%(?:\d+\$|l+d|@)")  # Swift kalıntısı

rows = list(csv.reader(open(path, encoding="utf-8")))
header, body = rows[0], rows[1:]
errors = []
if header[:1] != ["keys"] or not {"en", "tr", "es"} <= set(header):
    errors.append(f"başlık hatalı: {header}")
langs = header[1:]
seen = set()
for n, r in enumerate(body, start=2):
    if len(r) != len(header):
        errors.append(f"satır {n}: {len(r)} sütun (beklenen {len(header)})")
        continue
    key, vals = r[0], dict(zip(langs, r[1:]))
    if key in seen:
        errors.append(f"yinelenen anahtar: {key}")
    seen.add(key)
    ref = [s for s in SPEC.findall(vals.get("en", "")) if s != "%%"]
    for l in langs:
        v = vals.get(l, "")
        if not v.strip():
            errors.append(f"{key}: '{l}' boş")
        if BAD.search(v):
            errors.append(f"{key}/{l}: Swift biçimi kalmış: {v!r}")
        got = [s for s in SPEC.findall(v) if s != "%%"]
        if got != ref:
            errors.append(f"{key}/{l}: yer tutucu {got} != en {ref}")
for e in errors:
    print("HATA", e)
print(f"{len(seen)} anahtar, {len(langs)} dil, {len(errors)} hata")
sys.exit(1 if errors else 0)
