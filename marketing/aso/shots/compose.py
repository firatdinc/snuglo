"""raw/<dil>/sN.png + headlines.json → out/<dil>/<dil>_<i>.jpg (1290x2796)."""
import json, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance
H = os.path.dirname(os.path.abspath(__file__))
ORDER = ["s1", "s2", "s5", "s4", "s8", "s6", "s7", "s3"]
W, HT = 1290, 2796
CREAM, INK = (255, 248, 236), (92, 56, 38)
def font(lang, size):
    if lang == "ja":
        return ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc", size)
    if lang == "ko":
        return ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", size, index=6)
    f = ImageFont.truetype(os.path.expanduser("~/snuglo/godot/art/fonts/Fredoka.ttf"), size)
    try: f.set_variation_by_axes([640])
    except Exception: pass
    return f
from fontTools.ttLib import TTFont
_FC = TTFont(os.path.expanduser("~/snuglo/godot/art/fonts/Fredoka.ttf")).getBestCmap()
def fallback(size):
    f = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", size)
    try: f.set_variation_by_axes([700])
    except Exception: pass
    return f
def runs(lang, line, f, size):
    """Fredoka'da olmayan karakterleri (ör. ş) yuvarlak sistem fontuyla çiz."""
    if lang in ("ja", "ko"):
        return [(line, f)]
    fb = fallback(size); out = []
    for ch in line:
        ff = f if ord(ch) in _FC else fb
        if out and out[-1][1] is ff: out[-1] = (out[-1][0] + ch, ff)
        else: out.append((ch, ff))
    return out
def compose(lang, i, scene, text):
    src = Image.open(f"{H}/raw/{lang}/{scene}.png").convert("RGB")
    # arka plan: kaplanmış, bulanık, hafif açık
    s = max(W / src.width, HT / src.height)
    bg = src.resize((int(src.width * s) + 2, int(src.height * s) + 2), Image.LANCZOS).crop((0, 0, W, HT))
    bg = bg.filter(ImageFilter.GaussianBlur(28))
    bg = ImageEnhance.Brightness(bg).enhance(1.08)
    bg = Image.blend(bg, Image.new("RGB", (W, HT), (250, 232, 214)), 0.18)
    # ekran
    sw = 1040; sh = int(src.height * sw / src.width); top = HT - sh - 70; x = (W - sw) // 2
    shot = src.resize((sw, sh), Image.LANCZOS)
    pad, rad = 20, 74
    sh_l = Image.new("RGBA", (W, HT), (0, 0, 0, 0)); d = ImageDraw.Draw(sh_l)
    d.rounded_rectangle((x - pad, top - pad + 18, x + sw + pad, top + sh + pad + 18), rad + pad, fill=(60, 30, 20, 110))
    sh_l = sh_l.filter(ImageFilter.GaussianBlur(24))
    bg = Image.alpha_composite(bg.convert("RGBA"), sh_l)
    d = ImageDraw.Draw(bg)
    d.rounded_rectangle((x - pad, top - pad, x + sw + pad, top + sh + pad), rad + pad, fill=(255, 255, 255, 255))
    m = Image.new("L", (sw, sh), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, sw, sh), rad, fill=255)
    bg.paste(shot, (x, top), m)
    # başlık
    size = 118 if lang not in ("ja", "ko") else 104
    lines = text.split("\n")
    while True:
        f = font(lang, size)
        if max(sum(d.textlength(t, font=ff) for t, ff in runs(lang, l, f, size)) for l in lines) <= W - 120 or size < 70: break
        size -= 4
    lh = size * 1.12; y0 = (top - pad - len(lines) * lh) / 2 - 6
    for k, l in enumerate(lines):
        rr = runs(lang, l, f, size); tw = sum(d.textlength(t, font=ff) for t, ff in rr); y = y0 + k * lh
        cx = (W - tw) / 2
        for t, ff in rr:
            d.text((cx, y), t, font=ff, fill=CREAM, stroke_width=12, stroke_fill=INK); cx += d.textlength(t, font=ff)
    out = f"{H}/out/{lang}"; os.makedirs(out, exist_ok=True)
    bg.convert("RGB").save(f"{out}/{lang}_{i}.jpg", quality=92)
hl = json.load(open(f"{H}/headlines.json"))
for lang in (sys.argv[1:] or hl):
    for i, (sc, t) in enumerate(zip(ORDER, hl[lang]), 1):
        compose(lang, i, sc, t)
    print("ok", lang)
