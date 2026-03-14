#!/usr/bin/env python3
"""
FlowerOS Banner Library (Python)
Consistent box-drawing templates for all Python tools.

Import: from lib.banners import *
"""

import os
import sys
import re

# ═══════════════════════════════════════════════════════════════════════════
#  Color Palette (matches lib/banners.sh)
# ═══════════════════════════════════════════════════════════════════════════

_FOS_RED = os.getenv("FLOWEROS_CLR_RED", "\x1b[31m")
_FOS_GREEN = os.getenv("FLOWEROS_CLR_GREEN", "\x1b[32m")
_FOS_YELLOW = os.getenv("FLOWEROS_CLR_YELLOW", "\x1b[33m")
_FOS_BLUE = os.getenv("FLOWEROS_CLR_BLUE", "\x1b[34m")
_FOS_MAGENTA = os.getenv("FLOWEROS_CLR_MAGENTA", "\x1b[35m")
_FOS_CYAN = os.getenv("FLOWEROS_CLR_CYAN", "\x1b[36m")
_FOS_WHITE = os.getenv("FLOWEROS_CLR_WHITE", "\x1b[37m")
_FOS_DIM = os.getenv("FLOWEROS_CLR_DIM", "\x1b[90m")
_FOS_BOLD = os.getenv("FLOWEROS_CLR_BOLD", "\x1b[1m")
_FOS_RESET = os.getenv("FLOWEROS_CLR_RESET", "\x1b[0m")

# Box-drawing characters (single source of truth)
_FOS_TL = "╔"  # top-left
_FOS_TR = "╗"  # top-right
_FOS_BL = "╚"  # bottom-left
_FOS_BR = "╝"  # bottom-right
_FOS_H = "═"   # horizontal
_FOS_V = "║"   # vertical

# Fixed banner width (inner content area)
_FOS_WIDTH = 75

# Quiet mode
_FOS_QUIET = os.getenv("FLOWEROS_QUIET", "0") == "1"

# ═══════════════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════════════

def _strip_ansi(text: str) -> str:
    """Strip ANSI codes for length calculation."""
    return re.sub(r'\x1b\[[0-9;]*m', '', text)

def _pad(text: str, width: int = _FOS_WIDTH) -> str:
    """Pad string to fixed width (visual padding, ignoring ANSI)."""
    stripped = _strip_ansi(text)
    visible_len = len(stripped)
    pad_len = max(0, width - visible_len)
    return text + (' ' * pad_len)

def _hrule(width: int = _FOS_WIDTH) -> str:
    """Horizontal rule: ═══...═══"""
    return _FOS_H * (width + 2)

# ═══════════════════════════════════════════════════════════════════════════
#  Template Functions
# ═══════════════════════════════════════════════════════════════════════════

def fos_banner_box(*lines: str, color: str = "") -> None:
    """
    Full box banner with any number of lines.
    
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║                        MESSAGE LINE 1                                     ║
    ║                        MESSAGE LINE 2                                     ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    
    Usage: fos_banner_box("Line 1", "Line 2", color=_FOS_CYAN)
    """
    if _FOS_QUIET:
        return
    
    c = color or os.getenv("FOS_BANNER_COLOR", "")
    
    print()
    print(f"{c}{_FOS_TL}{_hrule()}{_FOS_TR}{_FOS_RESET}")
    print(f"{c}{_FOS_V}{_pad('')}{_FOS_V}{_FOS_RESET}")
    
    for line in lines:
        padded = _pad(f"  {line}  ")
        print(f"{c}{_FOS_V}{padded}{_FOS_V}{_FOS_RESET}")
    
    print(f"{c}{_FOS_V}{_pad('')}{_FOS_V}{_FOS_RESET}")
    print(f"{c}{_FOS_BL}{_hrule()}{_FOS_BR}{_FOS_RESET}")
    print()

def fos_banner_title(title: str, subtitle: str = "", icon_left: str = "🌸", icon_right: str = "") -> None:
    """
    FlowerOS signature title box.
    
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║           🌸 FlowerOS v1.3.0 - TITLE HERE ⚡                            ║
    ║                                                                           ║
    ║                     ⚠️  SUBTITLE HERE ⚠️                                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    
    Usage: fos_banner_title("Title", "Subtitle", "🌸", "⚡")
    """
    if _FOS_QUIET:
        return
    
    if not icon_right:
        icon_right = icon_left
    
    c = os.getenv("FOS_BANNER_COLOR", _FOS_CYAN)
    
    decorated = f"{icon_left} {title} {icon_right}"
    
    print()
    print(f"{c}{_FOS_TL}{_hrule()}{_FOS_TR}{_FOS_RESET}")
    print(f"{c}{_FOS_V}{_pad('')}{_FOS_V}{_FOS_RESET}")
    print(f"{c}{_FOS_V}{_pad(f'           {decorated}')}{_FOS_V}{_FOS_RESET}")
    
    if subtitle:
        print(f"{c}{_FOS_V}{_pad('')}{_FOS_V}{_FOS_RESET}")
        print(f"{c}{_FOS_V}{_pad(f'                     {subtitle}')}{_FOS_V}{_FOS_RESET}")
    
    print(f"{c}{_FOS_V}{_pad('')}{_FOS_V}{_FOS_RESET}")
    print(f"{c}{_FOS_BL}{_hrule()}{_FOS_BR}{_FOS_RESET}")
    print()

