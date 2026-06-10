#!/usr/bin/env bash
# version-selector.sh — FlowerOS Interactive Beta Version Selector (Bash)
# Usage: bash version-selector.sh
# Navigate: ↑ ↓ arrows or j/k, Enter to select, q to quit.

set -euo pipefail

# ── Colour palette ────────────────────────────────────────────────────────
r=$'\033[0m'       # reset
b=$'\033[1m'       # bold
m=$'\033[35m'      # magenta
c=$'\033[36m'      # cyan
g=$'\033[32m'      # green
y=$'\033[33m'      # yellow
rd=$'\033[31m'     # red
gy=$'\033[90m'     # dark grey
wh=$'\033[97m'     # bright white

ok()   { printf " ${g}[✓]${r} %s\n" "$*"; }
err()  { printf " ${rd}[✗]${r} %s\n" "$*"; }
info() { printf " ${c}[✿]${r} %s\n" "$*"; }
warn() { printf " ${y}[⚠]${r} %s\n" "$*"; }
hdr()  { printf "${m}%s${r}\n" "$*"; }
dim()  { printf "${gy}%s${r}\n" "$*"; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Version registry ──────────────────────────────────────────────────────
# Format: "ver|codename|status|statusColor|date|tier|build_cmd|note"
VERSIONS=(
  "2.8.3|Dandelion RC1|Release Candidate|yellow|2025-Q3|Tier 5 (Linux/WSL active)|bash build.sh|First RC — all v1.3.x experimental features promoted to RC."
  "2.8.4|Dandelion RC2|Release Candidate|yellow|2025-Q3|Tier 5 + Tier-4 Windows|bash build.sh|Tier-4 Windows substrate promoted from scaffolded to functional."
  "2.8.5|Dandelion RC3|Release Candidate|yellow|2025-Q4|Tier 2 + 4 + 5|bash build.sh|Tier-2 kernel moves from prototype to RC."
  "2.9.0|Dandelion Beta 1|Beta|cyan|2026-Q1|Full tier model 1-5|bash build.sh|First integrated beta across all five tiers."
  "2.9.1|Dandelion Beta 2|Beta|cyan|2026-Q1|Full tier model 1-5|bash build.sh|Security and integration hardening before 3.0 stable."
)

# Per-version highlights (indexed 0..4 matching VERSIONS array)
declare -A HIGHLIGHTS
HIGHLIGHTS[0]="Network routing layer stabilised (Rooter.hpp)\nTier-4 Windows IPC broker compiled and tested\nflower-run auto-detects 16 languages\nGames suite: chess, colony, tower-defense finalized\nMOTD composable providers v2"
HIGHLIGHTS[1]="Tier-4 state.json schema v2 (GPU flags, shell profiles)\nNamed-pipe IPC bus hardened — multi-client support\nflower-kernel: parasitic attach on Debian / AlmaLinux\nfp (LaTeX workflow) — watch mode and deps auto-install\nInstall engine: checksum verification for downloads"
HIGHLIGHTS[2]="Tier-2 kernel wrapper: intercept-and-enhance on existing Linux\nflower-userdb: multi-user account model\nGPU batch dispatch (flower-run --gpu --hpc)\nTerminal network node discovery + relay\nColortest: extended 256-color + Unicode flower diagnostics"
HIGHLIGHTS[3]="Full tier model 1-5 — bare metal, parasitic, container, Windows, Linux\nPermanent system install hardened (immutable flags, multi-distro)\nflower-ai optional local inference subsystem scaffold\nTheming v3: palette inheritance, runtime hot-swap\nUnified install engine v2: acquire → verify → build → graft → bloom"
HIGHLIGHTS[4]="Security hardening — Thorns defense subsystem active\nIPC bus: named-pipe + Unix socket bridge for mixed OS nodes\nflower-run: CUDA + OpenCL GPU dispatch fully integrated\nLaTeX fp: multi-file projects, bibliography, watch daemon\nDandelion release tooling: version-selector + compile-check"

# ── Compiler probe ────────────────────────────────────────────────────────
COMPILER_LABEL="none"
CAN_BUILD=0
if command -v gcc   >/dev/null 2>&1; then COMPILER_LABEL="gcc";   CAN_BUILD=1
elif command -v clang >/dev/null 2>&1; then COMPILER_LABEL="clang"; CAN_BUILD=1
fi

# ── Helpers ───────────────────────────────────────────────────────────────
_ver()    { echo "${VERSIONS[$1]}" | cut -d'|' -f1; }
_name()   { echo "${VERSIONS[$1]}" | cut -d'|' -f2; }
_status() { echo "${VERSIONS[$1]}" | cut -d'|' -f3; }
_scol()   { echo "${VERSIONS[$1]}" | cut -d'|' -f4; }
_date()   { echo "${VERSIONS[$1]}" | cut -d'|' -f5; }
_tier()   { echo "${VERSIONS[$1]}" | cut -d'|' -f6; }
_build()  { echo "${VERSIONS[$1]}" | cut -d'|' -f7; }
_note()   { echo "${VERSIONS[$1]}" | cut -d'|' -f8; }

status_color() {
  local s="$1"
  case "$s" in
    yellow) printf "$y" ;;
    cyan)   printf "$c" ;;
    green)  printf "$g" ;;
    red)    printf "$rd" ;;
    *)      printf "$r"  ;;
  esac
}

