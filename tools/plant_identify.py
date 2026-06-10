#!/usr/bin/env python3
"""
FlowerOS Plant Image Identifier  (tools/plant_identify.py)

Identifies plant images by cross-referencing filename keywords,
EXIF metadata, and dominant color palette against the local
Calflora database (tools/calflora_db.py).

Scans images the user provides on the command line *and* any
previously converted files sitting in ascii_out/.

Part of FlowerOS v1.3.0 — Botanical Image Identification Subsystem.

Usage:
    python3 plant_identify.py <img_or_dir> [more...]
    python3 plant_identify.py --scan          # scan ascii_out/ originals
    python3 plant_identify.py --sync          # sync Calflora DB first
"""

import os
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Add lib/ for banners
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "lib"))

try:
    from banners import *
except ImportError:
    pass

# Color constants (banners.py prefixes them with _ so they aren't
# exported by `from banners import *`; define them unconditionally)
_FOS_RED = "\x1b[31m"
_FOS_GREEN = "\x1b[32m"
_FOS_YELLOW = "\x1b[33m"
_FOS_CYAN = "\x1b[36m"
_FOS_MAGENTA = "\x1b[35m"
_FOS_DIM = "\x1b[90m"
_FOS_BOLD = "\x1b[1m"
_FOS_RESET = "\x1b[0m"

# Banner helpers (may already exist from banners import; safe to overwrite)
if "fos_status_ok" not in dir():
    def fos_status_ok(msg): print(f"{_FOS_GREEN}✓ {msg}{_FOS_RESET}")
if "fos_status_fail" not in dir():
    def fos_status_fail(msg): print(f"{_FOS_RED}✗ {msg}{_FOS_RESET}")
if "fos_status_warn" not in dir():
    def fos_status_warn(msg): print(f"{_FOS_YELLOW}⚠ {msg}{_FOS_RESET}")
if "fos_banner_title" not in dir():
    def fos_banner_title(t, s="", il="", ir=""): print(f"\n{'═'*75}\n  {il} {t}\n  {s}\n{'═'*75}\n")
if "fos_banner_header" not in dir():
    def fos_banner_header(h, c=""): print(f"\n{c}── {h} ──{_FOS_RESET}")

# Calflora DB (sibling module)
sys.path.insert(0, str(Path(__file__).resolve().parent))
import calflora_db

# ═══════════════════════════════════════════════════════════════════════════
#  Configuration
# ═══════════════════════════════════════════════════════════════════════════

FLOWEROS_VERSION = "1.3.0"
TOOL_NAME = "plant_identify"

_IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp", ".tiff"}
_FLOWEROS_ROOT = Path(__file__).resolve().parent.parent
_ASCII_OUT = _FLOWEROS_ROOT / "ascii_out"

# Color name → approximate RGB centroid (for dominant-color matching)
_COLOR_CENTROIDS: Dict[str, Tuple[int, int, int]] = {
    "red":      (200, 50, 50),
    "orange":   (230, 140, 40),
    "yellow":   (230, 220, 50),
    "cream":    (245, 235, 200),
    "white":    (240, 240, 240),
    "pink":     (230, 130, 160),
    "magenta":  (200, 60, 140),
    "lavender": (180, 150, 210),
    "purple":   (130, 70, 170),
    "blue":     (70, 100, 200),
    "green":    (60, 160, 60),
    "salmon":   (230, 150, 120),
}

# ═══════════════════════════════════════════════════════════════════════════
#  Image Collection
# ═══════════════════════════════════════════════════════════════════════════

def collect_images(args: List[str]) -> List[Path]:
    """Gather image files from CLI args (files and directories)."""
    paths: List[Path] = []
    for a in args:
        p = Path(a).expanduser()
        if p.is_dir():
            paths += sorted(
                f for f in p.rglob("*")
                if f.suffix.lower() in _IMAGE_EXTS and f.is_file()
            )
        elif p.is_file() and p.suffix.lower() in _IMAGE_EXTS:
            paths.append(p)
    # de-dup
    seen = set()
    out = []
    for p in paths:
        rp = str(p.resolve())
        if rp not in seen:
            seen.add(rp)
            out.append(p)
    return out


