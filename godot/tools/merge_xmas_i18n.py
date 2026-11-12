#!/usr/bin/env python3
"""i18n/work/xmas_*.csv (başlıksız, 10 sütun) satırlarını i18n/strings.csv'ye ekler; var olan anahtar güncellenir."""
import csv, glob, io, os
root = os.path.join(os.path.dirname(__file__), "..")
p = os.path.join(root, "i18n", "strings.csv")
rows = list(csv.reader(open(p, encoding="utf-8")))
idx = {r[0]: i for i, r in enumerate(rows) if r}
n_new = n_upd = 0
for f in sorted(glob.glob(os.path.join(root, "i18n", "work", "xmas_*.csv"))):
    for r in csv.reader(open(f, encoding="utf-8")):
        if not r or r[0] == "keys":
            continue
        assert len(r) == 10, (f, r[0], len(r))
        if r[0] in idx:
            rows[idx[r[0]]] = r; n_upd += 1
        else:
            idx[r[0]] = len(rows); rows.append(r); n_new += 1
buf = io.StringIO(); csv.writer(buf, lineterminator="\n").writerows(rows)
open(p, "w", encoding="utf-8").write(buf.getvalue())
print(f"yeni {n_new}, güncellenen {n_upd}")
