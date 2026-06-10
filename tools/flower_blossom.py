#!/usr/bin/env python3
"""
FlowerOS Image to ASCII Converter - Pastel 256-Color
Botanical naming: "flower_blossom" - transforms images into blooming ASCII art

Part of FlowerOS v1.3.0 Universal Compute System
Batch convert images to ANSI 256-color "pastel" ASCII.

View output with:
  cat ascii_out/file.ansi.txt
or (recommended):
  less -R ascii_out/file.ansi.txt

Flags:
  --identify   After conversion, identify plants via Calflora DB
"""

import sys
from pathlib import Path

# Add lib to path for banner + compact encoding libraries
sys.path.insert(0, str(Path(__file__).parent.parent / "lib"))

try:
    from banners import *
except ImportError:
    # Fallback if lib/banners.py not available
    _FOS_RED = "\x1b[31m"
    _FOS_YELLOW = "\x1b[33m"
    _FOS_CYAN = "\x1b[36m"
    _FOS_RESET = "\x1b[0m"
    def fos_status_fail(msg): print(f"{_FOS_RED}✗ {msg}{_FOS_RESET}")
    def fos_banner_error(msg): print(f"{_FOS_RED}ERROR: {msg}{_FOS_RESET}", file=sys.stderr)

try:
    from PIL import Image
except ImportError:
    fos_banner_error("Missing dependency: Pillow")
    print(f"{_FOS_YELLOW}Install: python3 -m pip install pillow{_FOS_RESET}")
    print(f"{_FOS_CYAN}Or: sudo apt-get install python3-pil{_FOS_RESET}")
    sys.exit(1)

from compact_encoding import CompactEncoder, encode_fca, decode_fca, encoding_stats

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Configuration
# ═══════════════════════════════════════════════════════════════════════════

FLOWEROS_VERSION = "1.3.0"
TOOL_NAME = "flower_blossom"

# Character ramp (dark -> light) - botanical progression
# Seeds → Roots → Stems → Leaves → Flowers → Full bloom
RAMP = "@%#*+=-:. "

# A hand-picked "pastel-ish" 256-color palette (foreground).
# These are mostly light, soft tones from the 6x6x6 cube and some light grays.
# Theme: Soft garden colors (petals, leaves, sky)
PASTEL = [
    231, 230, 229, 228, 227,  # near-white / warm whites (full bloom)
    225, 224, 223, 222,       # lavender / pale purples (flower petals)
    195, 194, 193,            # mint / pale green (leaves)
    159, 158, 157,            # pale cyan (morning dew)
    189, 188, 187,            # pink-ish / soft magenta (roses)
    186, 185, 184,            # peach / soft orange (sunset petals)
    152, 151, 150,            # soft blue-gray (garden stones)
    254, 253, 252,            # light grays (clouds)
]

ANSI_RESET = "\x1b[0m"

# ═══════════════════════════════════════════════════════════════════════════
#  Core Conversion Functions
# ═══════════════════════════════════════════════════════════════════════════

def color_for_luma(luma: int) -> int:
    """
    Map 0..255 brightness to a pastel palette color.
    Darker pixels -> slightly deeper pastel; brighter -> near-white.
    
    Think of it as: seed → sprout → bloom (darkness → light)
    """
    idx = int((luma / 255.0) * (len(PASTEL) - 1))
    return PASTEL[idx]


def image_to_ansi_ascii(img: Image.Image, out_width: int, *, compact: bool = True) -> str:
    """
    Convert PIL Image to ANSI-colored ASCII art.

    This is the "blooming" process - transforming pixels into characters.
    Uses the compact encoding kernel when compact=True (default) to
    eliminate redundant ANSI escape codes via delta-colour + RLE.
    """
    gray = img.convert("L")
    w, h = gray.size
    if w <= 0 or h <= 0:
        return ""

    # Aspect correction for character cells (garden plot dimensions)
    aspect = h / w
    out_height = max(1, int(aspect * out_width * 0.55))

    gray = gray.resize((out_width, out_height))

    pixels = list(gray.getdata())
    scale = (len(RAMP) - 1) / 255.0

    # Compact encoding path — delta colour + run-length
    if compact:
        enc = CompactEncoder(rle=True)
        p = 0
        for _ in range(out_height):
            enc.begin_line()
            for _ in range(out_width):
                luma = pixels[p]
                p += 1
                ch  = RAMP[int(luma * scale)]
                col = color_for_luma(luma)
                enc.put(ch, col)
            enc.end_line()
        return enc.finish()

    # Naive fallback (one escape per cell)
    lines = []
    p = 0
    for _ in range(out_height):
        line_parts = []
        for _ in range(out_width):
            luma = pixels[p]
            p += 1

            ch = RAMP[int(luma * scale)]
            col = color_for_luma(luma)

            # 256-color foreground: ESC[38;5;{n}m
            line_parts.append(f"\x1b[38;5;{col}m{ch}")
        line_parts.append(ANSI_RESET)  # reset at end of line
        lines.append("".join(line_parts))

    return "\n".join(lines) + ANSI_RESET + "\n"


