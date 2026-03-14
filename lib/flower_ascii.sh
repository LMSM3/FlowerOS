#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS ASCII Character Library  —  lib/flower_ascii.sh
#  Source this file to get flower_guy() and helpers in any shell/MOTD script.
#
#  Drop-in path:  source ~/.config/floweros/flower_ascii.sh
#              or source "${FLOWEROS_LIB}/flower_ascii.sh"
#
# ───────────────────────────────────────────────────────────────────────────
#  Shell ↔ C contract
#  Every function here has a 1:1 twin in src/utils/flower_guy.c
#  The C binary (flower-guy) is the production backend; this shell version
#  is the portable bootstrap that runs before anything is compiled.
#
#  C backend build:
#    gcc -O2 -std=c11 -I src/ -o flower-guy src/utils/flower_guy.c
#  After that, flower_guy() will delegate to it automatically.
#
# ───────────────────────────────────────────────────────────────────────────
#  Architecture note (one line):
#    goal → compile this entire file to C automatically: sh2c lib/flower_ascii.sh
# ═══════════════════════════════════════════════════════════════════════════

# ── Guard: only load once ────────────────────────────────────────────────
[[ -n "${_FLOWER_ASCII_LOADED:-}" ]] && return 0
_FLOWER_ASCII_LOADED=1

# ── Resolve library root ──────────────────────────────────────────────────
_FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════════════════
#  flower_c  —  theme-aware 256-color lookup
#  Roles: primary | secondary | accent | muted | reset
#
#  Resolution order:
#    1. Active THEME_* associative array  (theme_self_init.sh loaded)
#    2. ~/.floweros/theme.conf            (sourced directly)
#    3. Hardcoded pastel 256-color values (always works, no deps)
#
#  C twin: fp_role_color() in src/utils/flower_guy.c
# ═══════════════════════════════════════════════════════════════════════════

flower_c() {
    local role="${1:-reset}"

    # ── Path 1: live theme associative array ─────────────────────────────
    local theme_name="${FLOWEROS_THEME_ACTIVE:-${FLOWEROS_THEME:-garden}}"
    local arr_name="THEME_${theme_name^^}"   # e.g. THEME_GARDEN

    # declare -n requires bash 4.3+; guard gracefully
    if (( BASH_VERSINFO[0] >= 4 && BASH_VERSINFO[1] >= 3 )); then
        if declare -p "$arr_name" >/dev/null 2>&1; then
            declare -n _fa_theme="$arr_name"
            [[ -n "${_fa_theme[$role]+x}" ]] && { printf '%s' "${_fa_theme[$role]}"; return; }
        fi
    fi

    # ── Path 2: theme.conf keys  (THEME_PRIMARY="\033[…]") ───────────────
    local conf="${HOME}/.floweros/theme.conf"
    if [[ -f "$conf" ]]; then
        local key="THEME_${role^^}"
        local val
        val="$(grep -m1 "^${key}=" "$conf" 2>/dev/null | cut -d= -f2- | tr -d '"')"
        [[ -n "$val" ]] && { printf '%b' "$val"; return; }
    fi

    # ── Path 3: hardcoded pastel 256-color fallback ───────────────────────
    # These match the FOS_* constants in src/floweros.h exactly.
    case "$role" in
        primary)   printf '\033[38;5;117m' ;;  # mint-cyan
        secondary) printf '\033[38;5;183m' ;;  # soft magenta
        accent)    printf '\033[38;5;159m' ;;  # light cyan
        muted)     printf '\033[38;5;245m' ;;  # grey
        reset|*)   printf '\033[0m'        ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  flower_guy  —  pastel ASCII character with 6 body variants × 4 moods
#
#  Usage:
#    flower_guy [variant]          variant default: classic
#    MOOD=<mood> flower_guy [variant]
#
#  Variants:  classic | chonk | pot | ghost | orb | tiny
#  Moods:     happy | neutral | angry | sleepy
#
#  C twin: flower_guy_print() in src/utils/flower_guy.c
#          Identical output — verified by diff in CI.
# ═══════════════════════════════════════════════════════════════════════════

flower_guy() {
    # ── If compiled C backend exists, delegate to it immediately ─────────
    # The C binary is faster, handles wide chars correctly, and is the
    # canonical reference implementation.
    local _c_bin
    _c_bin="${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-guy}"
    if [[ -x "${_c_bin:-}" ]]; then
        MOOD="${MOOD:-neutral}" "${_c_bin}" "${1:-classic}"
        return $?
    fi

    local variant="${1:-classic}"
    local mood="${MOOD:-neutral}"

    local A B C M R
    A="$(flower_c primary)"
    B="$(flower_c secondary)"
    C="$(flower_c accent)"
    M="$(flower_c muted)"
    R="$(flower_c reset)"

    # ── Mood faces ────────────────────────────────────────────────────────
    # Each mood produces a distinct eye/mouth pair.
    # ASCII-only: no Unicode so the art renders on any locale.
    local EYES MOUTH
    EYES="( ) ( )"
    MOUTH="^"
    case "$mood" in
        happy)   EYES="(o) (o)"; MOUTH="u" ;;
        neutral) EYES="( ) ( )"; MOUTH="^" ;;
        angry)   EYES="(>)(<)";  MOUTH="-" ;;
        sleepy)  EYES="(-) (-)"; MOUTH="~" ;;
    esac

    # ── Variants ──────────────────────────────────────────────────────────
    # Flower petals use A/B alternating colors for a "layered" feel.
    # Body uses M (muted) so it reads as a soft silhouette under the bloom.
    case "$variant" in

        classic)
            cat <<EOF
