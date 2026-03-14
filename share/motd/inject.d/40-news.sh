#!/usr/bin/env bash
# inject.d/40-news.sh — Layer-1 injector: RSS headlines
# Enable: export FLOWER_MOTD_NEWS=1
# Tune:   export FLOWER_NEWS_N=2
#         export FLOWER_NEWS_FEED="https://example.com/rss.xml"
set -euo pipefail
[[ -n "${FLOWER_MOTD_NEWS:-}" ]] || exit 0
PY="/usr/local/lib/floweros/motd/py/provider_news.py"
[[ -f "$PY" ]] || exit 0
python3 "$PY" || true
