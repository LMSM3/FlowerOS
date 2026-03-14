#!/usr/bin/env bash
# inject.d/30-stocks.sh — Layer-1 injector: stock tickers
# Enable: export FLOWER_MOTD_STOCKS=1
# Tune:   export FLOWER_STOCKS="AAPL,MSFT,NVDA"
set -euo pipefail
[[ -n "${FLOWER_MOTD_STOCKS:-}" ]] || exit 0
PY="/usr/local/lib/floweros/motd/py/provider_stocks.py"
[[ -f "$PY" ]] || exit 0
python3 "$PY" || true
