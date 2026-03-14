"""
floweros.motd._wiki
~~~~~~~~~~~~~~~~~~~
Thin Wikipedia REST summary fetcher.
Returns a single shortened sentence or None — never raises.
Caller decides what to do with None (use local blurb).

Requires: requests (optional — graceful degradation if absent)
Timeout:  1.2 s hard cap so login is never blocked.
"""

import textwrap

_UA = "FlowerOS-MOTD/1.0 (https://github.com/floweros)"
_API = "https://en.wikipedia.org/api/rest_v1/page/summary/{}"
_TIMEOUT = 1.2
_MAX_CHARS = 115


def fetch(title: str) -> "str | None":
    """Return a ≤115-char Wikipedia extract for *title*, or None."""
    try:
        import requests
    except ImportError:
        return None

    try:
        url = _API.format(title.replace(" ", "%20"))
        r = requests.get(url, timeout=_TIMEOUT, headers={"User-Agent": _UA})
        if r.status_code != 200:
            return None
        txt = (r.json().get("extract") or "").strip()
        if not txt:
            return None
        # Strip leading repeated title ("X is a ...") — keep it punchy
        return textwrap.shorten(txt, width=_MAX_CHARS, placeholder="…")
    except Exception:
        return None