# ── Draw banner ───────────────────────────────────────────────────────────
draw_banner() {
  clear
  hdr "╔══════════════════════════════════════════════════════════════════╗"
  hdr "║  ✿  FlowerOS  —  Interactive Version Selector                  ║"
  hdr "║      Beta series:  2.8.3  →  2.9.1   (Dandelion)               ║"
  hdr "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
}

# ── Draw version list ─────────────────────────────────────────────────────
draw_list() {
  local sel="$1"
  printf "  Use ${y}↑ ↓ / j k${r} to navigate,  ${g}Enter${r} to select,  ${rd}q${r} to quit\n"
  printf "  ─────────────────────────────────────────────────────────────\n\n"

  for i in "${!VERSIONS[@]}"; do
    local ver; ver=$(_ver  $i)
    local nm;  nm=$(_name  $i)
    local st;  st=$(_status $i)
    local sc;  sc=$(_scol  $i)
    local scolor; scolor=$(status_color "$sc")

    if [[ $i -eq $sel ]]; then
      printf "  ${c}► v%-5s  ${wh}%-22s${r}${scolor}[%s]${r}\n" "$ver" "$nm" "$st"
    else
      printf "    ${gy}v%-5s  %-22s${r}${scolor}[%s]${r}\n" "$ver" "$nm" "$st"
    fi
  done
  echo ""
}

# ── Draw detail panel ─────────────────────────────────────────────────────
draw_detail() {
  local idx="$1"
  local ver; ver=$(_ver  $idx)
  local nm;  nm=$(_name  $idx)
  local st;  st=$(_status $idx)
  local sc;  sc=$(_scol  $idx)
  local dt;  dt=$(_date  $idx)
  local tr;  tr=$(_tier  $idx)
  local nt;  nt=$(_note  $idx)
  local scolor; scolor=$(status_color "$sc")

  printf "  ─────────────────────────────────────────────────────────────\n"
  printf "  Version   ${c}%s${r}\n"                    "$ver"
  printf "  Codename  ${m}%s${r}\n"                    "$nm"
  printf "  Status    ${scolor}%s${r}\n"               "$st"
  printf "  Target    ${gy}%s${r}\n"                   "$dt"
  printf "  Tiers     ${gy}%s${r}\n"                   "$tr"
  echo ""
  printf "  ${y}Highlights:${r}\n"
  echo -e "${HIGHLIGHTS[$idx]}" | while IFS= read -r line; do
    printf "    ${gy}•${r} %s\n" "$line"
  done
  echo ""

  printf "  ${y}Build:${r}\n"
  local bcmd; bcmd=$(_build $idx)
  printf "    ${g}%s${r}\n" "$bcmd"
  echo ""

  printf "  ${y}Compiler status:${r}\n"
  if [[ $CAN_BUILD -eq 1 ]]; then
    printf "    ${g}✓  %s detected — full build supported${r}\n" "$COMPILER_LABEL"
  else
    printf "    ${rd}✗  No compatible compiler found${r}\n"
    printf "    ${gy}   sudo apt install build-essential${r}\n"
  fi

  echo ""
  dim "  Note: $nt"
  printf "  ─────────────────────────────────────────────────────────────\n\n"
}

