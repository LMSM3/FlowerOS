#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  flower_walk.sh  —  FlowerOS walking flower animation  [EXPERIMENTAL]
#
#  Usage:  bash flower_walk.sh
#          FPS=30 bash flower_walk.sh      (override frame rate)
#          LINES=20 COLUMNS=100 bash flower_walk.sh  (fixed canvas)
#
# ───────────────────────────────────────────────────────────────────────────
#  Status: EXPERIMENTAL
#  This is the shell bootstrap of the animation engine.
#  A real-time composited animation in pure bash has known limits:
#    • ASSOC array writes per frame are O(W×H) — slow on large terminals
#    • sleep precision is limited to ~6 decimal places via awk
#    • Bash string ops cannot hit 60fps on most hardware
#
#  C backend (canonical, production target):
#    src/utils/flower_walk.c  ←→  THIS FILE  (1:1 feature parity)
#    gcc -O2 -std=c11 -o flower-walk src/utils/flower_walk.c
#    The C version uses write() + nanosleep() and hits 60fps easily.
#
# ───────────────────────────────────────────────────────────────────────────
#  Frame system notes
#  Frames are encoded with single-letter color tokens (A B C M R) that map
#  to the FlowerOS role palette.  No ANSI codes are embedded in the art
#  strings — the renderer resolves them at draw time, so recoloring is free.
#
#  To add smoother animation (more frames):
#    1. Define FRAME2, FRAME3, … with the same token encoding
#    2. Raise FRAME_COUNT below
#    3. Reduce TICKS_PER_FRAME for faster cycling (4 is snappy, 8 is relaxed)
#
# ───────────────────────────────────────────────────────────────────────────
#  Architecture note (one line):
#    end-goal → gcc $(bash2c flower_walk.sh) -lm -o flower-walk  # sh→C in one shot
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Delegate to compiled C backend if available ───────────────────────────
# The C binary is drop-in compatible: same env vars, same behavior, way faster.
_C_WALK="${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-walk}"
if [[ -x "${_C_WALK:-}" ]]; then
    exec "${_C_WALK}" "$@"
fi

# ── Color backend ─────────────────────────────────────────────────────────
# Use theme system if loaded; else hardcoded pastel 256-color values.
# Mirrors the token_to_role() mapping in the C twin exactly.

_FA_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/flower_ascii.sh"
[[ -f "$_FA_LIB" ]] && source "$_FA_LIB"

if ! declare -f flower_c >/dev/null 2>&1; then
    flower_c() {
        case "${1:-reset}" in
            primary)   printf '\033[38;5;117m' ;;
            secondary) printf '\033[38;5;183m' ;;
            accent)    printf '\033[38;5;159m' ;;
            muted)     printf '\033[38;5;245m' ;;
            reset|*)   printf '\033[0m' ;;
        esac
    }
fi

# ── Timing ────────────────────────────────────────────────────────────────
FPS="${FPS:-25}"
# DT in nanoseconds — kept as integer to avoid float in bash arithmetic
DT_NS=$(( 1000000000 / FPS ))

# ── Canvas ────────────────────────────────────────────────────────────────
W="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
H="${LINES:-$(tput lines 2>/dev/null || echo 24)}"
(( H -= 1 ))
(( H < 10 )) && H=10

# ── Terminal control sequences ────────────────────────────────────────────
alt_on()  { printf '\033[?1049h'; }   # enter alternate screen buffer
alt_off() { printf '\033[?1049l'; }   # leave alternate screen buffer
hide()    { printf '\033[?25l'; }     # hide cursor
show()    { printf '\033[?25h'; }     # show cursor
cls()     { printf '\033[2J'; }       # clear screen
home()    { printf '\033[H'; }        # move cursor to top-left

cleanup() {
    show
    alt_off
    printf '%s' "$(flower_c reset)"
}
trap cleanup EXIT INT TERM

alt_on; hide; cls

# ── Background ────────────────────────────────────────────────────────────
# Sparse dot field — gives depth without visual noise.
# Same formula as C twin: bg_char_at(x,y) in flower_walk.c
bg_char_at() {
    local x="$1" y="$2"
    if   (( (x + 2*y) % 17 == 0 )); then printf '.'
    elif (( (x +   y) % 29 == 0 )); then printf ':'
    else printf ' '
    fi
}

# ── Frame definitions ─────────────────────────────────────────────────────
# Token encoding:
#   A = primary color    B = secondary    C = accent    M = muted    R = reset
# Tokens are single capital letters that switch the current color.
# They are NOT printed — only the non-token characters are rendered.
# This is identical to how the C twin stores its frame table.
#
# Walk cycle: 4 frames = one full step.  Frames 0+2 share foot position,
# 1+3 are the swing.  Add more frames here and raise FRAME_COUNT for smoother.
#
# TICKS_PER_FRAME: how many animation ticks each frame stays visible.
#   Lower  = faster leg movement (4 is punchy, 8 is leisurely).

FRAME_COUNT=4
TICKS_PER_FRAME=6

