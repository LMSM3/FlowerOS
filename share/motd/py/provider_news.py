#!/usr/bin/env python3
"""
floweros.motd.provider_news
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prints one 🗞 RSS headline line.
Tries each feed in order; stops at first success.
Silently exits 0 on any failure.

Env vars:
    FLOWER_NEWS_N     number of headlines to show (default 2)
    FLOWER_NEWS_FEED  override URL for a custom RSS feed
"""

import os, sys, xml.etree.ElementTree as ET

_DEFAULT_FEEDS = [
    "https://feeds.bbci.co.uk/news/world/rss.xml",
    "https://rss.nytimes.com/services/xml/rss/nyt/World.xml",
    "https://www.reutersagency.com/feed/?best-topics=top-news&post_type=best",
]


def _parse_rss(text: str) -> "list[str]":
    try:
        root = ET.fromstring(text)
        return [
            item.text.strip()
            for item in root.findall(".//channel/item/title")
            if item.text
        ]
    except Exception:
        return []


def main() -> int:
    try:
        import requests
    except ImportError:
        return 0

    n = max(1, int(os.environ.get("FLOWER_NEWS_N", "2")))
    custom = os.environ.get("FLOWER_NEWS_FEED", "")
    feeds = ([custom] + _DEFAULT_FEEDS) if custom else _DEFAULT_FEEDS

    for url in feeds:
        try:
            r = requests.get(url, timeout=1.3, headers={"User-Agent": "FlowerOS-MOTD/1.0"})
            if r.status_code != 200:
                continue
            titles = _parse_rss(r.text)
            if not titles:
                continue
            joined = " · ".join(titles[:n])
            capped = joined[:140] + ("…" if len(joined) > 140 else "")
            icon = "🗞" if os.environ.get("FLOWER_MOTD_EMOJI", "0") == "1" else "!"
            print(f"{icon} " + capped)
            break
        except Exception:
            continue

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