def collect_images(args):
    """
    Collect all image files from arguments (files or directories).
    
    "Gathering seeds from the garden."
    """
    exts = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}
    paths = []
    for a in args:
        p = Path(a).expanduser()
        if p.is_dir():
            paths += [f for f in sorted(p.rglob("*")) if f.suffix.lower() in exts and f.is_file()]
        elif p.is_file() and p.suffix.lower() in exts:
            paths.append(p)
        else:
            print(f"{ANSI_YELLOW}⚠ Skipping:{ANSI_RESET} {p}")
    
    # De-duplicate
    seen = set()
    out = []
    for p in paths:
        rp = str(p.resolve())
        if rp not in seen:
            seen.add(rp)
            out.append(p)
    return out


# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Banner
# ═══════════════════════════════════════════════════════════════════════════

def print_banner():
    """Display FlowerOS branding using banner library."""
    fos_banner_title(
        f"FlowerOS v{FLOWEROS_VERSION} - Image to ASCII",
        "Pastel 256-Color Converter",
        "🌸",
        "🌸"
    )
    print(f"{_FOS_GREEN}Tool:{_FOS_RESET} {TOOL_NAME} - Transform images into blooming ASCII art")
    print(f"{_FOS_GREEN}Mode:{_FOS_RESET} Batch processing (Universal Runner System)")
    print()


def print_help():
    """Display usage information."""
    print_banner()
    fos_banner_header("USAGE", _FOS_YELLOW)
    print(f"  {_FOS_CYAN}python3 {TOOL_NAME}.py <img_or_dir> [more_imgs_or_dirs...]{_FOS_RESET}")
    print()

    fos_banner_header("EXAMPLES", _FOS_YELLOW)
    print(f"  {_FOS_CYAN}# Single image{_FOS_RESET}")
    print(f"  python3 {TOOL_NAME}.py photo.jpg")
    print()
    print(f"  {_FOS_CYAN}# Directory of images{_FOS_RESET}")
    print(f"  python3 {TOOL_NAME}.py /path/to/images/")
    print()
    print(f"  {_FOS_CYAN}# Multiple files and directories{_FOS_RESET}")
    print(f"  python3 {TOOL_NAME}.py photo1.png photo2.jpg /path/to/more/")
    print()

    fos_banner_header("VIEWING OUTPUT", _FOS_YELLOW)
    print(f"  {_FOS_CYAN}# Recommended: less with color support{_FOS_RESET}")
    print(f"  less -R ascii_out/*.ansi.txt")
    print()
    print(f"  {_FOS_CYAN}# Alternative: cat (may scroll too fast){_FOS_RESET}")
    print(f"  cat ascii_out/image.ansi.txt")
    print()

    fos_banner_header("SUPPORTED FORMATS", _FOS_YELLOW)
    print(f"  {_FOS_GREEN}✓{_FOS_RESET} PNG, JPG/JPEG, BMP, GIF, WebP")
    print()


