"""Kozmetik setleri: klasik ChatGPT dokularını yeniden renklendirerek üretir (desen aynı kalır).
- Kumaş setleri: art/fabric/classic/fNN.png → art/fabric/<set>/fNN.png (12 hedef renk / set)
- Tahtalar:      art/board/frame.png → art/board/<id>.png
- scripts/game/fabric_colors.gd: setlerin gerçek medyan renkleri (gölge/hayalet/rakam için)
Yöntem: HSV'de ton kaydırma + doygunluk/parlaklık gamma eşlemesi (medyan → hedef).
Kullanım: python3 tools/make_cosmetic_sets.py   (godot/ kökünden)"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAB = f"{ROOT}/art/fabric"
BOARD = f"{ROOT}/art/board"

# 12 renk; komşu indeksler ton+parlaklıkça ayrışsın (oyunda yan yana parçalar).
FABRIC_SETS = {
    "meadow":   ["e8828f", "f2c14e", "7cc4a4", "6f9fd8", "b483c9", "f7b7a3", "4f9a7c", "ef8a5b", "a3b84f", "8f7fd1", "d9a066", "5fb4c9"],
    "berry":    ["3f6fa8", "7a4f9a", "2f8f9a", "5a84c4", "9a3f6f", "8fb6d9", "2f5f6f", "c45a7a", "4f6f4f", "a08fd0", "6f4f8f", "4fa8c4"],
    "denim":    ["4a5f7a", "8a9aae", "3a4a5a", "6f87a8", "5a5f6a", "b0bccb", "2f3f52", "7a8a9a", "4f5a6f", "9fb0c8", "606a78", "3f5a7f"],
    "sunset":   ["e0603f", "f2a03f", "9a3f4f", "f2c46f", "c4505a", "f7c9a8", "7a3a2f", "e8846f", "b0702f", "d97a9a", "8f4f3a", "f0b04f"],
    "aurora":   ["3fb08f", "6f5fc4", "2f8fb0", "8fd0a0", "9a5fb0", "a8e0d0", "2f6f6f", "5fa0e0", "4f9a5f", "c48fe0", "3f5f8f", "7fc0c0"],
    "midnight": ["2f3f6f", "8f2f4f", "1f5f4f", "c4963f", "4f2f6f", "6f7fa8", "1f2f3f", "a8483f", "3f5f2f", "7f5f9f", "5f3f2f", "2f6f8f"],
    "blossom":  ["f2a0b4", "e86f8f", "f7d6c4", "c9a0d9", "a8c4a0", "f7c4d0", "d9708a", "fbe0a8", "b4d0e0", "e0a0c0", "9ab88f", "f0b8a0"],
}

# Tahta temaları: iç kumaş hedef rengi + ahşap (ton kaydırma°, doygunluk ×, parlaklık ×).
BOARDS = {
    "parchment": None,
    "dawn":      ("f6d9c8", (0, 0.9, 1.08)),
    "forest":    ("cfdcbc", (-4, 0.85, 0.72)),
    "night":     ("aeb0c8", (0, 0.45, 0.48)),
    "dusk":      ("d5c6df", (-6, 0.8, 0.9)),
    "rose":      ("f1cdd0", (0, 0.45, 1.18)),
    "meadow":    ("dde9c4", (6, 0.8, 1.12)),
    "twilight":  ("9c9abf", (-8, 0.55, 0.42)),
    "ember":     ("e6b896", (-10, 1.15, 0.7)),
}


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = a.max(-1)
    mn = a.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rc = np.where(m, (mx - r) / np.where(m, d, 1), 0)
    gc = np.where(m, (mx - g) / np.where(m, d, 1), 0)
    bc = np.where(m, (mx - b) / np.where(m, d, 1), 0)
    h = np.where(r == mx, bc - gc, np.where(g == mx, 2 + rc - bc, 4 + gc - rc))
    h = np.where(m, (h / 6.0) % 1.0, 0)
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1), 0)
    return h, s, mx


def hsv_to_rgb(h, s, v):
    i = np.floor(h * 6).astype(int) % 6
    f = h * 6 - np.floor(h * 6)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    r = np.choose(i, [v, q, p, p, t, v])
    g = np.choose(i, [t, v, v, q, p, p])
    b = np.choose(i, [p, p, t, v, v, q])
    return np.stack([r, g, b], -1)


def gamma_map(x, x0, x1):
    x0 = min(max(x0, 0.02), 0.98)
    x1 = min(max(x1, 0.02), 0.98)
    return np.clip(x, 0, 1) ** (math.log(x1) / math.log(x0))


def recolor(im, dh, s0, s1, v0, v1):
    a = np.asarray(im).astype(np.float32) / 255.0
    rgb, alpha = a[..., :3], a[..., 3:] if a.shape[-1] == 4 else None
    h, s, v = rgb_to_hsv(rgb)
    h = (h + dh) % 1.0
    s = gamma_map(s, s0, s1)
    v = gamma_map(v, v0, v1)
    out = hsv_to_rgb(h, s, v)
    if alpha is not None:
        out = np.concatenate([out, alpha], -1)
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), im.mode)


def median_hsv(im):
    a = np.asarray(im.convert("RGB")).astype(np.float32).reshape(-1, 3) / 255.0
    med = np.median(a, 0)
    h, s, v = rgb_to_hsv(med[None, :])
    # Ton için ortalama vektör (dairesel) — doygun pikseller ağırlıklı
    H, S, V = rgb_to_hsv(a)
    ang = H * 2 * math.pi
    hh = (math.atan2((np.sin(ang) * S).sum(), (np.cos(ang) * S).sum()) / (2 * math.pi)) % 1.0
    return hh, float(np.median(S)), float(np.median(V))


def hex_hsv(hx):
    c = np.array([int(hx[i:i + 2], 16) for i in (0, 2, 4)], np.float32)[None, :] / 255.0
    h, s, v = rgb_to_hsv(c)
    return float(h[0]), float(s[0]), float(v[0])


def med_hex(im):
    a = np.asarray(im.convert("RGB")).reshape(-1, 3)
    m = np.median(a, 0).astype(int)
    return "%02x%02x%02x" % tuple(m)


def _wood_mask(w, ins):
    m = Image.new("L", (w, w), 255)
    ImageDraw.Draw(m).rectangle((ins, ins, w - ins, w - ins), fill=0)
    return m


def main():
    colors = {}
    for sid, targets in FABRIC_SETS.items():
        os.makedirs(f"{FAB}/{sid}", exist_ok=True)
        cols = []
        for i, hx in enumerate(targets):
            src = Image.open(f"{FAB}/classic/f{i:02d}.png")
            h0, s0, v0 = median_hsv(src)
            h1, s1, v1 = hex_hsv(hx)
            out = recolor(src, h1 - h0, s0, s1, v0, v1)
            out.save(f"{FAB}/{sid}/f{i:02d}.png", optimize=True)
            cols.append(med_hex(out))
        colors[sid] = cols
        print(sid, cols)
    frame = Image.open(f"{BOARD}/frame.png").convert("RGBA")
    W = frame.width
    ins = 92 + 6  # frame.json inner + kenar payı
    cloth_box = (ins, ins, W - ins, W - ins)
    cloth = frame.crop(cloth_box)
    wa = np.asarray(frame)
    wsel = (np.asarray(_wood_mask(W, ins)) > 0) & (wa[..., 3] > 200)
    wood_med = median_hsv(Image.fromarray(wa[wsel][None, :, :3]))
    mask = _wood_mask(W, ins).filter(ImageFilter.GaussianBlur(3))
    for bid, t in BOARDS.items():
        if t is None:
            continue
        hx, (dh, sk, vk) = t
        _, s0, v0 = wood_med
        wood = recolor(frame, dh / 360.0, s0, min(s0 * sk, 0.95), v0, min(v0 * vk, 0.95))
        h0, cs0, cv0 = median_hsv(cloth)
        h1, cs1, cv1 = hex_hsv(hx)
        cl = recolor(frame, h1 - h0, cs0, cs1, cv0, cv1)
        out = Image.composite(wood, cl, mask)
        out.save(f"{BOARD}/{bid}.png", optimize=True)
        print("board", bid)
    with open(f"{ROOT}/scripts/game/fabric_colors.gd", "w") as f:
        f.write("class_name FabricColors\nextends RefCounted\n")
        f.write("## OTOMATİK: tools/make_cosmetic_sets.py üretir. Setlerin dokulardan ölçülen medyan renkleri.\n\n")
        f.write("const SETS := {\n")
        for sid, cols in colors.items():
            f.write('\t"%s": [%s],\n' % (sid, ", ".join('Color("%s")' % c for c in cols)))
        f.write("}\n")


if __name__ == "__main__":
    main()