def discover_originals_from_ascii_out() -> List[Path]:
    """
    Look at ascii_out/*.ansi.txt filenames and try to locate the
    original images that were converted.  This lets us identify
    images the user has *already* downloaded and processed.
    """
    if not _ASCII_OUT.is_dir():
        return []
    originals: List[Path] = []
    for ansi_file in sorted(_ASCII_OUT.glob("*.ansi.txt")):
        stem = ansi_file.stem  # e.g. "beautiful-flowers-iris.ansi" → need .stem again
        stem = stem.replace(".ansi", "")
        # Search common locations for the original
        for ext in _IMAGE_EXTS:
            for search_dir in [_FLOWEROS_ROOT, Path.home() / "Downloads",
                               Path.home() / "Pictures", Path.cwd()]:
                candidate = search_dir / f"{stem}{ext}"
                if candidate.is_file():
                    originals.append(candidate)
                    break
            else:
                continue
            break
    return originals


# ═══════════════════════════════════════════════════════════════════════════
#  Feature Extraction
# ═══════════════════════════════════════════════════════════════════════════

def _tokenize_filename(path: Path) -> List[str]:
    """
    Break a filename into lowercase keyword tokens.
    'beautiful-flowers-iris_photo(2).jpg' → ['beautiful','flowers','iris','photo']
    """
    stem = path.stem.lower()
    tokens = re.split(r'[\s_\-\.,()\[\]{}]+', stem)
    return [t for t in tokens if len(t) >= 3 and not t.isdigit()]


def extract_exif_keywords(path: Path) -> List[str]:
    """Extract useful keywords from EXIF/IPTC if Pillow is available."""
    try:
        from PIL import Image
        from PIL.ExifTags import TAGS
    except ImportError:
        return []
    keywords: List[str] = []
    try:
        with Image.open(path) as im:
            exif = im.getexif()
            if exif:
                for tag_id, value in exif.items():
                    tag_name = TAGS.get(tag_id, "")
                    if tag_name in ("ImageDescription", "XPSubject",
                                    "XPTitle", "XPKeywords", "XPComment"):
                        if isinstance(value, bytes):
                            value = value.decode("utf-16-le", errors="ignore").rstrip("\x00")
                        if isinstance(value, str) and value.strip():
                            keywords.extend(re.split(r'[;,\s]+', value.lower()))
    except Exception:
        pass
    return [k for k in keywords if len(k) >= 3]


def extract_dominant_colors(path: Path, sample_size: int = 2000) -> List[str]:
    """
    Extract the top dominant color names from an image by sampling pixels
    and matching against _COLOR_CENTROIDS.
    """
    try:
        from PIL import Image
    except ImportError:
        return []
    try:
        with Image.open(path) as im:
            im = im.convert("RGB")
            # Downsample for speed
            im.thumbnail((150, 150))
            pixels = list(im.getdata())
    except Exception:
        return []

    # Count nearest named color for each pixel
    counts: Counter = Counter()
    for r, g, b in pixels:
        best_name = ""
        best_dist = float("inf")
        for name, (cr, cg, cb) in _COLOR_CENTROIDS.items():
            d = (r - cr) ** 2 + (g - cg) ** 2 + (b - cb) ** 2
            if d < best_dist:
                best_dist = d
                best_name = name
        counts[best_name] += 1

    total = sum(counts.values()) or 1
    # Return colors that account for ≥10% of pixels
    dominant = [name for name, cnt in counts.most_common()
                if cnt / total >= 0.10]
    return dominant[:5]


# ═══════════════════════════════════════════════════════════════════════════
#  Identification Engine
# ═══════════════════════════════════════════════════════════════════════════

