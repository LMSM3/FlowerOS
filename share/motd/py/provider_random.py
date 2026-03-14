#!/usr/bin/env python3
"""
floweros.motd.provider_random
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prints one 🌸 science/nature line.

Layer 0 (bash fallback): flower-motd.sh has its own inline array — this
provider upgrades that with Wikipedia enrichment when requests is present.

Usage (via inject.d/90-randomfacts.sh):
    python3 provider_random.py

Env vars:
    FLOWER_RANDOM_KIND   element | chemical | plant | mix  (default: mix)
"""

import os, random, sys

# Isolated — import siblings from same directory regardless of install path
sys.path.insert(0, os.path.dirname(__file__))
from _data import ELEMENTS, CHEMICALS, PLANTS
from _wiki import fetch

_EMOJI = os.environ.get("FLOWER_MOTD_EMOJI", "0") == "1"

_POOLS = {
    "element":  ELEMENTS,
    "chemical": CHEMICALS,
    "plant":    PLANTS,
}

_ICONS = {
    "element":  "⚗" if _EMOJI else "*",
    "chemical": "🧪" if _EMOJI else "~",
    "plant":    "🌱" if _EMOJI else "+",
}


def _pick(kind: str) -> str:
    pool = _POOLS[kind]
    name, tag, blurb = random.choice(pool)          # truly random
    icon = _ICONS[kind]
    wiki = fetch(name)                               # None if offline/missing
    detail = wiki if wiki else blurb
    return f"{icon} {kind.title()}: {name} ({tag}) — {detail}"


def main() -> int:
    kind = os.environ.get("FLOWER_RANDOM_KIND", "mix").lower()
    if kind not in _POOLS:
        kind = "mix"
    if kind == "mix":
        kind = random.choice(list(_POOLS))
    print(_pick(kind))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
