#!/usr/bin/env bash
# FlowerOS Image-to-Terminal Converter
# Converts images to beautiful terminal art with pastel colors

set -euo pipefail

img="${1:?Usage: $0 <image> [cols=120] [pastel=0.55] [mode=half|full]}"
cols="${2:-120}"
pastel="${3:-0.55}"
mode="${4:-half}"

command -v python3 >/dev/null || { echo "Error: python3 not found"; exit 1; }

python3 - "$img" "$cols" "$pastel" "$mode" <<'PYTHON'
import sys, math

path = sys.argv[1]
cols = max(10, int(sys.argv[2]))
pastel = float(sys.argv[3])
mode = sys.argv[4].lower()

try:
    from PIL import Image
except Exception as e:
    print("Error: Pillow not installed", file=sys.stderr)
    print("Install: python3 -m pip install --user pillow", file=sys.stderr)
    sys.exit(1)

# Color conversion helpers
def clamp01(x): 
    return 0.0 if x < 0 else (1.0 if x > 1 else x)

def rgb_to_hsl(r,g,b):
    r/=255.0; g/=255.0; b/=255.0
    mx = max(r,g,b); mn = min(r,g,b)
    l = (mx+mn)/2.0
    if mx == mn:
        return 0.0, 0.0, l
    d = mx-mn
    s = d/(2.0-mx-mn) if l > 0.5 else d/(mx+mn)
    if mx == r:
        h = (g-b)/d + (6 if g < b else 0)
    elif mx == g:
        h = (b-r)/d + 2
    else:
        h = (r-g)/d + 4
    h /= 6.0
    return h, s, l

def hsl_to_rgb(h,s,l):
    def hue2rgb(p,q,t):
        t %= 1.0
        if t < 1/6: return p + (q-p)*6*t
        if t < 1/2: return q
        if t < 2/3: return p + (q-p)*(2/3 - t)*6
        return p
    if s == 0.0:
        v = int(round(l*255))
        return v,v,v
    q = l*(1+s) if l < 0.5 else l + s - l*s
    p = 2*l - q
    r = hue2rgb(p,q,h + 1/3)
    g = hue2rgb(p,q,h)
    b = hue2rgb(p,q,h - 1/3)
    return int(round(r*255)), int(round(g*255)), int(round(b*255))

def pastelize(r,g,b, strength):
    """Convert to pastel by desaturating and brightening"""
    h,s,l = rgb_to_hsl(r,g,b)
    s = clamp01(s * (1.0 - 0.75*strength))
    l = clamp01(l + (0.25*strength))
    return hsl_to_rgb(h,s,l)

# xterm-256 color palette
levels = [0, 95, 135, 175, 215, 255]

def xterm_index_from_rgb(r,g,b):
    """Map RGB to xterm-256 color index"""
    def cube(v):
        idx = min(range(6), key=lambda i: abs(levels[i]-v))
        return idx, levels[idx]
    
    ri, rr = cube(r)
    gi, gg = cube(g)
    bi, bb = cube(b)
    cube_code = 16 + 36*ri + 6*gi + bi
    cube_dist = (r-rr)**2 + (g-gg)**2 + (b-bb)**2

    gray = int(round((r+g+b)/3))
    gidx = int(round((gray - 8)/10))
    gidx = 0 if gidx < 0 else (23 if gidx > 23 else gidx)
    gval = 8 + 10*gidx
    gray_code = 232 + gidx
    gray_dist = (r-gval)**2 + (g-gval)**2 + (b-gval)**2

    return gray_code if gray_dist < cube_dist else cube_code

# Load and scale image
im = Image.open(path).convert("RGB")
w,h = im.size
scale = cols / float(w)
new_w = cols
new_h = max(1, int(round(h*scale)))

if mode == "half":
    new_h = max(2, new_h // 2 * 2)

im = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
px = im.load()

# ANSI escape codes
ESC = "\x1b"
RST = f"{ESC}[0m"
def set_fg256(n): return f"{ESC}[38;5;{n}m"
def set_bg256(n): return f"{ESC}[48;5;{n}m"

out_lines = []

if mode == "full":
    # Full block mode
    for y in range(new_h):
        line = []
        last = None
        for x in range(new_w):
            r,g,b = px[x,y]
            r,g,b = pastelize(r,g,b,pastel)
            code = xterm_index_from_rgb(r,g,b)
            if code != last:
                line.append(set_fg256(code))
                last = code
            line.append("█")
        line.append(RST)
        out_lines.append("".join(line))
else:
    # Half-block mode (better quality)
    for y in range(0, new_h, 2):
        line = []
        last_pair = None
        for x in range(new_w):
            rt,gt,bt = px[x,y]
            rb,gb,bb = px[x,y+1]
            rt,gt,bt = pastelize(rt,gt,bt,pastel)
            rb,gb,bb = pastelize(rb,gb,bb,pastel)
            ct = xterm_index_from_rgb(rt,gt,bt)
            cb = xterm_index_from_rgb(rb,gb,bb)
            pair = (ct,cb)
            if pair != last_pair:
                line.append(set_fg256(ct))
                line.append(set_bg256(cb))
                last_pair = pair
            line.append("▀")
        line.append(RST)
        out_lines.append("".join(line))

sys.stdout.write("\n".join(out_lines) + "\n")
PYTHON
