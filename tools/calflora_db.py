#!/usr/bin/env python3
"""
FlowerOS Calflora Database Integration  (tools/calflora_db.py)

Local SQLite cache of California flora taxonomy retrieved from
Calflora (calflora.org).  Provides offline search by common name,
scientific name, family, and bloom color.

The module attempts to fetch from Calflora's public API on first run,
then falls back to a built-in seed dataset of common California
wildflowers so the tool is always usable even when the upstream
endpoint is unreachable (their /entry/REST.html returned 404 as of
2024-06).

Part of FlowerOS v1.3.0 — Botanical Image Identification Subsystem.
"""

import json
import os
import sqlite3
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ═══════════════════════════════════════════════════════════════════════════
#  Configuration
# ═══════════════════════════════════════════════════════════════════════════

_FLOWEROS_ROOT = Path(__file__).resolve().parent.parent
_DB_DIR = _FLOWEROS_ROOT / "data" / "calflora"
DB_PATH = _DB_DIR / "calflora.db"

# Calflora API endpoints (ordered by likelihood of being alive)
_API_ENDPOINTS = [
    "https://www.calflora.org/app/api/search",
    "https://www.calflora.org/entry/observ.cgi",
]
_API_TIMEOUT = 8  # seconds

# ═══════════════════════════════════════════════════════════════════════════
#  Seed Dataset — common California wildflowers
#
#  Guarantees the DB is always populated even without network access.
#  Each entry: (scientific_name, common_name, family, bloom_colors,
#               native, bloom_months, habitat)
# ═══════════════════════════════════════════════════════════════════════════

