#!/usr/bin/env python3
"""
FlowerOS Compact Encoding Kernel — lib/compact_encoding.py

Core colour and ASCII encoding kernel for photo-to-ASCII conversion.
Provides a compact encoding scheme that dramatically reduces output size
by eliminating redundant ANSI escape sequences.

Encoding strategies:
  1. Delta colour — only emit an ANSI code when the colour changes
  2. Run-length  — collapse N identical (char, colour) pairs into one token
  3. Compact binary (.fca) — FlowerOS Compact ASCII, a minimal binary format
     for storage/replay that decompresses to full ANSI on display

Import:
    from lib.compact_encoding import CompactEncoder, encode_ansi_compact

C twin:  (planned) src/kernel/compact_encode.c
"""

from typing import List, Tuple, Optional, BinaryIO, TextIO
import struct
import io

# ═══════════════════════════════════════════════════════════════════════════
#  Constants
# ═══════════════════════════════════════════════════════════════════════════

ANSI_FG_256 = "\x1b[38;5;{}m"      # 256-colour foreground template
ANSI_RESET  = "\x1b[0m"

# .fca binary header  (FlowerOS Compact ASCII)
FCA_MAGIC   = b"FCA\x01"           # 4 bytes: magic + version 1
FCA_VERSION = 1

# ═══════════════════════════════════════════════════════════════════════════
#  Core Compact Encoder
# ═══════════════════════════════════════════════════════════════════════════

class CompactEncoder:
    """
    Stateful encoder that converts a grid of (char, colour_code) pairs
    into the smallest ANSI output possible.

    Usage:
        enc = CompactEncoder()
        for row in grid:
            enc.begin_line()
            for ch, col in row:
                enc.put(ch, col)
            enc.end_line()
        result = enc.finish()
    """

    __slots__ = ("_parts", "_prev_col", "_run_ch", "_run_col",
                 "_run_len", "_rle")

    def __init__(self, *, rle: bool = True):
        """
        Args:
            rle: Enable run-length encoding (collapse identical consecutive
                 cells into a single span).  Disable for streaming output.
        """
        self._parts: List[str] = []
        self._prev_col: Optional[int] = None
        self._run_ch: str = ""
        self._run_col: int = -1
        self._run_len: int = 0
        self._rle = rle

    # ── internal ─────────────────────────────────────────────────────────

    def _flush_run(self) -> None:
        """Emit the current accumulated run to _parts."""
        if self._run_len == 0:
            return

        # Delta colour: only emit if colour changed since last flush
        if self._run_col != self._prev_col:
            self._parts.append(ANSI_FG_256.format(self._run_col))
            self._prev_col = self._run_col

        self._parts.append(self._run_ch * self._run_len)
        self._run_len = 0

    # ── public API ───────────────────────────────────────────────────────

    def begin_line(self) -> None:
        """Start a new row.  Resets run state (colour carries over)."""
        self._flush_run()

    def put(self, ch: str, colour: int) -> None:
        """Append one cell.  *ch* is a single display character."""
        if self._rle and colour == self._run_col and ch == self._run_ch:
            self._run_len += 1
        else:
            self._flush_run()
            self._run_ch = ch
            self._run_col = colour
            self._run_len = 1

    def end_line(self) -> None:
        """Finish the current row — flush pending run + reset + newline."""
        self._flush_run()
        self._parts.append(ANSI_RESET + "\n")
        self._prev_col = None          # force re-emit on next line

    def finish(self) -> str:
        """Return the complete compact ANSI string and reset the encoder."""
        self._flush_run()
        result = "".join(self._parts)
        self._parts.clear()
        self._prev_col = None
        self._run_len = 0
        return result


# ═══════════════════════════════════════════════════════════════════════════
#  Convenience wrapper (drop-in for existing blossom code)
# ═══════════════════════════════════════════════════════════════════════════

def encode_ansi_compact(
    pixels: List[int],
    colours: List[int],
    width: int,
    height: int,
    ramp: str,
    *,
    rle: bool = True,
) -> str:
    """
    One-shot compact encode.

    Args:
        pixels:  flat list of luma values (0-255), length = width * height
        colours: flat list of ANSI 256-colour codes, same length
        width:   columns per row
        height:  number of rows
        ramp:    luminance → character ramp string (dark → light)
        rle:     enable run-length compression

    Returns:
        Compact ANSI string ready for terminal display or file storage.
    """
    ramp_scale = (len(ramp) - 1) / 255.0
    enc = CompactEncoder(rle=rle)
    p = 0
    for _ in range(height):
        enc.begin_line()
        for _ in range(width):
            luma = pixels[p]
            col  = colours[p]
            ch   = ramp[int(luma * ramp_scale)]
            enc.put(ch, col)
            p += 1
        enc.end_line()
    return enc.finish()


