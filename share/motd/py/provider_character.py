#!/usr/bin/env python3
"""
floweros.motd.provider_character
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Python port of src/utils/flower_guy.c — all 6 variants, 4 moods.

Outputs multi-line ANSI art to stdout so flower-motd.sh can capture it
with mapfile and render it side-by-side with system info.

Used when the compiled flower-guy binary is not on PATH.
Output is byte-for-byte equivalent to flower_guy.c (same color codes,
same whitespace, same variant/mood API).

Env vars:
    FLOWER_CHAR_VARIANT   hex|classic|chonk|pot|ghost|orb|tiny  (default: hex)
    FLOWER_CHAR_MOOD      happy|neutral|angry|sleepy             (default: neutral)
"""

import os, random, sys

# ── Palette (mirrors role_color() in flower_guy.c) ───────────────────────
_CA = "\033[38;5;117m"   # primary   — cyan
_CB = "\033[38;5;183m"   # secondary — lavender
_CC = "\033[38;5;159m"   # accent    — light cyan
_CM = "\033[38;5;245m"   # muted     — gray
_CY = "\033[38;5;229m"   # gold      — yellow
_CR = "\033[0m"           # reset

# ── Moods (mirrors get_face() in flower_guy.c) ───────────────────────────
_MOODS = {
    "happy":   ("(o) (o)", "u"),
    "neutral": ("( ) ( )", "^"),
    "angry":   ("(>)(<)",  "-"),
    "sleepy":  ("(-) (-)", "~"),
}

# ── Width constants — encode the expected ASCII width of each slot ────────
# angry eyes "(>)(<)" are 6 chars; all others are 7.  Padding to _EYE_W
# keeps every right-wall character in its correct column.
_EYE_W   = max(len(eyes)  for eyes, _  in _MOODS.values())  # 7
_MOUTH_W = max(len(mouth) for _,   mouth in _MOODS.values())  # 1

# ── Variants — 1:1 port of C variant_* functions ────────────────────────
# Each function takes (eyes, mouth) strings and returns a list of lines.
# Backslash chars are literal backslashes, same as in the C printf output.

def _classic(e, m):
    e = e.ljust(_EYE_W)
    return [
        f"{_CB}                   .-.",
        f"{_CA}                .-(   )-.",
        f"{_CB}              (   .-.     )",
        f"{_CA}                `-(   )-,",
        f"{_CB}                   `-'",
        f"{_CR}{_CM}                  __|__",
        f"{_CM}               _/       \\_",
        f"{_CM}             _/  _   _    \\_",
        f"{_CM}            /   {e}     \\",
        f"{_CM}           \\      {m}         /",
        f"{_CM}            \\_   ___      _/",
        f"{_CM}              \\_/   \\____/",
        _CR,
    ]


def _chonk(e, m):
    e = e.ljust(_EYE_W)
    return [
        f"{_CA}                .-.",
        f"{_CB}             .-(   )-.",
        f"{_CA}            (   .-.   )",
        f"{_CB}             `-(   )-'",
        f"{_CR}{_CM}               ___|___",
        f"{_CM}            __/       \\__",
        f"{_CM}          _/   __ __     \\_",
        f"{_CM}         /    {e}        \\",
        f"{_CM}         \\      {m}        /",
        f"{_CM}          \\_    ___     _/",
        f"{_CM}            \\__/   \\___/",
        _CR,
    ]


def _pot(e, m):
    e = e.ljust(_EYE_W)
    return [
        f"{_CB}               .-.",
        f"{_CA}            .-(   )-.",
        f"{_CB}          (   .-.     )",
        f"{_CA}            `-(   )-,",
        f"{_CB}               `-'",
        f"{_CR}{_CM}              __|__",
        f"{_CM}           _/       \\_",
        f"{_CM}         _/  {e}    \\_",
        f"{_CM}        /       {m}      \\",
        f"{_CM}        \\_    _____    _/",
        f"{_CM}          \\__/     \\__/",
        f"{_CM}             \\_____/",
        _CR,
    ]


def _ghost(e, m):
    e = e.ljust(_EYE_W)
    return [
        f"{_CC}              .-.",
        f"{_CA}           .-(   )-.",
        f"{_CC}          (   .-.   )",
        f"{_CA}           `-(   )-'",
        f'{_CR}{_CM}            .-"""".-',
        f"{_CM}           /  {e}  \\",
        f"{_CM}          |     {m}     |",
        f"{_CM}          |  ._____.  |",
        f"{_CM}          \\_/     \\_/",
        _CR,
    ]


def _orb(e, m):
    e = e.ljust(_EYE_W)
    return [
        f"{_CC}             .-.",
        f"{_CB}          .-(   )-.",
        f"{_CC}         (   .-.   )",
        f"{_CB}          `-(   )-'",
        f"{_CR}{_CM}           .--------.",
        f"{_CM}         .'  {e}   '.",
        f"{_CM}        /      {m}      \\",
        f"{_CM}        \\   ._____.   /",
        f"{_CM}         '._       _.'",
        f"{_CM}            `-----'",
        _CR,
    ]


def _tiny(e, m):
    return [
        f"{_CA}   .-.",
        f"{_CA}  {e}",
        f"{_CA}   |=|",
        f"{_CR}{_CM}  __|__",
        f"{_CM} /  {m}  \\",
        f"{_CM} `-----'",
        _CR,
    ]


def _hex(e, m):
    e = e.ljust(_EYE_W)
    return [
        f"{_CB}          .-.",
        f"{_CA}       .-(   )-.",
        f"{_CB}      (   .-.   )",
        f"{_CA}       `-(   )-'",
        f"{_CB}          `-'",
        f"{_CR}{_CM}           __|__",
        f"{_CM}         _/       \\_",
        f"{_CM}        /  {e}  \\",
        f"{_CM}        |     {m}     |",
        f"{_CM}        \\  _______  /",
        f"{_CM}         \\_________/",
        f"{_CY}         /         \\",
        f"{_CY}       ####   #####",
        _CR,
    ]


_VARIANTS = {
    "hex":     _hex,
    "classic": _classic,
    "chonk":   _chonk,
    "pot":     _pot,
    "ghost":   _ghost,
    "orb":     _orb,
    "tiny":    _tiny,
}


def main() -> int:
    variant = os.environ.get("FLOWER_CHAR_VARIANT", "hex").lower()
    mood    = os.environ.get("FLOWER_CHAR_MOOD",    "neutral").lower()

    if variant not in _VARIANTS:
        variant = random.choice(list(_VARIANTS))
    if mood not in _MOODS:
        mood = random.choice(list(_MOODS))

    eyes, mouth = _MOODS[mood]
    lines = _VARIANTS[variant](eyes, mouth)
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