_SEED_TAXA: List[Tuple[str, str, str, str, int, str, str]] = [
    ("Eschscholzia californica",   "California Poppy",          "Papaveraceae",    "orange,yellow",          1, "Feb-Sep",  "grassland,coastal"),
    ("Iris douglasiana",           "Douglas Iris",              "Iridaceae",       "purple,blue,cream",      1, "Mar-May",  "coastal,woodland"),
    ("Iris macrosiphon",           "Bowl-tubed Iris",           "Iridaceae",       "purple,cream,yellow",    1, "Apr-Jun",  "woodland,grassland"),
    ("Iris fernaldii",             "Fernald's Iris",            "Iridaceae",       "cream,yellow",           1, "May-Jun",  "woodland"),
    ("Iris missouriensis",         "Western Blue Flag",         "Iridaceae",       "blue,purple",            1, "May-Jul",  "meadow,wetland"),
    ("Lupinus nanus",              "Sky Lupine",                "Fabaceae",        "blue,purple",            1, "Mar-May",  "grassland"),
    ("Lupinus arboreus",           "Yellow Bush Lupine",        "Fabaceae",        "yellow",                 1, "Apr-Jul",  "coastal"),
    ("Lupinus albifrons",          "Silver Lupine",             "Fabaceae",        "purple,blue",            1, "Mar-Jun",  "chaparral"),
    ("Clarkia amoena",             "Farewell to Spring",        "Onagraceae",      "pink,lavender",          1, "May-Jul",  "grassland,coastal"),
    ("Mimulus guttatus",           "Seep Monkeyflower",         "Phrymaceae",      "yellow",                 1, "Mar-Aug",  "wetland,stream"),
    ("Mimulus aurantiacus",        "Sticky Monkeyflower",       "Phrymaceae",      "orange,salmon",          1, "Mar-Jul",  "chaparral,coastal"),
    ("Castilleja affinis",         "Indian Paintbrush",         "Orobanchaceae",   "red,orange",             1, "Mar-Jun",  "grassland,chaparral"),
    ("Aquilegia formosa",          "Western Columbine",         "Ranunculaceae",   "red,yellow",             1, "Apr-Aug",  "woodland,stream"),
    ("Sisyrinchium bellum",        "Blue-eyed Grass",           "Iridaceae",       "blue,purple",            1, "Mar-May",  "grassland"),
    ("Trillium ovatum",            "Western Wake-robin",        "Melanthiaceae",   "white,pink",             1, "Feb-Jun",  "forest"),
    ("Erythronium californicum",   "California Fawn Lily",      "Liliaceae",       "white,cream",            1, "Mar-May",  "forest,woodland"),
    ("Calochortus luteus",         "Yellow Mariposa Lily",      "Liliaceae",       "yellow",                 1, "Apr-Jun",  "grassland"),
    ("Calochortus venustus",       "Butterfly Mariposa Lily",   "Liliaceae",       "white,pink,purple",      1, "May-Jul",  "grassland"),
    ("Dodecatheon hendersonii",    "Henderson's Shooting Star", "Primulaceae",     "pink,magenta",           1, "Feb-May",  "grassland,woodland"),
    ("Brodiaea elegans",           "Harvest Brodiaea",          "Asparagaceae",    "purple,blue",            1, "May-Jul",  "grassland"),
    ("Dichelostemma capitatum",    "Blue Dicks",                "Asparagaceae",    "purple,blue",            1, "Mar-May",  "grassland,chaparral"),
    ("Claytonia perfoliata",       "Miner's Lettuce",           "Montiaceae",      "white,pink",             1, "Feb-May",  "woodland,forest"),
    ("Delphinium nudicaule",       "Red Larkspur",              "Ranunculaceae",   "red,orange",             1, "Mar-Jun",  "woodland"),
    ("Delphinium cardinale",       "Scarlet Larkspur",          "Ranunculaceae",   "red",                    1, "May-Jul",  "chaparral"),
    ("Erysimum capitatum",         "Western Wallflower",        "Brassicaceae",    "orange,yellow",          1, "Mar-Jul",  "chaparral,grassland"),
    ("Eriophyllum confertiflorum", "Golden Yarrow",             "Asteraceae",      "yellow",                 1, "Apr-Aug",  "chaparral"),
    ("Encelia californica",        "California Bush Sunflower",  "Asteraceae",      "yellow",                 1, "Feb-Nov",  "coastal,chaparral"),
    ("Layia platyglossa",          "Tidy Tips",                 "Asteraceae",      "yellow,white",           1, "Mar-Jun",  "grassland"),
    ("Nemophila menziesii",        "Baby Blue Eyes",            "Boraginaceae",    "blue",                   1, "Feb-Jun",  "grassland,woodland"),
    ("Platystemon californicus",   "Cream Cups",                "Papaveraceae",    "cream,yellow",           1, "Mar-May",  "grassland"),
    ("Amsinckia menziesii",        "Fiddleneck",                "Boraginaceae",    "orange,yellow",          1, "Mar-Jun",  "grassland"),
    ("Argemone munita",            "Prickly Poppy",             "Papaveraceae",    "white",                  1, "Apr-Sep",  "desert,chaparral"),
    ("Romneya coulteri",           "Matilija Poppy",            "Papaveraceae",    "white",                  1, "May-Jul",  "chaparral"),
    ("Ceanothus thyrsiflorus",     "Blue Blossom",              "Rhamnaceae",      "blue",                   1, "Mar-Jun",  "coastal,woodland"),
    ("Rosa californica",           "California Wild Rose",       "Rosaceae",        "pink",                   1, "Apr-Sep",  "stream,woodland"),
    ("Lilium pardalinum",          "Leopard Lily",              "Liliaceae",       "orange,red",             1, "May-Jul",  "stream,woodland"),
    ("Lilium humboldtii",          "Humboldt Lily",             "Liliaceae",       "orange,yellow",          1, "May-Jul",  "woodland,chaparral"),
    ("Sidalcea malviflora",        "Checkerbloom",              "Malvaceae",       "pink,magenta",           1, "Mar-Jun",  "grassland"),
    ("Dicentra formosa",           "Pacific Bleeding Heart",    "Papaveraceae",    "pink",                   1, "Mar-Jul",  "forest"),
    ("Zauschneria californica",    "California Fuchsia",        "Onagraceae",      "red,orange",             1, "Aug-Nov",  "chaparral"),
    ("Helianthus annuus",          "Common Sunflower",          "Asteraceae",      "yellow",                 1, "Jun-Oct",  "grassland"),
    ("Achillea millefolium",       "Yarrow",                    "Asteraceae",      "white",                  1, "Apr-Sep",  "grassland,meadow"),
    ("Penstemon heterophyllus",    "Foothill Penstemon",        "Plantaginaceae",  "blue,purple",            1, "Apr-Jul",  "chaparral,woodland"),
    ("Salvia spathacea",           "Hummingbird Sage",          "Lamiaceae",       "magenta,red",            1, "Mar-May",  "woodland,chaparral"),
    ("Trichostema lanatum",        "Woolly Blue Curls",         "Lamiaceae",       "blue,purple",            1, "Apr-Aug",  "chaparral"),
    ("Arctostaphylos manzanita",   "Common Manzanita",         "Ericaceae",       "pink,white",             1, "Dec-Mar",  "chaparral,woodland"),
    ("Cercis occidentalis",        "Western Redbud",            "Fabaceae",        "magenta,pink",           1, "Feb-Apr",  "woodland,chaparral"),
    ("Styrax redivivus",           "Snowdrop Bush",             "Styracaceae",     "white",                  1, "Apr-Jun",  "chaparral,woodland"),
]

