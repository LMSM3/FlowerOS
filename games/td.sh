#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Tower Defense  —  shell launcher  (games/td.sh)
#
#  Delegates to the compiled C binary (flower-td).
#
#  Usage:  bash games/td.sh
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_C_CANDIDATES=(
    "/opt/floweros/bin/flower-td"
    "${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-td}"
    "${_ROOT}/src/flower-td"
)
for _C in "${_C_CANDIDATES[@]}"; do
    [[ -x "${_C:-}" ]] && exec "${_C}" "$@"
done

echo "flower-td not found.  Build it:"
echo "  cd ${_ROOT}/src && gcc -O2 -std=c11 -Wall -Wextra -o flower-td games/td_engine.c"
exit 1