def identify_image(path: Path) -> List[Dict]:
    """
    Attempt to identify the plant in an image by combining:
      1. Filename keyword matching against calflora DB
      2. EXIF metadata keyword matching
      3. Dominant color cross-reference

    Returns a scored list of candidate taxa (best first).
    """
    # Gather features
    filename_tokens = _tokenize_filename(path)
    exif_tokens = extract_exif_keywords(path)
    dominant_colors = extract_dominant_colors(path)

    all_tokens = filename_tokens + exif_tokens
    candidates: Dict[str, float] = {}  # scientific_name → score

    # --- Pass 1: keyword matching (high weight) ---
    for token in all_tokens:
        matches = calflora_db.search_by_name(token, limit=20)
        for m in matches:
            sci = m["scientific_name"]
            # Exact common-name word match scores higher
            common_words = set(m.get("common_name", "").lower().split())
            if token in common_words:
                candidates[sci] = candidates.get(sci, 0) + 3.0
            else:
                candidates[sci] = candidates.get(sci, 0) + 1.0

    # --- Pass 2: color matching (medium weight) ---
    if dominant_colors:
        for color in dominant_colors:
            color_matches = calflora_db.search_by_color(color, limit=30)
            for m in color_matches:
                sci = m["scientific_name"]
                # Small boost for color agreement
                candidates[sci] = candidates.get(sci, 0) + 0.5

    # Sort by score descending
    ranked = sorted(candidates.items(), key=lambda x: x[1], reverse=True)

    results: List[Dict] = []
    for sci, score in ranked[:8]:
        info = calflora_db.get_taxon(sci)
        if info:
            info["_score"] = score
            results.append(info)

    return results


# ═══════════════════════════════════════════════════════════════════════════
#  Display
# ═══════════════════════════════════════════════════════════════════════════

def print_identification(path: Path, results: List[Dict]) -> None:
    """Pretty-print identification results for one image."""
    print(f"\n{_FOS_CYAN}📷 {path.name}{_FOS_RESET}")
    print(f"   {_FOS_DIM}{path}{_FOS_RESET}")

    if not results:
        print(f"   {_FOS_YELLOW}⚠ No matches found in Calflora database{_FOS_RESET}")
        tokens = _tokenize_filename(path)
        colors = extract_dominant_colors(path)
        print(f"   {_FOS_DIM}  filename tokens: {tokens}{_FOS_RESET}")
        print(f"   {_FOS_DIM}  dominant colors:  {colors}{_FOS_RESET}")
        return

    best = results[0]
    score = best.get("_score", 0)
    confidence = "HIGH" if score >= 4.0 else "MEDIUM" if score >= 2.0 else "LOW"
    conf_color = _FOS_GREEN if confidence == "HIGH" else _FOS_YELLOW if confidence == "MEDIUM" else _FOS_RED

    print(f"   {_FOS_GREEN}🌿 Best match:{_FOS_RESET} {_FOS_BOLD}{best['common_name']}{_FOS_RESET}")
    print(f"   {_FOS_DIM}   Scientific: {best['scientific_name']}{_FOS_RESET}")
    print(f"   {_FOS_DIM}   Family:     {best.get('family', 'N/A')}{_FOS_RESET}")
    print(f"   {_FOS_DIM}   Colors:     {best.get('bloom_colors', 'N/A')}{_FOS_RESET}")
    print(f"   {_FOS_DIM}   Habitat:    {best.get('habitat', 'N/A')}{_FOS_RESET}")
    print(f"   {_FOS_DIM}   Native:     {'Yes' if best.get('native') else 'No'}{_FOS_RESET}")
    print(f"   {conf_color}   Confidence: {confidence} (score={score:.1f}){_FOS_RESET}")

    if len(results) > 1:
        print(f"   {_FOS_DIM}   Other candidates:{_FOS_RESET}")
        for alt in results[1:5]:
            alt_score = alt.get("_score", 0)
            print(f"   {_FOS_DIM}     • {alt['common_name']} "
                  f"({alt['scientific_name']}) score={alt_score:.1f}{_FOS_RESET}")