# Frame 0: neutral stance — feet even
FRAME0=$'   B.-.\nAB( Ao A)\n   B\`-\'\n    M__|__\n  M_/     \\_\n M/   A^    \\\n M\\_  ___  _/\n   M\\_/ \\_/'
# Frame 1: left step — left foot forward
FRAME1=$'   B.-.\nAB( Ao A)\n   B\`-\'\n    M__|__\n  M_/     \\_\n M/   A~    \\\n M \\_  ___  _/\n    M\\_/  \\_/'
# Frame 2: neutral — mirror of 0 (slight head tilt via mood cycle)
FRAME2=$'   B.-.\nAB( Ao A)\n   B\`-\'\n    M__|__\n  M_/     \\_\n M/   A^    \\\n M\\_  ___  _/\n  M\\_/ \\_/ '
# Frame 3: right step — right foot forward
FRAME3=$'   B.-.\nAB( Ao A)\n   B\`-\'\n    M__|__\n  M_/     \\_\n M/   A~    \\\n M\\_  ___ _/\n  M\\_/   \\_/'

FRAMES=("$FRAME0" "$FRAME1" "$FRAME2" "$FRAME3")

# ── Token → color resolver ─────────────────────────────────────────────────
_tok_to_role() {
    case "$1" in
        A) echo primary   ;;
        B) echo secondary ;;
        C) echo accent    ;;
        M) echo muted     ;;
        *) echo reset     ;;
    esac
}

# ── Sprite compositing into associative arrays ────────────────────────────
# SPR_CH[x,y] = character to draw at screen position (x,y)
# SPR_CO[x,y] = color role for that character
# Equivalent to the sprite_buffer_t struct in the C twin.
declare -A SPR_CH
declare -A SPR_CO

render_sprite() {
    local frame="$1" ox="$2" oy="$3"
    local row=0
    local line

    while IFS= read -r line; do
        local col=0 i=0 cur_role="reset"

        while (( i < ${#line} )); do
            local ch="${line:i:1}"

            # Token detection: A-C, M, R are color-switch markers, not printed
            if [[ "$ch" =~ ^[ABCMR]$ ]]; then
                cur_role="$(_tok_to_role "$ch")"
                (( i++ ))
                continue
            fi

            local sx=$(( ox + col )) sy=$(( oy + row ))
            if (( sx >= 1 && sx <= W && sy >= 1 && sy <= H )); then
                SPR_CH["$sx,$sy"]="$ch"
                SPR_CO["$sx,$sy"]="$cur_role"
            fi

            (( col++ )); (( i++ ))
        done
        (( row++ ))
    done <<< "$frame"
}

# ── Entity state (fixed-point arithmetic for sub-column precision) ─────────
# x2 = x * 2  →  allows 0.5-column increments without floating point
# This matches the fixed-point scheme in the C twin exactly.
x2=4
y=$(( H / 2 ))
vx2=1                # velocity: +1 = right, -1 = left
tick=0
SPRITE_W=12          # conservative bounding box width for edge detection

# ── Main loop ─────────────────────────────────────────────────────────────
while :; do
    (( tick++ ))

    # Physics: advance position
    (( x2 += vx2 ))
    local_x=$(( x2 / 2 ))

    # Bounce off canvas edges — mirrors wall_bounce() in C twin
    if (( local_x < 1 )); then
        x2=2; vx2=1
    elif (( local_x > W - SPRITE_W )); then
        x2=$(( (W - SPRITE_W) * 2 )); vx2=-1
    fi

    # Select frame from walk cycle
    frame_idx=$(( (tick / TICKS_PER_FRAME) % FRAME_COUNT ))

    # Clear sprite buffers for this tick
    SPR_CH=(); SPR_CO=()

    render_sprite "${FRAMES[$frame_idx]}" "$local_x" "$y"

    # ── Render full canvas ────────────────────────────────────────────────
    # Build each line as a string to minimize write() syscalls.
    # The C twin does the same with a single fwrite() per row.
    home
    local yy
    for (( yy=1; yy<=H; yy++ )); do
        local row_str="" last_role="__none__"
        local xx
        for (( xx=1; xx<=W; xx++ )); do
            local key="$xx,$yy"
            if [[ -n "${SPR_CH[$key]+x}" ]]; then
                local role="${SPR_CO[$key]:-reset}"
                if [[ "$role" != "$last_role" ]]; then
                    row_str+="$(flower_c "$role")"
                    last_role="$role"
                fi
                row_str+="${SPR_CH[$key]}"
            else
                if [[ "$last_role" != "muted" ]]; then
                    row_str+="$(flower_c muted)"
                    last_role="muted"
                fi
                row_str+="$(bg_char_at "$xx" "$yy")"
            fi
        done
        row_str+="$(flower_c reset)"
        printf '%s\n' "$row_str"
    done

    # ── Frame timing ──────────────────────────────────────────────────────
    # Bash has no nanosleep; fractional sleep via awk is the best we can do.
    # The C twin uses nanosleep() directly — exact, no subprocess overhead.
    sleep "$(awk -v ns="$DT_NS" 'BEGIN{ printf "%.6f", ns/1e9 }')"
done
