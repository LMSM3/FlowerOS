#!/usr/bin/env bash
# inject.d/20-weather.sh — Layer-1 injector: weather
# Enable: export FLOWER_MOTD_WEATHER=1
# Tune:   export FLOWER_WEATHER_LOC="Chico"
set -euo pipefail
[[ -n "${FLOWER_MOTD_WEATHER:-}" ]] || exit 0
PY="/usr/local/lib/floweros/motd/py/provider_weather.py"
[[ -f "$PY" ]] || exit 0
python3 "$PY" || true
