# ═══════════════════════════════════════════════════════════════════════════
#  Better Color Mapping (RGB -> nearest pastel ANSI) + caching + dithering
# ═══════════════════════════════════════════════════════════════════════════

from typing import Dict, Tuple, List, Optional

# Precompute approximate RGB for ANSI 256 codes (only for codes in your PASTEL list).
# ANSI 256 palette:
# - 16..231: 6x6x6 color cube
# - 232..255: grayscale ramp
def ansi256_to_rgb(code: int) -> Tuple[int, int, int]:
    if 16 <= code <= 231:
        c = code - 16
        r = c // 36
        g = (c % 36) // 6
        b = c % 6
        # xterm cube values
        steps = [0, 95, 135, 175, 215, 255]
        return steps[r], steps[g], steps[b]
    if 232 <= code <= 255:
        v = 8 + (code - 232) * 10
        return v, v, v
    # 0..15 are system colors; approximate conservatively
    # (We don't use them in PASTEL anyway.)
    return 0, 0, 0


# Build palette RGB table once
PASTEL_RGB: List[Tuple[int, int, int]] = [ansi256_to_rgb(c) for c in PASTEL]

# Cache: pixel rgb -> ansi code
# Key is (r,g,b). Value is ANSI code.
_COLOR_CACHE: Dict[Tuple[int, int, int], int] = {}

def _dist2(a: Tuple[int, int, int], b: Tuple[int, int, int]) -> int:
    dr = a[0] - b[0]
    dg = a[1] - b[1]
    db = a[2] - b[2]
    return dr*dr + dg*dg + db*db

def nearest_pastel_ansi(r: int, g: int, b: int) -> int:
    key = (r, g, b)
    hit = _COLOR_CACHE.get(key)
    if hit is not None:
        return hit

    # Find nearest palette color
    best_i = 0
    best_d = 10**18
    for i, prgb in enumerate(PASTEL_RGB):
        d = _dist2(key, prgb)
        if d < best_d:
            best_d = d
            best_i = i

    code = PASTEL[best_i]
    _COLOR_CACHE[key] = code
    return code


# Ordered dithering (Bayer 4x4). Helps smooth gradients/banding.
# This is gentle: it nudges luma and color slightly.
BAYER4 = (
    (0,  8,  2, 10),
    (12, 4, 14,  6),
    (3, 11,  1,  9),
    (15, 7, 13,  5),
)

def apply_dither(v: int, x: int, y: int, strength: int = 8) -> int:
    # v: 0..255
    # strength ~ 0..24; higher = more visible dithering
    t = BAYER4[y & 3][x & 3]  # 0..15
    # center around 0
    offset = (t - 7.5) / 15.0
    out = int(v + offset * strength)
    return 0 if out < 0 else 255 if out > 255 else out


def image_to_ansi_ascii(img: Image.Image, out_width: int, dither: bool = True) -> str:
    """
    Convert PIL Image to ANSI-colored ASCII art.
    Characters from luma; colors from RGB (nearest pastel match).
    """
    rgb = img.convert("RGB")
    w, h = rgb.size
    if w <= 0 or h <= 0:
        return ""

    # Character-cell aspect correction
    aspect = h / w
    out_height = max(1, int(aspect * out_width * 0.55))

    rgb = rgb.resize((out_width, out_height), resample=Image.BILINEAR)

    # Pull data once
    pixels = list(rgb.getdata())

    # Ramp lookup
    ramp_len = len(RAMP)
    ramp_scale = (ramp_len - 1) / 255.0

    lines: List[str] = []
    p = 0

    for y in range(out_height):
        line_parts: List[str] = []
        for x in range(out_width):
            r, g, b = pixels[p]
            p += 1

            # Luma for character selection (perceptual-ish)
            luma = (77*r + 150*g + 29*b) >> 8  # ~0.299,0.587,0.114

            if dither:
                # gentle dithering to reduce banding
                luma2 = apply_dither(luma, x, y, strength=10)
                # Also nudge channels a bit based on same dither signal
                r2 = apply_dither(r, x, y, strength=6)
                g2 = apply_dither(g, x, y, strength=6)
                b2 = apply_dither(b, x, y, strength=6)
            else:
                luma2 = luma
                r2, g2, b2 = r, g, b

            ch = RAMP[int(luma2 * ramp_scale)]
            col = nearest_pastel_ansi(r2, g2, b2)

            line_parts.append(f"\x1b[38;5;{col}m{ch}")

        line_parts.append(ANSI_RESET)
        lines.append("".join(line_parts))

    return "\n".join(lines) + ANSI_RESET + "\n"
