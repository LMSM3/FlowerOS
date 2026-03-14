#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  inject.d/50-td-reminder.sh — FlowerOS Tower Defense login reminder
#
#  Fires when EITHER condition is true:
#    · uptime < 10 minutes  (reboot / fresh login)
#    · last shown > 24 hours ago  (daily nudge)
#    · FLOWER_TD_FORCE=1  (manual override — bypasses all timing)
#
#  Stamp file: ~/.cache/floweros/motd/td_last
#  Disable:    export FLOWER_MOTD_NO_TD=1
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail
[[ -n "${FLOWER_MOTD_NO_TD:-}" ]] && exit 0

_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/floweros/motd"
_STAMP="$_CACHE_DIR/td_last"
mkdir -p "$_CACHE_DIR"

# ── Trigger check ──────────────────────────────────────────────────────────
_fire=0

if [[ -n "${FLOWER_TD_FORCE:-}" ]]; then
    # Manual force — skip timing gates entirely
    _fire=1
else
    # Uptime in whole seconds (default high so it only triggers on real fresh boot)
    _up=99999
    if [[ -r /proc/uptime ]]; then
        _up="$(awk '{printf "%d",$1}' /proc/uptime 2>/dev/null || echo 99999)"
    fi

    if (( _up < 600 )); then
        _fire=1
    elif [[ ! -f "$_STAMP" ]]; then
        _fire=1
    else
        _now="$(date +%s)"
        _mt="$(stat -c %Y "$_STAMP" 2>/dev/null || echo 0)"
        if (( _now - _mt >= 86400 )); then
            _fire=1
        fi
    fi
fi

if (( _fire == 0 )); then exit 0; fi

# ── Colors (match td_engine.c palette) ────────────────────────────────────
_CM=$'\033[38;5;183m'   # lavender
_CC=$'\033[38;5;117m'   # cyan
_CD=$'\033[38;5;245m'   # gray
_CG=$'\033[38;5;120m'   # green
_CB=$'\033[1m'
_CR=$'\033[0m'

# ── Output ─────────────────────────────────────────────────────────────────
_td_bin=""
if command -v flower-td >/dev/null 2>&1; then _td_bin="flower-td"; fi

printf "\n"
printf "  %s%s✿ FlowerOS Tower Defense%s  %s·  v2 · PvZ-style lane combat%s\n" \
    "$_CB" "$_CM" "$_CR" "$_CD" "$_CR"

if [[ -n "$_td_bin" ]]; then
    printf "  %sflower-td%s  %s[D]aisy [R]ose [S]unflower [C]actus [T]horn%s\n" \
        "$_CG" "$_CR" "$_CD" "$_CR"
    printf "  %s7 lanes · 20 stages · 30 petals · 10 lives   %sflower-td --help%s\n" \
        "$_CD" "$_CC" "$_CR"
else
    printf "  %sgcc -O2 -std=c11 -o flower-td src/games/td_engine.c%s\n" "$_CD" "$_CR"
    printf "  %s7 lanes · 20 stages · flowers vs creeps  (not yet built)%s\n" "$_CD" "$_CR"
fi

touch "$_STAMP"