# ── Compile check helper ──────────────────────────────────────────────────
run_compile_check() {
  local ver="$1"
  echo ""
  info "Running compile check for v$ver..."
  echo ""

  local CFLAGS="-O2 -std=c11 -Wall -Wextra"
  local pass=0 fail=0

  for src in \
    "src/utils/banner.c:banner" \
    "src/utils/fortune.c:fortune" \
    "src/utils/colortest.c:colortest" \
    "src/utils/random.c:random" \
    "src/utils/animate.c:animate"
  do
    local file="${src%%:*}"
    local name="${src##*:}"
    local fullpath="$REPO/$file"
    if [[ ! -f "$fullpath" ]]; then
      dim "  $(printf '%-14s' "$name") missing  ($file)"
      continue
    fi
    local tmpout
    tmpout="$(mktemp)"
    if gcc $CFLAGS -o "$tmpout" "$fullpath" 2>/dev/null; then
      ok "$(printf '%-14s' "$name") compiled OK"
      pass=$((pass+1))
    else
      err "$(printf '%-14s' "$name") FAILED"
      fail=$((fail+1))
    fi
    rm -f "$tmpout"
  done

  echo ""
  if [[ $fail -eq 0 ]]; then
    ok "Compile check: $pass sources passed"
  else
    warn "Compile check: $pass passed, $fail failed"
  fi
  echo ""
}

# ── Build action ──────────────────────────────────────────────────────────
invoke_build() {
  local idx="$1"
  local ver; ver=$(_ver $idx)
  local nm;  nm=$(_name $idx)

  draw_banner
  hdr "  ✿  Building FlowerOS v$ver  —  $nm"
  echo ""

  if [[ $CAN_BUILD -eq 1 ]]; then
    ok "Compiler: $COMPILER_LABEL"
    run_compile_check "$ver"

    read -rp "  Proceed with full build? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn] ]]; then
      info "Build cancelled."
    else
      if [[ -f "$REPO/build.sh" ]]; then
        bash "$REPO/build.sh"
      else
        err "build.sh not found at $REPO/build.sh"
      fi
    fi
  else
    err "No compatible compiler available"
    warn "Cannot build v$ver without gcc or clang"
    echo ""
    echo "  Install options:"
    printf "    ${c}Debian/Ubuntu:${r}  sudo apt install build-essential\n"
    printf "    ${c}Fedora/RHEL:${r}    sudo dnf install gcc make\n"
    printf "    ${c}Arch:${r}           sudo pacman -S base-devel\n"
    printf "    ${c}macOS:${r}          xcode-select --install\n"
    echo ""
  fi

  echo ""
  printf "  ${gy}Press Enter to return to the selector...${r} "
  read -r
}

# ── Key reader (arrow keys) ───────────────────────────────────────────────
read_key() {
  local esc seq
  IFS= read -r -s -n1 esc
  if [[ "$esc" == $'\x1b' ]]; then
    IFS= read -r -s -n1 -t0.1 seq
    if [[ "$seq" == "[" ]]; then
      IFS= read -r -s -n1 -t0.1 seq
      case "$seq" in
        A) echo "UP" ;;
        B) echo "DOWN" ;;
        *) echo "OTHER" ;;
      esac
    else
      echo "ESC"
    fi
  else
    echo "$esc"
  fi
}

# ═════════════════════════════════════════════════════════════════════════
#  MAIN — interactive loop
# ═════════════════════════════════════════════════════════════════════════
sel=0
total=${#VERSIONS[@]}

# Disable terminal echo/line mode
old_stty=$(stty -g)
trap "stty '$old_stty'; echo ''; exit 0" INT TERM
stty -echo -icanon min 1 time 0

while true; do
  draw_banner
  draw_list "$sel"
  draw_detail "$sel"

  if [[ $CAN_BUILD -eq 1 ]]; then
    printf "  ${g}Compiler: $COMPILER_LABEL${r}  •  Press Enter to compile-check + build selected version\n"
  else
    printf "  ${rd}No compiler${r}  •  Install gcc or clang, then re-run this selector\n"
  fi
  echo ""

  key=$(read_key)

  case "$key" in
    UP|k)
      if [[ $sel -gt 0 ]]; then sel=$((sel-1)); else sel=$((total-1)); fi
      ;;
    DOWN|j)
      if [[ $sel -lt $((total-1)) ]]; then sel=$((sel+1)); else sel=0; fi
      ;;
    $'\n'|$'\r')
      stty "$old_stty"
      invoke_build "$sel"
      old_stty=$(stty -g)
      stty -echo -icanon min 1 time 0
      ;;
    q|Q)
      stty "$old_stty"
      clear
      hdr "  ✿  FlowerOS version selector — exited"
      dim "     Selected: v$(_ver $sel)  ($(_name $sel))"
      echo ""
      exit 0
      ;;
    1|2|3|4|5)
      idx=$((key-1))
      if [[ $idx -ge 0 && $idx -lt $total ]]; then sel=$idx; fi
      ;;
  esac
done