def fos_banner_section(text: str, color: str = _FOS_YELLOW) -> None:
    """
    Section divider.
    
    ════════════════════════════════════════════════════════════════════════════
      MESSAGE TEXT
    ════════════════════════════════════════════════════════════════════════════
    
    Usage: fos_banner_section("Section Title", _FOS_YELLOW)
    """
    if _FOS_QUIET:
        return
    
    print()
    print(f"{color}{_hrule()}{_FOS_RESET}")
    if text:
        print(f"{color}  {text}{_FOS_RESET}")
    print(f"{color}{_hrule()}{_FOS_RESET}")
    print()

def fos_banner_header(text: str, color: str = _FOS_CYAN) -> None:
    """
    Inline header.
    
    ═══ MESSAGE TEXT ═══
    
    Usage: fos_banner_header("Header Text", _FOS_CYAN)
    """
    if _FOS_QUIET:
        return
    
    print()
    print(f"{color}═══ {text} ═══{_FOS_RESET}")
    print()

def fos_banner_error(msg: str) -> None:
    """
    Error box (red, writes to stderr).
    
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║  ✗ ERROR: Message here                                                    ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    
    Usage: fos_banner_error("Something failed")
    """
    print(file=sys.stderr)
    print(f"{_FOS_RED}{_FOS_TL}{_hrule()}{_FOS_TR}{_FOS_RESET}", file=sys.stderr)
    print(f"{_FOS_RED}{_FOS_V}{_pad(f'  ✗ ERROR: {msg}')}{_FOS_V}{_FOS_RESET}", file=sys.stderr)
    print(f"{_FOS_RED}{_FOS_BL}{_hrule()}{_FOS_BR}{_FOS_RESET}", file=sys.stderr)
    print(file=sys.stderr)

def fos_banner_warn(msg: str) -> None:
    """
    Warning box (yellow).
    
    Usage: fos_banner_warn("Watch out!")
    """
    print()
    print(f"{_FOS_YELLOW}{_FOS_TL}{_hrule()}{_FOS_TR}{_FOS_RESET}")
    print(f"{_FOS_YELLOW}{_FOS_V}{_pad(f'  ⚠️  WARNING: {msg}')}{_FOS_V}{_FOS_RESET}")
    print(f"{_FOS_YELLOW}{_FOS_BL}{_hrule()}{_FOS_BR}{_FOS_RESET}")
    print()

def fos_banner_ok(msg: str) -> None:
    """
    Success box (green).
    
    Usage: fos_banner_ok("Done!")
    """
    print()
    print(f"{_FOS_GREEN}{_FOS_TL}{_hrule()}{_FOS_TR}{_FOS_RESET}")
    print(f"{_FOS_GREEN}{_FOS_V}{_pad(f'  ✓ {msg}')}{_FOS_V}{_FOS_RESET}")
    print(f"{_FOS_GREEN}{_FOS_BL}{_hrule()}{_FOS_BR}{_FOS_RESET}")
    print()

def fos_banner_experimental() -> None:
    """Red experimental warning one-liner."""
    print(f"{_FOS_RED}⚠️  RED WARNING: EXPERIMENTAL FEATURE - NOT PRODUCTION READY{_FOS_RESET}")

def fos_status(msg: str, icon: str = "→") -> None:
    """Status line (dim, for progress/info)."""
    print(f"  {_FOS_DIM}{icon}{_FOS_RESET} {msg}")

def fos_status_ok(msg: str) -> None:
    """Status line with green checkmark."""
    print(f"  {_FOS_GREEN}✓{_FOS_RESET} {msg}")

def fos_status_fail(msg: str) -> None:
    """Status line with red X."""
    print(f"  {_FOS_RED}✗{_FOS_RESET} {msg}")

def fos_status_warn(msg: str) -> None:
    """Status line with yellow warning."""
    print(f"  {_FOS_YELLOW}⚠{_FOS_RESET} {msg}")

def fos_tagline() -> None:
    """FlowerOS philosophy footer."""
    if _FOS_QUIET:
        return
    print()
    print(f"{_FOS_DIM}  🌺 FlowerOS — The Universal Operating System{_FOS_RESET}")
    print(f"{_FOS_DIM}  Every terminal session is a garden. 🌸{_FOS_RESET}")
    print()
