#!/usr/bin/env python3
"""
split_screenshots.py — Split a composite App Store promo image (several
phone panels side-by-side on a dark background, separated by a light-gray
divider bar + a navy gap) into individual App Store screenshots.

Target: iPhone 6.5" display — 1242 x 2688 px (portrait).

Approach (no padding, no stretching, no sharpening):
  1. Find the light-gray divider bars (a unique neutral ~#E5E5E5 that never
     occurs in the navy / cream panel backgrounds) — pixel-accurate anchors.
  2. Each panel is the vertical slot BETWEEN two dividers: from the end of
     the previous gray bar to the start of the next one. The gray bars are
     excluded; the thin navy gap stays as a natural side margin. Because the
     panels were laid out on an even pitch, every slot comes out at almost
     exactly the 1242:2688 aspect, so a direct resize introduces no visible
     distortion and nothing is cropped or padded.
  3. Resize each slot to 1242 x 2688 with LANCZOS and save lossless PNG.

Usage:
    python3 split_screenshots.py <source.png> <out_dir> [--panels 5]
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    sys.exit("Pillow + numpy required: pip install 'pillow>=10' 'numpy>=1.24'")


def gray_bar_bands(a, W, n_panels):
    """Column ranges of the light-gray divider bars (neutral, full height)."""
    R, G, B = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    neutral = (np.abs(R - G) < 14) & (np.abs(G - B) < 14) & (R > 200) & (R < 248)
    frac = neutral.mean(axis=0)
    is_bar = frac > 0.7                       # near-full-height bars only
    bands, x = [], 0
    while x < W:
        if is_bar[x]:
            s = x
            while x < W and is_bar[x]:
                x += 1
            bands.append((s, x))
        else:
            x += 1
    bands = [(s, e) for (s, e) in bands if (e - s) >= 6]
    if len(bands) <= n_panels - 1:
        return bands
    widths = sorted(e - s for s, e in bands)
    med = widths[len(widths) // 2]            # real dividers share one width
    near = [(s, e) for (s, e) in bands if abs((e - s) - med) <= 6]
    return near if len(near) == n_panels - 1 else bands


def panel_boxes(a, W, n_panels):
    """Slot x-ranges between dividers (gray bars excluded)."""
    bars = gray_bar_bands(a, W, n_panels)
    if len(bars) != n_panels - 1:
        return None
    starts = [s for s, e in bars]
    ends = [e for s, e in bars]
    # interior slot width (gray-bar end -> next gray-bar start) is uniform;
    # use its median for the two edge panels too.
    widths = [starts[i + 1] - ends[i] for i in range(len(bars) - 1)]
    slot = int(round(sorted(widths)[len(widths) // 2])) if widths else W // n_panels
    lefts = [max(0, starts[0] - slot)] + ends
    rights = starts + [min(W, ends[-1] + slot)]
    return list(zip(lefts, rights))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("out_dir")
    ap.add_argument("--panels", type=int, default=5)
    ap.add_argument("--width", type=int, default=1242)
    ap.add_argument("--height", type=int, default=2688)
    args = ap.parse_args()

    src = Path(args.source).expanduser()
    out = Path(args.out_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)

    im = Image.open(src).convert("RGB")
    W, H = im.size
    a = np.asarray(im).astype(int)

    boxes = panel_boxes(a, W, args.panels)
    if boxes is None:
        step = W / args.panels
        boxes = [(round(i * step), round((i + 1) * step))
                 for i in range(args.panels)]
        mode = "equal-split (fallback)"
    else:
        mode = "divider-aligned slots"

    print(f"Source {W}x{H} -> {args.panels} panels [{mode}]")
    for i, (x0, x1) in enumerate(boxes, 1):
        panel = im.crop((x0, 0, x1, H)).resize((args.width, args.height), Image.LANCZOS)
        dest = out / f"{i}.png"
        panel.save(dest, "PNG")
        print(f"  panel {i}: x[{x0}:{x1}] w={x1 - x0} (ar={(x1-x0)/H:.3f}) -> {dest.name}")
    print(f"Done. {args.panels} files in {out}")


if __name__ == "__main__":
    main()
