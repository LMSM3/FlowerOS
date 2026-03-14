#!/usr/bin/env bash
# inject.d/90-randomfacts.sh — Layer-1 injector: science/nature random fact
# Enable: export FLOWER_MOTD_RANDOM=1
# Tune:   export FLOWER_RANDOM_KIND=mix   (element|chemical|plant|mix)
#
# If python3 is absent the bash Layer-0 fact in flower-motd.sh already ran —
# this layer adds optional Wikipedia enrichment; never duplicates the line.
set -euo pipefail
[[ -n "${FLOWER_MOTD_RANDOM:-}" ]] || exit 0
PY="/usr/local/lib/floweros/motd/py/provider_random.py"
[[ -f "$PY" ]] || exit 0
python3 "$PY" || true
