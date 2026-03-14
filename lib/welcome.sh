#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  lib/welcome.sh  —  FlowerOS entry point
#
#  Sourced from ~/.bashrc (written by flower-install).
#  On first terminal open:   draws the welcome panel.
#  On subsequent opens:      silent.
#  Always:                   defines fhelp.
#
#  fhelp     — show the command reference panel any time
#  fhelp -l  — include the full frun language table
#
# ───────────────────────────────────────────────────────────────────────────
#  Shell ↔ C note
#  The C installer (flower-install) writes the source line for this file.
#  The first-run flag is ~/.floweros/welcomed  (touch to reset).
# ═══════════════════════════════════════════════════════════════════════════

[[ -n "${_FOS_WELCOME_LOADED:-}" ]] && return 0
_FOS_WELCOME_LOADED=1

# Only run in interactive shells
[[ $- == *i* ]] || return 0

# ── Colors (reuse flower_c if already loaded, else inline fallback) ───────
if ! declare -f flower_c >/dev/null 2>&1; then
    flower_c() {
        case "${1:-reset}" in
            primary)   printf '\033[38;5;117m' ;;
            secondary) printf '\033[38;5;183m' ;;
            muted)     printf '\033[38;5;245m' ;;
            green)     printf '\033[38;5;120m' ;;
            yellow)    printf '\033[38;5;229m' ;;
            reset|*)   printf '\033[0m' ;;
        esac
    }
fi

# Single-letter bindings used throughout this file
_WA="$(flower_c primary)"    # mint-cyan  — accent / flower center
_WB="$(flower_c secondary)"  # soft magenta — petals
_WM="$(flower_c muted)"      # grey — body / dims
_WG="$(flower_c green)"      # green — ok markers
_WY="$(flower_c yellow)"     # yellow — command names
_WR="$(flower_c reset)"

# ── Helpers ───────────────────────────────────────────────────────────────
_fw_hr() {
    # horizontal rule, adapts to terminal width (max 72)
    local w="${COLUMNS:-80}"; (( w > 72 )) && w=72
    printf "${_WM}"
    printf '═%.0s' $(seq 1 $w)
    printf "${_WR}\n"
}

# ═══════════════════════════════════════════════════════════════════════════
#  _fos_welcome_panel  —  the actual panel drawn on first open / fhelp
#
#  Layout: right-facing walk sprite (10 lines) beside command table.
#  Sprite is R1 frame (walking pose) from experimental/animations/flower_walk_demo.sh.
# ═══════════════════════════════════════════════════════════════════════════

_fos_welcome_panel() {
    local ver="${FLOWEROS_VERSION:-1.3.0}"
    local user="${USER:-$(whoami 2>/dev/null || echo user)}"

    printf '\n'
    _fw_hr

    printf "${_WB}  ✿  ${_WA}FlowerOS ${ver}${_WM}  ·  Linux power install  ·  Welcome, ${user}${_WR}\n"
    _fw_hr
    printf '\n'

    # ── Sprite (right-facing walk R1 frame, colours embedded) ────────────
    local -a sprite=(
        "${_WB}     .~.         ${_WR}"
        "${_WB}   .(   ).       ${_WR}"
        "${_WB}  (${_WA} .~. ${_WB})${_WB}>     ${_WR}"
        "${_WB}   \`-(   )-'    ${_WR}"
        "${_WB}     \`-'        ${_WR}"
        "${_WM}     _|_         ${_WR}"
        "${_WM}   .(${_WA}^${_WM}).${_WB}>      ${_WR}"
        "${_WM}    |=|          ${_WR}"
        "${_WM}   _/ \\         ${_WR}"
        "${_WM}  o   o          ${_WR}"
    )

    # ── Command table (right column, 10 rows) ────────────────────────────
    local -a cmds=(
        ""
        "${_WM}  Command                         What it does${_WR}"
        "${_WM}  ─────────────────────────────   ────────────────────────────${_WR}"
        "  ${_WY}frun${_WR} ${_WA}<file>${_WR}                      Run any of 17 languages"
        "  ${_WY}frun --hpc${_WR} ${_WA}<file>${_WR}               +OpenMP · -O3 -march=native"
        "  ${_WY}frun --gpu${_WR} ${_WA}<file.cu>${_WR}            +CUDA / OpenCL"
        "  ${_WY}flower-walk${_WR}                      Walking animation demo"
        "  ${_WY}fp new${_WR} ${_WA}<doc>${_WR}                     New LaTeX document"
        "  ${_WY}flower-motd${_WR}                      System info dashboard"
        "  ${_WY}fhelp${_WR} ${_WM}[-l]${_WR}                       This screen  ·  ${_WM}-l adds lang table${_WR}"
    )

    # ── Render side by side ───────────────────────────────────────────────
    local max_i=${#sprite[@]}
    (( ${#cmds[@]} > max_i )) && max_i=${#cmds[@]}

    for (( i=0; i<max_i; i++ )); do
        local s="${sprite[$i]:-}"
        local c="${cmds[$i]:-}"
        # Sprite column is fixed 22 visual chars wide; ANSI codes don't count
        # so we print sprite then pad with spaces to align command column.
        # Use cursor column 24 via \033[24G for reliable alignment.
        printf '  %s\033[24G%s\n' "$s" "$c"
    done

    printf '\n'
    _fw_hr
    printf "${_WM}  Docs: ~/FlowerOS/  ·  Prefs: ~/.floweros/preferences.conf  ·  fhelp -l${_WR}\n"
    _fw_hr
    printf '\n'
}

# ═══════════════════════════════════════════════════════════════════════════
#  fhelp  —  always available, shows the panel + optional language table
# ═══════════════════════════════════════════════════════════════════════════

fhelp() {
    _fos_welcome_panel
    if [[ "${1:-}" == "-l" ]]; then
        if declare -f frun_list >/dev/null 2>&1; then
            frun_list
        elif [[ -n "${_FOS_RUN_BIN:-}" ]]; then
            "${_FOS_RUN_BIN}" --list
        elif command -v flower-run >/dev/null 2>&1; then
            flower-run --list
        else
            printf "${_WM}  (source lib/run.sh or install flower-run to see the language table)${_WR}\n\n"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  First-run gate
#  Shows the panel once on the first interactive terminal after install.
#  Touch ~/.floweros/welcomed to reset (will show again on next open).
# ═══════════════════════════════════════════════════════════════════════════

_fos_flag="${HOME}/.floweros/welcomed"
if [[ ! -f "${_fos_flag}" ]]; then
    _fos_welcome_panel
    mkdir -p "$(dirname "${_fos_flag}")"
    touch "${_fos_flag}" 2>/dev/null || true
fi
unset _fos_flag