# ═══════════════════════════════════════════════════════════════════════════
#  Database Management
# ═══════════════════════════════════════════════════════════════════════════

def _ensure_db() -> sqlite3.Connection:
    """Open (and create if needed) the local calflora SQLite database."""
    _DB_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS taxa (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            scientific_name TEXT NOT NULL UNIQUE,
            common_name     TEXT,
            family          TEXT,
            bloom_colors    TEXT,
            native          INTEGER DEFAULT 1,
            bloom_months    TEXT,
            habitat         TEXT,
            image_url       TEXT,
            source          TEXT DEFAULT 'seed',
            fetched_at      TEXT
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS sync_log (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp  TEXT NOT NULL,
            endpoint   TEXT,
            status     TEXT,
            count      INTEGER DEFAULT 0
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_taxa_common
        ON taxa (common_name COLLATE NOCASE)
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_taxa_family
        ON taxa (family COLLATE NOCASE)
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_taxa_colors
        ON taxa (bloom_colors)
    """)
    conn.commit()
    return conn


def seed_database(conn: Optional[sqlite3.Connection] = None) -> int:
    """Insert the built-in seed taxa (skip duplicates). Returns count inserted."""
    own = conn is None
    if own:
        conn = _ensure_db()
    inserted = 0
    for row in _SEED_TAXA:
        try:
            conn.execute(
                """INSERT OR IGNORE INTO taxa
                   (scientific_name, common_name, family, bloom_colors,
                    native, bloom_months, habitat, source, fetched_at)
                   VALUES (?,?,?,?,?,?,?,'seed',datetime('now'))""",
                row,
            )
            inserted += conn.total_changes  # rough
        except sqlite3.IntegrityError:
            pass
    conn.commit()
    if own:
        conn.close()
    return inserted


def fetch_from_calflora(query: str = "", limit: int = 100) -> List[Dict]:
    """
    Attempt to fetch taxa from Calflora's public API.
    Returns a list of dicts on success, empty list on failure.
    """
    try:
        import requests
    except ImportError:
        return []

    for endpoint in _API_ENDPOINTS:
        try:
            params = {"format": "json", "limit": str(limit)}
            if query:
                params["taxon"] = query
            resp = requests.get(endpoint, params=params, timeout=_API_TIMEOUT)
            if resp.status_code == 200:
                data = resp.json()
                if isinstance(data, list):
                    return data
                if isinstance(data, dict) and "results" in data:
                    return data["results"]
        except Exception:
            continue
    return []


def sync(query: str = "", verbose: bool = False) -> int:
    """
    Sync local DB with Calflora API.  Falls back to seed data if the
    API is unreachable.  Returns total taxa count in the local DB.
    """
    conn = _ensure_db()

    # Always ensure seed data is present
    seed_database(conn)

    # Try live API
    records = fetch_from_calflora(query)
    api_status = "ok" if records else "unreachable"
    inserted = 0

    for rec in records:
        sci = rec.get("taxon") or rec.get("scientific_name") or rec.get("name", "")
        if not sci:
            continue
        common = rec.get("common_name", "") or rec.get("commonName", "")
        family = rec.get("family", "")
        colors = rec.get("bloom_colors", "") or rec.get("flowerColor", "")
        native = 1 if rec.get("native", True) else 0
        img = rec.get("imageUrl", "") or rec.get("image_url", "")
        try:
            conn.execute(
                """INSERT OR REPLACE INTO taxa
                   (scientific_name, common_name, family, bloom_colors,
                    native, image_url, source, fetched_at)
                   VALUES (?,?,?,?,?,?,'calflora',datetime('now'))""",
                (sci, common, family, colors, native, img),
            )
            inserted += 1
        except sqlite3.IntegrityError:
            pass

    conn.execute(
        "INSERT INTO sync_log (timestamp, endpoint, status, count) VALUES (datetime('now'),?,?,?)",
        (_API_ENDPOINTS[0], api_status, inserted),
    )
    conn.commit()

    total = conn.execute("SELECT COUNT(*) FROM taxa").fetchone()[0]
    if verbose:
        print(f"[calflora_db] sync complete — api={api_status}, "
              f"fetched={inserted}, total_taxa={total}")
    conn.close()
    return total


# ═══════════════════════════════════════════════════════════════════════════
#  Query Functions
# ═══════════════════════════════════════════════════════════════════════════

def search_by_name(term: str, limit: int = 10) -> List[Dict]:
    """Search taxa by common or scientific name (case-insensitive substring)."""
    conn = _ensure_db()
    seed_database(conn)
    rows = conn.execute(
        """SELECT * FROM taxa
           WHERE common_name    LIKE ? COLLATE NOCASE
              OR scientific_name LIKE ? COLLATE NOCASE
           LIMIT ?""",
        (f"%{term}%", f"%{term}%", limit),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def search_by_color(color: str, limit: int = 20) -> List[Dict]:
    """Search taxa whose bloom_colors contain the given color."""
    conn = _ensure_db()
    seed_database(conn)
    rows = conn.execute(
        "SELECT * FROM taxa WHERE bloom_colors LIKE ? COLLATE NOCASE LIMIT ?",
        (f"%{color}%", limit),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def search_by_family(family: str, limit: int = 20) -> List[Dict]:
    """Search taxa by botanical family."""
    conn = _ensure_db()
    seed_database(conn)
    rows = conn.execute(
        "SELECT * FROM taxa WHERE family LIKE ? COLLATE NOCASE LIMIT ?",
        (f"%{family}%", limit),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_all_taxa() -> List[Dict]:
    """Return every taxon in the local DB."""
    conn = _ensure_db()
    seed_database(conn)
    rows = conn.execute("SELECT * FROM taxa ORDER BY common_name").fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_taxon(scientific_name: str) -> Optional[Dict]:
    """Exact lookup by scientific name."""
    conn = _ensure_db()
    seed_database(conn)
    row = conn.execute(
        "SELECT * FROM taxa WHERE scientific_name = ? COLLATE NOCASE",
        (scientific_name,),
    ).fetchone()
    conn.close()
    return dict(row) if row else None


# ═══════════════════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════════════════

def _cli():
    """Minimal CLI for testing / manual queries."""
    if len(sys.argv) < 2:
        print("FlowerOS Calflora DB — local California flora database")
        print()
        print("Usage:")
        print("  calflora_db.py sync              Sync from API + seed")
        print("  calflora_db.py search <term>     Search by name")
        print("  calflora_db.py color  <color>    Search by bloom color")
        print("  calflora_db.py family <family>   Search by family")
        print("  calflora_db.py list              List all taxa")
        print()
        print(f"Database: {DB_PATH}")
        return

    cmd = sys.argv[1].lower()

    if cmd == "sync":
        total = sync(verbose=True)
        print(f"Database now has {total} taxa.")

    elif cmd == "search" and len(sys.argv) > 2:
        term = " ".join(sys.argv[2:])
        results = search_by_name(term)
        if not results:
            print(f"No results for '{term}'")
        for r in results:
            print(f"  {r['common_name']:30s}  {r['scientific_name']:35s}  [{r['bloom_colors']}]")

    elif cmd == "color" and len(sys.argv) > 2:
        color = sys.argv[2]
        results = search_by_color(color)
        if not results:
            print(f"No results for color '{color}'")
        for r in results:
            print(f"  {r['common_name']:30s}  {r['scientific_name']:35s}  [{r['bloom_colors']}]")

    elif cmd == "family" and len(sys.argv) > 2:
        family = sys.argv[2]
        results = search_by_family(family)
        if not results:
            print(f"No results for family '{family}'")
        for r in results:
            print(f"  {r['common_name']:30s}  {r['scientific_name']:35s}  [{r['bloom_colors']}]")

    elif cmd == "list":
        for r in get_all_taxa():
            print(f"  {r['common_name']:30s}  {r['scientific_name']:35s}  [{r['bloom_colors']}]")

    else:
        print(f"Unknown command: {cmd}")


if __name__ == "__main__":
    _cli()