# ═══════════════════════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) < 2 or sys.argv[1] in {"-h", "--help", "help"}:
        fos_banner_title(
            f"FlowerOS v{FLOWEROS_VERSION} — Plant Identifier",
            "Calflora-backed image identification",
            "🌿", "🔍",
        )
        print(f"{_FOS_GREEN}Tool:{_FOS_RESET} {TOOL_NAME}")
        print()
        print(f"{_FOS_YELLOW}── USAGE ──{_FOS_RESET}")
        print(f"  {_FOS_CYAN}python3 {TOOL_NAME}.py <img_or_dir> [more...]{_FOS_RESET}")
        print(f"  {_FOS_CYAN}python3 {TOOL_NAME}.py --scan{_FOS_RESET}   "
              f"Identify from ascii_out/ history")
        print(f"  {_FOS_CYAN}python3 {TOOL_NAME}.py --sync{_FOS_RESET}   "
              f"Sync Calflora DB before identifying")
        print()
        print(f"{_FOS_YELLOW}── EXAMPLES ──{_FOS_RESET}")
        print(f"  python3 {TOOL_NAME}.py ~/Downloads/flower.jpg")
        print(f"  python3 {TOOL_NAME}.py ~/Pictures/garden/ --sync")
        print()
        print(f"{_FOS_DIM}Database: {calflora_db.DB_PATH}{_FOS_RESET}")
        return

    fos_banner_title(
        f"FlowerOS v{FLOWEROS_VERSION} — Plant Identifier",
        "Calflora-backed image identification",
        "🌿", "🔍",
    )

    # Handle flags
    args = list(sys.argv[1:])
    do_sync = "--sync" in args
    do_scan = "--scan" in args
    args = [a for a in args if not a.startswith("--")]

    # Sync DB if requested or on first run
    if do_sync or not calflora_db.DB_PATH.exists():
        print(f"{_FOS_YELLOW}🌱 Syncing Calflora database...{_FOS_RESET}")
        total = calflora_db.sync(verbose=True)
        fos_status_ok(f"Database ready — {total} taxa")
        print()
    else:
        # Ensure seed data
        conn = calflora_db._ensure_db()
        calflora_db.seed_database(conn)
        total = conn.execute("SELECT COUNT(*) FROM taxa").fetchone()[0]
        conn.close()
        fos_status_ok(f"Database loaded — {total} taxa")

    # Collect images
    images: List[Path] = []
    if args:
        images = collect_images(args)
    if do_scan:
        print(f"{_FOS_CYAN}🔍 Scanning ascii_out/ for previously converted originals...{_FOS_RESET}")
        originals = discover_originals_from_ascii_out()
        images.extend(originals)
        if originals:
            fos_status_ok(f"Found {len(originals)} original(s) from ascii_out/")
        # Also identify from ascii_out filenames directly (even without original images)
        if _ASCII_OUT.is_dir():
            for ansi_file in sorted(_ASCII_OUT.glob("*.ansi.txt")):
                # Use the ansi filename as a "virtual" image for keyword matching
                images.append(ansi_file)

    if not images:
        fos_status_fail("No images found to identify")
        print(f"{_FOS_DIM}Provide image paths or use --scan to check ascii_out/{_FOS_RESET}")
        sys.exit(2)

    fos_status_ok(f"Scanning {len(images)} image(s)")

    # Identify each
    print()
    print(f"{_FOS_MAGENTA}{'═' * 75}{_FOS_RESET}")

    identified = 0
    for img_path in images:
        results = identify_image(img_path)
        print_identification(img_path, results)
        if results:
            identified += 1

    # Summary
    print()
    print(f"{_FOS_MAGENTA}{'═' * 75}{_FOS_RESET}")
    print()
    print(f"{_FOS_CYAN}🌸 Identification Complete{_FOS_RESET}")
    print(f"  {_FOS_GREEN}✓ Identified:{_FOS_RESET} {identified}/{len(images)} image(s)")
    print(f"  {_FOS_DIM}Database:    {calflora_db.DB_PATH}{_FOS_RESET}")
    print()


if __name__ == "__main__":
    main()