# ═══════════════════════════════════════════════════════════════════════════
#  Main Execution
# ═══════════════════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) < 2 or sys.argv[1] in {"-h", "--help", "help"}:
        print_help()
        sys.exit(0 if len(sys.argv) < 2 else 0)

    # Check for --identify flag
    raw_args = list(sys.argv[1:])
    do_identify = "--identify" in raw_args
    raw_args = [a for a in raw_args if a != "--identify"]

    print_banner()

    # Collect all images ("gathering seeds")
    print(f"{_FOS_YELLOW}🌱 Gathering images...{_FOS_RESET}")
    images = collect_images(raw_args)

    if not images:
        fos_status_fail("No images found")
        print(f"{_FOS_CYAN}Supported formats:{_FOS_RESET} .png .jpg .jpeg .bmp .gif .webp")
        sys.exit(2)

    fos_status_ok(f"Found {len(images)} image(s)")
    print()

    # Get output width (user input)
    fos_banner_header("CONFIGURATION", _FOS_YELLOW)
    while True:
        try:
            width_input = input(f"{_FOS_CYAN}Output ASCII width{_FOS_RESET} (10-500, recommend 120): ").strip()
            if not width_input:
                out_width = 120  # Default
                print(f"  → Using default: {out_width}")
                break
            out_width = int(width_input)
            if not (10 <= out_width <= 500):
                fos_status_warn("Pick something sane: 10..500")
                continue
            break
        except ValueError:
            fos_status_fail("Enter an integer")
        except KeyboardInterrupt:
            print(f"\n{_FOS_YELLOW}✗ Cancelled by user{_FOS_RESET}")
            sys.exit(130)

    # Create output directory
    out_dir = Path("ascii_out")
    out_dir.mkdir(parents=True, exist_ok=True)

    print()
    fos_banner_header("BLOOMING (Processing)", _FOS_YELLOW)

    # Process each image ("blooming" process)
    success_count = 0
    fail_count = 0
    total_naive = 0
    total_compact = 0

    for i, img_path in enumerate(images, 1):
        try:
            with Image.open(img_path) as im:
                # Compact-encoded ANSI output (delta colour + RLE)
                ansi = image_to_ansi_ascii(im, out_width, compact=True)
                # Also generate naive size for comparison stats
                naive = image_to_ansi_ascii(im, out_width, compact=False)

            out_path = out_dir / f"{img_path.stem}.ansi.txt"
            out_path.write_text(ansi, encoding="utf-8")

            # Optional: write .fca compact binary alongside
            fca_path = out_dir / f"{img_path.stem}.fca"
            gray = Image.open(img_path).convert("L")
            w, h = gray.size
            aspect = h / w
            oh = max(1, int(aspect * out_width * 0.55))
            gray = gray.resize((out_width, oh))
            px = list(gray.getdata())
            cols = [color_for_luma(l) for l in px]
            fca_path.write_bytes(encode_fca(px, cols, out_width, oh, RAMP))

            total_naive += len(naive.encode("utf-8"))
            total_compact += len(ansi.encode("utf-8"))

            stats = encoding_stats(len(naive.encode("utf-8")), len(ansi.encode("utf-8")))
            print(f"{ANSI_GREEN}✓ [{i}/{len(images)}]{ANSI_RESET} {img_path.name} → {out_path.name}  {stats}")
            success_count += 1

        except Exception as e:
            print(f"{ANSI_RED}✗ [{i}/{len(images)}]{ANSI_RESET} FAILED {img_path.name}: {e}")
            fail_count += 1

    # Summary
    print()
    print(f"{ANSI_MAGENTA}═══════════════════════════════════════════════════════════════════════════{ANSI_RESET}")
    print()
    print(f"{ANSI_CYAN}🌸 Blooming Complete{ANSI_RESET}")
    print()
    print(f"  {ANSI_GREEN}✓ Success:{ANSI_RESET} {success_count} image(s)")
    if fail_count > 0:
        print(f"  {ANSI_RED}✗ Failed:{ANSI_RESET}  {fail_count} image(s)")
    print(f"  {ANSI_CYAN}📁 Output:{ANSI_RESET}  {out_dir}/")
    if total_naive > 0:
        print(f"  {ANSI_CYAN}📦 Encoding:{ANSI_RESET} {encoding_stats(total_naive, total_compact)}")
    print()
    print(f"{ANSI_YELLOW}View with:{ANSI_RESET}")
    print(f"  less -R ascii_out/*.ansi.txt")
    print()
    print(f"{ANSI_MAGENTA}═══════════════════════════════════════════════════════════════════════════{ANSI_RESET}")
    print()
    
    print(f"{ANSI_GREEN}Every image is a seed waiting to bloom into ASCII art. 🌸{ANSI_RESET}")
    print()

    # --- Plant Identification (Calflora DB) ---
    if do_identify:
        try:
            import plant_identify
            import calflora_db

            print()
            print(f"{ANSI_CYAN}🌿 Running plant identification via Calflora DB...{ANSI_RESET}")
            print()

            # Ensure DB is seeded
            conn = calflora_db._ensure_db()
            calflora_db.seed_database(conn)
            total = conn.execute("SELECT COUNT(*) FROM taxa").fetchone()[0]
            conn.close()
            print(f"{ANSI_GREEN}✓ Calflora DB loaded — {total} taxa{ANSI_RESET}")

            identified = 0
            for img_path in images:
                results = plant_identify.identify_image(img_path)
                plant_identify.print_identification(img_path, results)
                if results:
                    identified += 1

            print()
            print(f"{ANSI_CYAN}🌸 Identified {identified}/{len(images)} image(s){ANSI_RESET}")

        except ImportError as e:
            print(f"{ANSI_RED}✗ Identification unavailable: {e}{ANSI_RESET}")
            print(f"{ANSI_YELLOW}  Ensure calflora_db.py and plant_identify.py are in tools/{ANSI_RESET}")


if __name__ == "__main__":
    main()
