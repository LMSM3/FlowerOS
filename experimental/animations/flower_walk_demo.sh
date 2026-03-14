#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  flower_walk_demo.sh  —  directional side-scrolling walk demo
#
#  The character walks right, bounces off the edge, flips to face left,
#  walks back, and repeats indefinitely.
#
#  Usage:  bash features/flower_walk_demo.sh
#          FPS=18 bash features/flower_walk_demo.sh
#
# ───────────────────────────────────────────────────────────────────────────
#  How this differs from flower_walk.sh
#  flower_walk.sh  — assoc-array compositing over a full background canvas.
#                    Correct architecture for multi-sprite scenes.
#  THIS FILE       — cursor-position draw/erase per sprite.
#                    Faster for a single directional character.
#                    Output is buffered into one printf per frame to
#                    minimise flicker (shell double-buffer technique).
#
# ───────────────────────────────────────────────────────────────────────────
#  Art contribution note
#  The sprites below are functional placeholders.  The frame functions
#  (sprite_right / sprite_left) are designed to be dropped-in replaced —
#  swap any line string without touching the engine.
#  Each frame function signature:  frame_R<N>() and frame_L<N>()
#  Return value:  prints 10 lines (no trailing newline on last).
#  The engine calls them and positions each line via ANSI cursor movement.
#
# ───────────────────────────────────────────────────────────────────────────
#  C backend note
#  src/utils/flower_walk.c is the production twin.
#  It uses the same sprite tables + nanosleep for smooth 60fps.
#  One-liner: gcc -O2 -std=c11 $(bash2c flower_walk_demo.sh) -o flower-walk
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Delegate to compiled C backend if present ────────────────────────────
# Resolution order (Tier 5 permanent install → user build → dev build):
#   1. /opt/floweros/bin/flower-walk   (installed via install-permanent.sh)
#   2. $FLOWEROS_DIR/../bin/flower-walk (user-level build)
#   3. src/flower-walk                  (local dev build)
_C_CANDIDATES=(
    "/opt/floweros/bin/flower-walk"
    "${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-walk}"
    "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../src/flower-walk"
)
for _C in "${_C_CANDIDATES[@]}"; do
    [[ -x "${_C:-}" ]] && exec "${_C}" "$@"
done
unset _C _C_CANDIDATES

# ── Color setup ───────────────────────────────────────────────────────────
# Load theme system if available; fall back to hardcoded pastel 256-color.
# These values must match the FOS_* constants in src/floweros.h exactly.
_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../lib/flower_ascii.sh"
[[ -f "$_LIB" ]] && source "$_LIB"

if ! declare -f flower_c >/dev/null 2>&1; then
    flower_c() {
        case "${1:-reset}" in
            primary)   printf '\033[38;5;117m' ;;  # mint-cyan
            secondary) printf '\033[38;5;183m' ;;  # soft magenta
            accent)    printf '\033[38;5;159m' ;;  # light cyan
            muted)     printf '\033[38;5;245m' ;;  # grey
            reset|*)   printf '\033[0m' ;;
        esac
    }
fi

# Bind color roles to single-letter locals (same convention as flower_guy.c)
#   A = primary   B = secondary   M = muted   R = reset
A=$(flower_c primary)
B=$(flower_c secondary)
M=$(flower_c muted)
R=$(flower_c reset)

# ── Terminal setup ────────────────────────────────────────────────────────
FPS="${FPS:-14}"
DT_NS=$(( 1000000000 / FPS ))

W="${COLUMNS:-$(tput cols  2>/dev/null || echo 80)}"
H="${LINES:-$(  tput lines 2>/dev/null || echo 24)}"
(( H -= 2 ))
(( H < 12 )) && H=12

SPRITE_W=12    # bounding-box width  (used for right-edge bounce)
SPRITE_H=10    # bounding-box height (number of lines per frame)

cur() { printf '\033[%d;%dH' "$1" "$2"; }   # move cursor to row,col
alt_on()  { printf '\033[?1049h'; }
alt_off() { printf '\033[?1049l'; }
hide()    { printf '\033[?25l'; }
show()    { printf '\033[?25h'; }

cleanup() { show; alt_off; printf '%s' "$R"; }
trap cleanup EXIT INT TERM

alt_on; hide