${B}                   .-.
${A}                .-(   )-.
${B}              (   .-.     )
${A}                \`-(   )-,
${B}                   \`-'
${R}${M}                  __|__
${M}               _/       \\_
${M}             _/  _   _    \\_
${M}            /   ${EYES}     \\
${M}           \\      ${MOUTH}         /
${M}            \\_   ___      _/
${M}              \\_/   \\____/
${R}
EOF
            ;;

        chonk)
            # Wider body — same petal structure, roomier silhouette
            cat <<EOF
${A}                .-.
${B}             .-(   )-.
${A}            (   .-.   )
${B}             \`-(   )-'
${R}${M}               ___|___
${M}            __/       \\__
${M}          _/   __ __     \\_
${M}         /    ${EYES}        \\
${M}         \\      ${MOUTH}        /
${M}          \\_    ___     _/
${M}            \\__/   \\___/
${R}
EOF
            ;;

        pot)
            # Shorter, rounder — sits in a pot base
            cat <<EOF
${B}               .-.
${A}            .-(   )-.
${B}          (   .-.     )
${A}            \`-(   )-,
${B}               \`-'
${R}${M}              __|__
${M}           _/       \\_
${M}         _/  ${EYES}    \\_
${M}        /       ${MOUTH}      \\
${M}        \\_    _____    _/
${M}          \\__/     \\__/
${M}             \\_____/
${R}
EOF
            ;;

        ghost)
            # Floaty — accent/primary petals, ghost skirt body
            cat <<EOF
${C}              .-.
${A}           .-(   )-.
${C}          (   .-.   )
${A}           \`-(   )-'
${R}${M}            .-""""-.
${M}           /  ${EYES}  \\
${M}          |     ${MOUTH}     |
${M}          |  ._____.  |
${M}          \\_/     \\_/
${R}
EOF
            ;;

        orb)
            # Smooth orb — rounder body, no sharp shoulders
            cat <<EOF
${C}             .-.
${B}          .-(   )-.
${C}         (   .-.   )
${B}          \`-(   )-'
${R}${M}           .--------.
${M}         .'  ${EYES}   '.
${M}        /      ${MOUTH}      \\
${M}        \\   ._____.   /
${M}         '._       _.'
${M}            \`-----'
${R}
EOF
            ;;

        tiny)
            # One-line-ish, for narrow MOTD columns or inline use
            cat <<EOF
${A}   .-.
${A}  ${EYES}
${A}   |=|
${R}${M}  __|__
${M} /  ${MOUTH}  \\
${M} \`-----'
${R}
EOF
            ;;

        *)
            printf '%s\n' \
                "usage: flower_guy {classic|chonk|pot|ghost|orb|tiny}  (MOOD=happy|neutral|angry|sleepy)"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  flower_guy_random  —  random variant + mood, used by MOTD rotation
#
#  MOTD usage:  flower_guy_random         (source this file first)
#  C twin: main() in flower_guy.c when called as: flower-guy --random
# ═══════════════════════════════════════════════════════════════════════════

flower_guy_random() {
    local variants=(classic chonk pot ghost orb tiny)
    local moods=(happy neutral angry sleepy)
    local v="${variants[$((RANDOM % ${#variants[@]}))]}"
    export MOOD="${moods[$((RANDOM % ${#moods[@]}))]}"
    flower_guy "$v"
    unset MOOD
}

# ═══════════════════════════════════════════════════════════════════════════
#  flower_guy_plain  —  plain (no color) version for piping / logging
#
#  Temporarily replaces flower_c with a no-op, renders, then restores.
#  Safe to call inside CI, log files, or anywhere color would be noise.
# ═══════════════════════════════════════════════════════════════════════════

flower_guy_plain() {
    # Save whatever flower_c currently is (may or may not exist)
    local _saved_flower_c
    _saved_flower_c="$(declare -f flower_c 2>/dev/null || true)"

    # Override with a no-op for the duration of this call
    flower_c() { :; }

    flower_guy "${1:-classic}"
    local _rc=$?

    # Restore original definition (or unset if it didn't exist before)
    if [[ -n "$_saved_flower_c" ]]; then
        eval "$_saved_flower_c" 2>/dev/null || true
    else
        unset -f flower_c
    fi

    return $_rc
}

# ═══════════════════════════════════════════════════════════════════════════
#  MOTD integration helper
#  Called automatically when sourced into motd-integration.sh
#  Runs flower_guy_random if interactive shell and not suppressed.
# ═══════════════════════════════════════════════════════════════════════════

flower_guy_motd() {
    # Respect FLOWEROS_QUIET and non-interactive shells
    [[ "${FLOWEROS_QUIET:-0}" == "1" ]] && return 0
    [[ $- != *i* ]] && return 0
    flower_guy_random
}
