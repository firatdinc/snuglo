"""In-App Event görselleri: kart 1920x1080, detay 1080x1920. Metin yok (Apple ad/aciklamayi ustune yazar)."""
import glob, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
A = os.path.expanduser("~/snuglo/godot/art")
FAB = sorted(f for f in glob.glob(f"{A}/fabric/classic/*") if f.endswith((".png", ".jpg")))
def patchwork(w, h, s=240, seed=3):
    random.seed(seed); c = Image.new("RGB", (w, h))
    for y in range(0, h, s):
        for x in range(0, w, s):
            t = Image.open(random.choice(FAB)).convert("RGB").resize((s, s), Image.LANCZOS)
            c.paste(t, (x, y))
    d = ImageDraw.Draw(c)
    for x in range(0, w, s):  # dikiş çizgileri
        for y in range(0, h, 28): d.line((x, y, x, y + 14), fill=(255, 246, 230), width=4)
    for y in range(0, h, s):
        for x in range(0, w, 28): d.line((x, y, x + 14, y), fill=(255, 246, 230), width=4)
    c = ImageEnhance.Color(c).enhance(0.85)
    return Image.blend(c, Image.new("RGB", (w, h), (250, 228, 205)), 0.28)
def glow(c, cx, cy, r):
    g = Image.new("L", c.size, 0); ImageDraw.Draw(g).ellipse((cx - r, cy - r, cx + r, cy + r), fill=210)
    g = g.filter(ImageFilter.GaussianBlur(r // 3))
    c.paste(Image.new("RGB", c.size, (255, 244, 214)), (0, 0), g)
def put(c, path, cx, cy, h, rot=0):
    im = Image.open(path).convert("RGBA"); im = im.resize((int(im.width * h / im.height), h), Image.LANCZOS)
    if rot: im = im.rotate(rot, expand=True, resample=Image.BICUBIC)
    sh = Image.new("RGBA", im.size, (60, 30, 20, 0)); sh.putalpha(im.getchannel("A").point(lambda a: a * 0.45))
    sh = sh.filter(ImageFilter.GaussianBlur(14))
    c.paste(sh, (int(cx - im.width / 2) + 10, int(cy - im.height / 2) + 22), sh)
    c.paste(im, (int(cx - im.width / 2), int(cy - im.height / 2)), im)
# kart 16:9 — önemli öğeler orta/üst-sağ, alt-sol Apple metni için boş
card = patchwork(1920, 1080); glow(card, 1180, 470, 470)
put(card, f"{A}/ui/ic_calendar.png", 820, 400, 300, 8)
put(card, f"{A}/mascot/cheer.png", 1200, 500, 640)
put(card, f"{A}/ui/chest_open.png", 1600, 640, 330, -6)
card.save("event_card_1920x1080.jpg", quality=92)
# detay 9:16
det = patchwork(1080, 1920, s=216, seed=7); glow(det, 540, 880, 520)
put(det, f"{A}/ui/ic_calendar.png", 300, 520, 300, 8)
put(det, f"{A}/mascot/cheer.png", 560, 900, 700)
put(det, f"{A}/ui/chest_open.png", 790, 1280, 330, -6)
det.save("event_detail_1080x1920.jpg", quality=92)
print("ok")