# ═══════════════════════════════════════════════════════════════════════════
#  Sprite frames — RIGHT-FACING  (4 frames, 10 lines each)
#
#  Walk cycle:  R0 → R1 → R2 → R3 → R0 → …
#
#  Petals stay constant across all frames.
#  The direction indicator ( > ) sits on the head line.
#  Lines 8–9 are the legs — these are the only lines that differ.
#
#  ┌───────────────────────────────────────────────────────────┐
#  │  To replace with your own art: edit only these functions. │
#  │  Keep exactly 10 lines per function, maintain SPRITE_W.   │
#  └───────────────────────────────────────────────────────────┘
# ═══════════════════════════════════════════════════════════════════════════

#  Leg patterns for RIGHT walk (read bottom-up: feet, then upper leg):
#
#  R0  neutral contact     R1  left push-off      R2  mid-float         R3  right push-off
#    / \                     _/ \                   / \                    / \_
#   o   o                   o   o                  o   o                  o   o

frame_R0() {      # neutral — both feet flat
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B} (${A} .~. ${B})       " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${M}  .(${A}^${M}).${B}>       " \
        "${M}   |=|          " \
        "${M}   / \\         " \
        "${M}  o   o         ${R}"
}

frame_R1() {      # left foot pushes off, right foot swings forward
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B} (${A} .~. ${B})       " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${M}  .(${A}^${M}).${B}>       " \
        "${M}   |=|          " \
        "${M}  _/ \\         " \
        "${M}  o   o         ${R}"
}

frame_R2() {      # mid-stride — weight transfers, brief float
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B} (${A} .~. ${B})       " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${M}  .(${A}~${M}).${B}>       " \
        "${M}   |=|          " \
        "${M}   / \\         " \
        "${M}  o   o         ${R}"
}

frame_R3() {      # right foot pushes off, left foot swings forward
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B} (${A} .~. ${B})       " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${M}  .(${A}^${M}).${B}>       " \
        "${M}   |=|          " \
        "${M}   / \\_        " \
        "${M}  o   o         ${R}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Sprite frames — LEFT-FACING  (4 frames, 10 lines each)
#
#  Mirror of the RIGHT frames:
#    • ( > ) replaced with ( < ) on head line
#    • Leg lean direction inverted
#    • Walk phase offset by 2 so stride is continuous through the bounce
#
#  Leg patterns for LEFT walk:
#
#  L0  neutral              L1  right push-off      L2  mid-float         L3  left push-off
#    / \                    / \_                     / \                   _/ \
#   o   o                  o   o                   o   o                  o   o
# ═══════════════════════════════════════════════════════════════════════════

frame_L0() {
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B}       (${A} .~. ${B})  " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${B}<${M}.(${A}^${M}).         " \
        "${M}   |=|          " \
        "${M}   / \\         " \
        "${M}  o   o         ${R}"
}

frame_L1() {      # right foot pushes off (mirror of R1)
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B}       (${A} .~. ${B})  " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${B}<${M}.(${A}^${M}).         " \
        "${M}   |=|          " \
        "${M}   / \\_        " \
        "${M}  o   o         ${R}"
}

frame_L2() {      # mid-float (mirror of R2)
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B}       (${A} .~. ${B})  " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${B}<${M}.(${A}~${M}).         " \
        "${M}   |=|          " \
        "${M}   / \\         " \
        "${M}  o   o         ${R}"
}

frame_L3() {      # left foot pushes off (mirror of R3)
    printf '%s\n' \
        "${B}    .~.          " \
        "${B}  .(   ).        " \
        "${B}       (${A} .~. ${B})  " \
        "${B}  \`-(   )-'      " \
        "${B}    \`-'          " \
        "${M}    _|_          " \
        "${B}<${M}.(${A}^${M}).         " \
        "${M}   |=|          " \
        "${M}  _/ \\         " \
        "${M}  o   o         ${R}"
}

# ── Frame dispatch tables ─────────────────────────────────────────────────
# Indexed by frame_idx (0–3).  Engine calls get_frame facing frame_idx.
# To extend to 8 frames: add frame_R4–R7 and frame_L4–L7 above, then
# change FRAME_COUNT to 8 and TICKS_PER_FRAME to 4.

FRAME_COUNT=4
TICKS_PER_FRAME=5

get_frame() {
    local facing="$1" idx="$2"
    case "${facing}${idx}" in
        r0) frame_R0 ;; r1) frame_R1 ;; r2) frame_R2 ;; r3) frame_R3 ;;
        l0) frame_L0 ;; l1) frame_L1 ;; l2) frame_L2 ;; l3) frame_L3 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  Erase — draw spaces over old sprite bounding box
