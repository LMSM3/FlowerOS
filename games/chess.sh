#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Chess  —  shell launcher  (games/chess.sh)
#
#  Delegates to the compiled C binary (flower-chess).
#  Resolution: Tier 5 install → user build → dev build
#
#  Usage:  bash games/chess.sh [--mode num|sym|gui] [--depth N]
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_C_CANDIDATES=(
    "/opt/floweros/bin/flower-chess"
    "${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-chess}"
    "${_ROOT}/src/flower-chess"
)
for _C in "${_C_CANDIDATES[@]}"; do
    [[ -x "${_C:-}" ]] && exec "${_C}" "$@"
done

echo "flower-chess not found.  Build it:"
echo "  cd ${_ROOT}/src && gcc -O2 -std=c11 -Wall -Wextra -o flower-chess games/chess_engine.c"
exit 1
