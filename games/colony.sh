#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Colony  —  shell launcher  (games/colony.sh)
#
#  Delegates to the compiled C binary (flower-colony).
#  Resolution: Tier 5 install → user build → dev build
#
#  Usage:  bash games/colony.sh [--mode num|sym] [--seed N]
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_C_CANDIDATES=(
    "/opt/floweros/bin/flower-colony"
    "${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-colony}"
    "${_ROOT}/src/flower-colony"
)
for _C in "${_C_CANDIDATES[@]}"; do
    [[ -x "${_C:-}" ]] && exec "${_C}" "$@"
done

echo "flower-colony not found.  Build it:"
echo "  cd ${_ROOT}/src && gcc -O2 -std=c11 -Wall -Wextra -o flower-colony games/colony_engine.c"
exit 1
