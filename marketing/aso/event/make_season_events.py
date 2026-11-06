"""Sezon In-App Event görselleri (kart 1920x1080, detay 1080x1920), metinsiz.
Arka plan: sezon sahnesi (art/scene/<ad>.jpg, yoksa snow.jpg) bulanık + sıcak ışık;
önde sezon dostları (art/friends). Alt-sol Apple metni için boş bırakılır.
Kullanım: python make_season_events.py  → winter/ ve advent/ klasörleri"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

A = os.path.expanduser("~/snuglo/godot/art")
HERE = os.path.dirname(os.path.abspath(__file__))

EVENTS = {
    "winter": {"scene": "snow", "tint": (214, 230, 245),
               "card": [("reindeer", 1180, 520, 720, 0)],
               "detail": [("reindeer", 540, 960, 820, 0)]},
    "advent": {"scene": "christmas", "tint": (250, 226, 205),
               "card": [("snowman", 700, 620, 460, 6), ("elf", 1650, 600, 440, -6),
                        ("santa", 1160, 500, 640, 0), ("gingerbread", 1400, 820, 330, -5)],
               "detail": [("snowman", 250, 1290, 420, 6), ("elf", 840, 1300, 400, -6),
                          ("gingerbread", 540, 1450, 340, 0), ("santa", 540, 880, 640, 0)]},
}


def scene(name, w, h):
    p = f"{A}/scene/{name}.jpg"
    if not os.path.exists(p):
        p = f"{A}/scene/snow.jpg"
    im = Image.open(p).convert("RGB")
    k = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def glow(c, cx, cy, r, col):
    g = Image.new("L", c.size, 0)
    ImageDraw.Draw(g).ellipse((cx - r, cy - r, cx + r, cy + r), fill=200)
    g = g.filter(ImageFilter.GaussianBlur(r // 3))
    c.paste(Image.new("RGB", c.size, col), (0, 0), g)


def put(c, name, cx, cy, h, rot=0):
    p = f"{A}/raw/{name}.png"
    if not os.path.exists(p):
        print("eksik:", name)
        return
    im = Image.open(p).convert("RGBA")
    im = im.resize((int(im.width * h / im.height), h), Image.LANCZOS)
    if rot:
        im = im.rotate(rot, expand=True, resample=Image.BICUBIC)
    sh = Image.new("RGBA", im.size, (40, 30, 30, 0))
    sh.putalpha(im.getchannel("A").point(lambda a: a * 0.45))
    sh = sh.filter(ImageFilter.GaussianBlur(16))
    c.paste(sh, (int(cx - im.width / 2) + 12, int(cy - im.height / 2) + 26), sh)
    c.paste(im, (int(cx - im.width / 2), int(cy - im.height / 2)), im)


def make(key, ev):
    os.makedirs(f"{HERE}/{key}", exist_ok=True)
    for kind, (w, h), items in (("card", (1920, 1080), ev["card"]), ("detail", (1080, 1920), ev["detail"])):
        c = scene(ev["scene"], w, h).filter(ImageFilter.GaussianBlur(5))
        c = ImageEnhance.Color(c).enhance(0.9)
        c = Image.blend(c, Image.new("RGB", (w, h), ev["tint"]), 0.18)
        big = max(items, key=lambda it: it[3])
        cx, cy = big[1], big[2]
        glow(c, cx, cy, int(min(w, h) * 0.45), (255, 244, 214))
        for it in items:
            put(c, *it)
        out = f"{HERE}/{key}/event_{kind}_{w}x{h}.jpg"
        c.save(out, quality=92)
        print(out)


for k, e in EVENTS.items():
    make(k, e)