# ═══════════════════════════════════════════════════════════════════════════
#  Compact Binary Format (.fca)  —  FlowerOS Compact ASCII v1
#
#  Layout:
#    Header  (12 bytes)
#      4B  magic       "FCA\x01"
#      2B  width       uint16  (columns)
#      2B  height      uint16  (rows)
#      2B  ramp_len    uint16  (length of ramp string)
#      2B  reserved    0x0000
#    Ramp   (ramp_len bytes)
#      The ASCII ramp string, UTF-8 encoded.
#    Data   (variable, row by row)
#      Each row is a sequence of *spans*:
#        1B  colour     ANSI 256-colour code (0-255)
#        1B  char_idx   index into the ramp table
#        2B  run_len    uint16  run length (1-65535)
#      Row terminator:
#        1B  0xFF       sentinel colour (impossible 256-code)
#
#  Decode to full ANSI with decode_fca().
# ═══════════════════════════════════════════════════════════════════════════

def encode_fca(
    pixels: List[int],
    colours: List[int],
    width: int,
    height: int,
    ramp: str,
) -> bytes:
    """Encode pixel + colour grid into .fca compact binary format."""
    ramp_bytes = ramp.encode("utf-8")
    ramp_scale = (len(ramp) - 1) / 255.0

    buf = io.BytesIO()
    # header
    buf.write(FCA_MAGIC)
    buf.write(struct.pack("<HHH2x", width, height, len(ramp_bytes)))
    buf.write(ramp_bytes)

    p = 0
    for _ in range(height):
        run_col = -1
        run_ci  = -1
        run_len = 0
        for _ in range(width):
            luma = pixels[p]
            col  = colours[p]
            ci   = int(luma * ramp_scale)
            p += 1

            if col == run_col and ci == run_ci and run_len < 65535:
                run_len += 1
            else:
                if run_len > 0:
                    buf.write(struct.pack("<BBH", run_col & 0xFF, run_ci & 0xFF, run_len))
                run_col = col
                run_ci  = ci
                run_len = 1
        # flush last run
        if run_len > 0:
            buf.write(struct.pack("<BBH", run_col & 0xFF, run_ci & 0xFF, run_len))
        # row sentinel
        buf.write(b"\xff")

    return buf.getvalue()


def decode_fca(data: bytes) -> str:
    """Decode .fca compact binary to full ANSI terminal string."""
    if data[:4] != FCA_MAGIC:
        raise ValueError("Not a valid .fca file (bad magic)")

    width, height, ramp_len = struct.unpack_from("<HHH", data, 4)
    # skip 2 reserved bytes at offset 10
    ramp = data[12 : 12 + ramp_len].decode("utf-8")

    pos = 12 + ramp_len
    lines: List[str] = []
    for _ in range(height):
        parts: List[str] = []
        prev_col: Optional[int] = None
        while pos < len(data):
            b = data[pos]
            if b == 0xFF:
                pos += 1
                break
            col, ci, run = struct.unpack_from("<BBH", data, pos)
            pos += 4
            if col != prev_col:
                parts.append(ANSI_FG_256.format(col))
                prev_col = col
            ch = ramp[ci] if ci < len(ramp) else " "
            parts.append(ch * run)
        parts.append(ANSI_RESET)
        lines.append("".join(parts))

    return "\n".join(lines) + ANSI_RESET + "\n"


# ═══════════════════════════════════════════════════════════════════════════
#  Metrics  —  report savings
# ═══════════════════════════════════════════════════════════════════════════

def encoding_stats(
    naive_len: int,
    compact_len: int,
) -> str:
    """Return a human-readable savings summary."""
    saved = naive_len - compact_len
    pct = (saved / naive_len * 100.0) if naive_len > 0 else 0.0
    return (
        f"Naive: {naive_len:,}B → Compact: {compact_len:,}B  "
        f"(saved {saved:,}B, {pct:.1f}%)"
    )
