"""4 beyaz karo (2x2, satır satır) → birleştir → kenardan flood fill ile beyaz zemini sil → alfa PNG.
Kullanım: cut_white.py out.png tile0 tile1 tile2 tile3 [tol]"""
import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
out, tiles = sys.argv[1], sys.argv[2:6]
tol = float(sys.argv[6]) if len(sys.argv) > 6 else 14
T = 627
im = Image.new("RGB", (2 * T, 2 * T))
for k, f in enumerate(tiles):
    t = Image.open(f).convert("RGB").resize((T, T), Image.LANCZOS)
    im.paste(t, ((k % 2) * T, (k // 2) * T))
a = np.asarray(im).astype(np.float32)
dist = np.sqrt(((255 - a) ** 2).sum(-1))       # beyazdan uzaklık
near = dist < tol
lab, _ = ndimage.label(near)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(border))
alpha = (~bg).astype(np.float32)
# yumuşak kenar: 1.2 px blur + kenardaki beyazlığa göre kısmi alfa
soft = np.clip(dist / (tol * 2.5), 0, 1)
edge = ndimage.binary_dilation(bg, iterations=2) & ~bg
alpha[edge] = np.minimum(alpha[edge], np.maximum(soft[edge], 0.0))
alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32) / 255
alpha[bg & ~ndimage.binary_dilation(~bg, iterations=1)] = 0
# kenar renginden beyaz sızıntısını çıkar (premultiply tersi)
rgb = a.copy()
m = (alpha > 0.02) & (alpha < 0.98)
rgb[m] = np.clip((a[m] - 255 * (1 - alpha[m, None])) / alpha[m, None], 0, 255)
o = np.dstack([rgb, alpha * 255]).astype(np.uint8)
res = Image.fromarray(o, "RGBA")
res = res.crop(res.getbbox())
res.save(out)
print(out, res.size)
