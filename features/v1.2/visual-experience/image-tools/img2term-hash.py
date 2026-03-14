#!/usr/bin/env python3
"""
FlowerOS Image-to-Terminal Converter (Hash-based Pastel Mode)
Converts images to terminal art using deterministic pastel palette
"""

import os
import sys
import colorsys

def clamp(x, lo, hi):
    return lo if x < lo else hi if x > hi else x

# Pastel palette using golden ratio for hue distribution
GOLDEN = 0.618033988749895

def pastel_rgb_from_bucket(i: int):
    """Generate pastel color from bucket index (0-1027)"""
    h = (i * GOLDEN) % 1.0
    s = 0.30 + 0.15 * ((i * 1315423911) & 0xFF) / 255.0
    v = 0.85 + 0.10 * ((i * 2654435761) & 0xFF) / 255.0
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return int(r * 255), int(g * 255), int(b * 255)

# xterm-256 color levels
LEVELS = [0, 95, 135, 175, 215, 255]

def xterm_index_from_rgb(r: int, g: int, b: int) -> int:
    """Map RGB to xterm-256 color index"""
    def nearest_level(v: int):
        idx = min(range(6), key=lambda k: abs(LEVELS[k] - v))
        return idx, LEVELS[idx]

    ri, rr = nearest_level(r)
    gi, gg = nearest_level(g)
    bi, bb = nearest_level(b)
    cube_code = 16 + 36 * ri + 6 * gi + bi
    cube_dist = (r - rr) ** 2 + (g - gg) ** 2 + (b - bb) ** 2

    gray = (r + g + b) // 3
    gidx = int(round((gray - 8) / 10))
    gidx = clamp(gidx, 0, 23)
    gval = 8 + 10 * gidx
    gray_code = 232 + gidx
    gray_dist = (r - gval) ** 2 + (g - gval) ** 2 + (b - gval) ** 2

    return gray_code if gray_dist < cube_dist else cube_code

def bucket1028(r: int, g: int, b: int) -> int:
    """Hash RGB to bucket 0-1027"""
    x = (r << 16) | (g << 8) | b
    x ^= (x >> 16)
    x = (x * 0x7feb352d) & 0xFFFFFFFF
    x ^= (x >> 15)
    x = (x * 0x846ca68b) & 0xFFFFFFFF
    x ^= (x >> 16)
    return x % 1028

def main():
    if len(sys.argv) < 2:
        print("FlowerOS Image-to-Terminal Converter")
        print("Usage: img2term-hash.py <image> [cols=120]")
        print("\nExample:")
        print("  python3 img2term-hash.py flower.png 140")
        return 1

    path = sys.argv[1]
    path = os.path.expanduser(path)
    
    if not os.path.exists(path):
        print(f"Error: File not found: {path}", file=sys.stderr)
        return 1

    try:
        from PIL import Image
    except Exception:
        print("Error: Pillow not installed", file=sys.stderr)
        print("Install: python3 -m pip install --user pillow", file=sys.stderr)
        return 1

    im = Image.open(path).convert("RGB")
    w, h = im.size

    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 120
    cols = max(10, cols)
    scale = cols / float(w)
    new_w = cols
    new_h = max(2, int(round(h * scale)))
    new_h = (new_h // 2) * 2

    im = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
    px = im.load()

    ESC = "\x1b"
    RST = f"{ESC}[0m"
    def fg(n): return f"{ESC}[38;5;{n}m"
    def bg(n): return f"{ESC}[48;5;{n}m"

    for y in range(0, new_h, 2):
        line = []
        last_pair = None
        for x in range(new_w):
            rt, gt, bt = px[x, y]
            rb, gb, bb = px[x, y + 1]

            btok = bucket1028(rt, gt, bt)
            bbok = bucket1028(rb, gb, bb)

            prt, pgt, pbt = pastel_rgb_from_bucket(btok)
            prb, pgb, pbb = pastel_rgb_from_bucket(bbok)

            ct = xterm_index_from_rgb(prt, pgt, pbt)
            cb = xterm_index_from_rgb(prb, pgb, pbb)
            pair = (ct, cb)

            if pair != last_pair:
                line.append(fg(ct))
                line.append(bg(cb))
                last_pair = pair

            line.append("▀")

        line.append(RST)
        print("".join(line))

    return 0

if __name__ == "__main__":
    sys.exit(main())
