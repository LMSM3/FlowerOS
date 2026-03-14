#!/usr/bin/env python3
"""
floweros.motd.provider_weather
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prints one 🌦 weather line via wttr.in.
Silently exits 0 if requests is absent or network is down.

Env vars:
    FLOWER_WEATHER_LOC   city name or blank for IP-geolocation
"""

import os, sys


def main() -> int:
    try:
        import requests
    except ImportError:
        return 0

    loc = os.environ.get("FLOWER_WEATHER_LOC", "")
    url = f"https://wttr.in/{loc}?format=3" if loc else "https://wttr.in?format=3"

    try:
        r = requests.get(url, timeout=1.0, headers={"User-Agent": "FlowerOS-MOTD/1.0"})
        if r.status_code == 200:
            text = r.text.strip()
            if text:
                icon = "🌦" if os.environ.get("FLOWER_MOTD_EMOJI", "0") == "1" else "~"
                print(f"{icon} {text}")
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