#  Called before drawing to avoid ghost pixels.
#  Uses the same bounding-box approach as the C twin.
# ═══════════════════════════════════════════════════════════════════════════

BLANK_LINE="$(printf '%*s' "$SPRITE_W" '')"

erase_sprite() {
    local ox="$1" oy="$2"
    local buf=""
    local r
    for (( r=0; r<SPRITE_H; r++ )); do
        local row=$(( oy + r ))
        (( row < 1 || row > H )) && continue
        buf+=$(printf '\033[%d;%dH%s' "$row" "$ox" "$BLANK_LINE")
    done
    printf '%s' "$buf"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Draw — cursor-position each line of the sprite
#  Output is buffered into a single string; written with one printf call
#  to minimise tty write() calls — this is the shell double-buffer trick.
# ═══════════════════════════════════════════════════════════════════════════

draw_sprite() {
    local ox="$1" oy="$2" facing="$3" frame_idx="$4"
    local buf="" row=0 line

    while IFS= read -r line; do
        local screen_row=$(( oy + row ))
        if (( screen_row >= 1 && screen_row <= H )); then
            buf+=$(printf '\033[%d;%dH%s' "$screen_row" "$ox" "$line")
        fi
        (( row++ ))
    done < <(get_frame "$facing" "$frame_idx")

    printf '%s' "$buf"
}

# ── Ground line ───────────────────────────────────────────────────────────
draw_ground() {
    local ground_row=$(( H - 1 ))
    printf '\033[%d;1H%s' "$ground_row" \
        "$(printf '%*s' "$W" '' | tr ' ' '─')${R}"
}

# ── Status bar ────────────────────────────────────────────────────────────
draw_status() {
    local facing="$1" x="$2"
    local dir_char="→"; [[ "$facing" == "l" ]] && dir_char="←"
    printf '\033[%d;2H%s  %s  x=%-4d  FPS=%-3d  q=quit%s' \
        "$H" "${M}" "$dir_char" "$x" "$FPS" "${R}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main loop
# ═══════════════════════════════════════════════════════════════════════════

# Initial state
px=4                           # horizontal position (column of sprite left edge)
py=$(( H / 2 - SPRITE_H / 2 )) # vertical centre
(( py < 1 )) && py=1
facing="r"                     # "r" = right, "l" = left
tick=0
frame_idx=0

prev_px=$px
prev_facing=$facing

# Draw static elements once
printf '\033[2J'               # clear screen
draw_ground

# Handle 'q' to quit gracefully (non-blocking read in background)
quit=0
_quit_check() {
    local key
    read -r -s -n1 -t0.001 key 2>/dev/null && [[ "$key" == "q" ]] && quit=1
    true
}

while (( ! quit )); do

    # ── Erase old position ──────────────────────────────────────────────
    erase_sprite "$prev_px" "$py"

    # ── Advance position ────────────────────────────────────────────────
    if [[ "$facing" == "r" ]]; then
        (( px++ ))
        # Bounce: hit right edge → flip to left-facing
        if (( px + SPRITE_W >= W )); then
            px=$(( W - SPRITE_W - 1 ))
            facing="l"
            # Phase-offset the frame so stride is continuous through the flip
            frame_idx=$(( (frame_idx + 2) % FRAME_COUNT ))
        fi
    else
        (( px-- ))
        # Bounce: hit left edge → flip to right-facing
        if (( px <= 1 )); then
            px=2
            facing="r"
            frame_idx=$(( (frame_idx + 2) % FRAME_COUNT ))
        fi
    fi

    # ── Advance walk frame ───────────────────────────────────────────────
    (( tick++ ))
    if (( tick % TICKS_PER_FRAME == 0 )); then
        frame_idx=$(( (frame_idx + 1) % FRAME_COUNT ))
    fi

    # ── Draw new position ────────────────────────────────────────────────
    draw_sprite "$px" "$py" "$facing" "$frame_idx"
    draw_status "$facing" "$px"

    prev_px=$px
    prev_facing=$facing

    # ── Frame timing ─────────────────────────────────────────────────────
    # Bash has no nanosleep.  awk fractional sleep is the closest we get.
    # The C twin uses nanosleep() — exact, zero subprocess overhead.
    sleep "$(awk -v ns="$DT_NS" 'BEGIN{ printf "%.4f", ns/1e9 }')"

    _quit_check
done
