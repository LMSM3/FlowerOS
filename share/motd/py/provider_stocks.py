#!/usr/bin/env python3
"""
floweros.motd.provider_stocks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prints one 💹 stock-ticker line via Stooq CSV (no API key needed).
Silently exits 0 on any failure.

Env vars:
    FLOWER_STOCKS   comma-separated tickers, e.g. "AAPL,MSFT,NVDA"
"""

import os, sys


def main() -> int:
    try:
        import requests
    except ImportError:
        return 0

    raw = os.environ.get("FLOWER_STOCKS", "AAPL,MSFT,TSLA")
    tickers = [t.strip().lower() for t in raw.split(",") if t.strip()][:5]
    if not tickers:
        return 0

    parts = []
    for t in tickers:
        # Stooq requires exchange suffix; append .us for bare US tickers
        stooq_sym = t if "." in t else f"{t}.us"
        url = f"https://stooq.com/q/l/?s={stooq_sym}&f=sd2t2ohlcv&h&e=csv"
        try:
            r = requests.get(url, timeout=1.2, headers={"User-Agent": "FlowerOS-MOTD/1.0"})
            if r.status_code != 200:
                continue
            lines = r.text.strip().splitlines()
            if len(lines) < 2:
                continue
            cols = lines[1].split(",")
            if len(cols) < 7:
                continue
            display = t.upper().split(".")[0]
            close = cols[6]
            if close and close != "N/D":
                parts.append(f"{display} {close}")
        except Exception:
            continue

    if parts:
        icon = "💹" if os.environ.get("FLOWER_MOTD_EMOJI", "0") == "1" else "$"
        print(f"{icon} Stocks: " + " · ".join(parts))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
