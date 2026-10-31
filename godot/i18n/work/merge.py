"""work/<lang>.json çevirilerini strings.csv'ye sütun olarak ekler, yer tutucuları doğrular."""
import csv, json, re, sys, os
H = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(H, "..", "strings.csv")
LANGS = [("de", "de"), ("fr", "fr"), ("it", "it"), ("pt_BR", "pt"), ("ja", "ja"), ("ko", "ko")]
PH = re.compile(r'%[-0-9.]*[sdif%]|\{[a-z_]+\}|\[/?[a-z]+[^\]]*\]|\n')
rows = list(csv.reader(open(CSV, encoding="utf-8")))
head, body = rows[0], rows[1:]
bad = 0
for src, col in LANGS:
    p = os.path.join(H, src + ".json")
    if not os.path.exists(p):
        print("yok:", src); continue
    t = json.load(open(p, encoding="utf-8"))
    if col in head:
        i = head.index(col)
    else:
        head.append(col); i = len(head) - 1
        for r in body: r.append("")
    for r in body:
        while len(r) <= i: r.append("")
        k, en = r[0], r[1]
        v = t.get(k)
        if v is None:
            print(f"{src}: eksik {k}"); bad += 1; v = en
        if PH.findall(v) != PH.findall(en):
            print(f"{src}: yer tutucu {k}: {en!r} -> {v!r}"); bad += 1
        r[i] = v
w = csv.writer(open(CSV, "w", encoding="utf-8", newline=""), lineterminator="\n")
w.writerow(head); w.writerows(body)
print("sütunlar:", head, "sorun:", bad)
sys.exit(1 if bad else 0)
