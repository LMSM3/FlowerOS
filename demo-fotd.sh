#!/usr/bin/env bash
# FlowerOS FOTD Interactive Demo — pretend user session
# Cycles through all flowers, sizes, and pastel settings
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

C=$'\033[36m' G=$'\033[32m' M=$'\033[35m' Y=$'\033[33m' Z=$'\033[0m'

banner() {
    echo ""
    echo "${M}╔══════════════════════════════════════════════════════════╗${Z}"
    echo "${M}║  🌸 FlowerOS FOTD — Flower Of The Day — Demo Session   ║${Z}"
    echo "${M}╚══════════════════════════════════════════════════════════╝${Z}"
    echo ""
}

sep() { echo "${C}──────────────────────────────────────────────────${Z}"; }

# ── Session 1: Random FOTD pick (what flower-motd.sh does) ───────────────
banner
echo "${Y}Session 1: Random FOTD pick (simulating login)${Z}"
sep
pngs=( motd/Import/*.png )
idx=$(( RANDOM % ${#pngs[@]} ))
pick="${pngs[$idx]}"
name="$(basename "${pick%.*}")"
echo "  Today's flower: #${name}"
echo ""
./png2term "$pick" 34 0.55
echo ""

# ── Session 2: Cycle all 12 flowers at sidebar width ─────────────────────
echo "${Y}Session 2: Cycle ALL 12 flowers at FOTD sidebar (34 cols)${Z}"
sep
for f in motd/Import/*.png; do
    n="$(basename "${f%.*}")"
    printf "\n${C}── FOTD #%s ──${Z}\n" "$n"
    ./png2term "$f" 34 0.55
done
echo ""

# ── Session 3: Size comparison on one image ──────────────────────────────
echo "${Y}Session 3: Size comparison — flower #03${Z}"
sep
for size in 20 34 60 80; do
    printf "\n${G}→ %d columns:${Z}\n" "$size"
    ./png2term motd/Import/03.png "$size" 0.55
done
echo ""

# ── Session 4: Pastel strength sweep ─────────────────────────────────────
echo "${Y}Session 4: Pastel sweep on flower #07${Z}"
sep
for p in 0.0 0.25 0.55 0.80 1.0; do
    printf "\n${G}→ pastel=$p:${Z}\n"
    ./png2term motd/Import/07.png 40 "$p"
done
echo ""

# ── Session 5: Rapid fire — 3 random picks in a row ─────────────────────
echo "${Y}Session 5: Rapid fire — 3 random FOTD picks${Z}"
sep
for round in 1 2 3; do
    idx=$(( RANDOM % ${#pngs[@]} ))
    pick="${pngs[$idx]}"
    name="$(basename "${pick%.*}")"
    printf "\n${M}🌸 Draw #%d: flower #%s${Z}\n" "$round" "$name"
    ./png2term "$pick" 50 0.55
done
echo ""

# ── Session 6: Pre-render pipeline (what build-motd.sh does) ────────────
echo "${Y}Session 6: Pre-render pipeline — flower #05 at all sizes${Z}"
sep
for variant in "small 60" "medium 120" "large 160" "hash 120"; do
    label="${variant%% *}"
    cols="${variant##* }"
    pastel=0.55
    [[ "$label" == "hash" ]] && pastel=0.40
    out="motd/ascii-output/05-${label}.ascii"
    ./png2term motd/Import/05.png "$cols" "$pastel" > "$out"
    sz=$(du -h "$out" | cut -f1)
    printf "  ${G}✓${Z} %s (%s cols): %s\n" "$label" "$cols" "$sz"
done
echo ""

echo "${M}╔══════════════════════════════════════════════════════════╗${Z}"
echo "${M}║  🌺 FOTD Demo Complete — all sessions passed!           ║${Z}"
echo "${M}╚══════════════════════════════════════════════════════════╝${Z}"
echo ""
