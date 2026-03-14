#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  lib/shell_extras.sh  —  FlowerOS shell conveniences & aliases
#
#  Sourced by .flowerrc after core functions load.
#  Safe to re-source (idempotent via guard).
#
#  Sections:
#    1. Dev-mode gate          (FLOWEROS_DEV=1 to enable dev features)
#    2. FlowerOS aliases       (games, tools, MOTD, publish, run)
#    3. General shell aliases  (ls, git, nav, safety)
#    4. Lazy NVM loader        (node/npm/npx without startup cost)
#    5. rm_safe                (blocks `rm /`, prompts on bulk)
#    6. trash()                (dev-mode only — move to XDG trash)
#    7. fhelp / helpAlias      (list everything registered here)
#    8. File watchers          (watch_build, watch_latex, watch_test)
# ═══════════════════════════════════════════════════════════════════════════

[[ -n "${_FLOWEROS_EXTRAS_LOADED:-}" ]] && return 0
_FLOWEROS_EXTRAS_LOADED=1

# ─── 1. Dev-mode gate ────────────────────────────────────────────────────
#  export FLOWEROS_DEV=1   → enables trash(), verbose watchers
#  default: off (production behaviour)
FLOWEROS_DEV="${FLOWEROS_DEV:-0}"

# ═══════════════════════════════════════════════════════════════════════════
#  2. FlowerOS tool aliases
# ═══════════════════════════════════════════════════════════════════════════

# ── Games ──
alias chess='flower-chess'
alias colony='flower-colony'
alias td='flower-td'
alias games='flower-play'

# ── Tools ──
alias todo='flower-todo'
alias fp='fp'

# ── MOTD / Character ──
alias motd='flower-motd'
alias guy='flower-guy'
alias guy-random='flower-guy --random'

# ── Runner ──
alias frun='flower-run'
alias fhpc='flower-run --hpc --time'
alias fgpu='flower-run --gpu --hpc --time'

# ── Core utils ──
alias fbanner='flower_banner'
alias ffortune='flower_fortune'
alias fcolor='flower_colortest'
alias fvisual='flower_visual'
alias fanimate='flower_animate'

# ── System ──
alias freload='source ~/.flowerrc && echo "✿ FlowerOS reloaded"'
alias fversion='echo "FlowerOS ${FLOWEROS_VERSION:-?}"'
alias fconfig='${EDITOR:-nano} "${HOME}/.floweros/preferences.conf"'

# ═══════════════════════════════════════════════════════════════════════════
#  3. General shell aliases
# ═══════════════════════════════════════════════════════════════════════════

# ── ls family ──
alias ll='ls -lAhF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lt='ls -lAhFt --color=auto'          # newest first
alias lS='ls -lAhFS --color=auto'          # largest first

# ── Navigation ──
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ── Git shortcuts ──
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -15'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gpl='git pull'

# ── Misc safety / convenience ──
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'

# ═══════════════════════════════════════════════════════════════════════════
#  4. Lazy NVM loader (zero startup cost until first use)
# ═══════════════════════════════════════════════════════════════════════════

if [[ -d "${NVM_DIR:-$HOME/.nvm}" ]] && ! command -v __nvm_loaded >/dev/null 2>&1; then
  _floweros_lazy_nvm() {
    unset -f node npm npx nvm _floweros_lazy_nvm
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  }
  node() { _floweros_lazy_nvm; node "$@"; }
  npm()  { _floweros_lazy_nvm; npm  "$@"; }
  npx()  { _floweros_lazy_nvm; npx  "$@"; }
  nvm()  { _floweros_lazy_nvm; nvm  "$@"; }
fi

# ═══════════════════════════════════════════════════════════════════════════
#  5. rm_safe  — block `rm /` and prompt on bulk deletes
# ═══════════════════════════════════════════════════════════════════════════

rm_safe() {
  for arg in "$@"; do
    if [[ "$arg" = "/" || "$arg" = "/*" ]]; then
      echo -e "\033[31m✗ absolutely not.\033[0m"
      return 1
    fi
  done
  command rm -I "$@"
}
alias rm='rm_safe'

# ═══════════════════════════════════════════════════════════════════════════
#  6. trash()  — move to XDG trash instead of deleting
#     Only active when FLOWEROS_DEV=1  (off by default)
# ═══════════════════════════════════════════════════════════════════════════

if (( FLOWEROS_DEV )); then
  trash() {
    local _trash="${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files"
    mkdir -p "$_trash"
    for f in "$@"; do
      if [[ ! -e "$f" ]]; then
        echo -e "\033[33m⚠ not found: $f\033[0m" >&2
        continue
      fi
      local base dest
      base="$(basename "$f")"
      dest="$_trash/$base"
      # avoid clobber — append timestamp if collision
      [[ -e "$dest" ]] && dest="${dest}.$(date +%s)"
      mv -- "$f" "$dest"
      echo -e "\033[38;5;245m  → trashed: $base\033[0m"
    done
  }
else
  trash() {
    echo -e "\033[33m⚠ trash() is disabled in production mode.\033[0m"
    echo "  Enable with: export FLOWEROS_DEV=1 && freload"
    return 1
  }
fi

# ═══════════════════════════════════════════════════════════════════════════
#  7. fhelp / helpAlias  — show every FlowerOS alias & function
# ═══════════════════════════════════════════════════════════════════════════

fhelp() {
  local c="\033[36m" g="\033[38;5;120m" d="\033[38;5;245m" y="\033[33m" z="\033[0m"
  local m="\033[38;5;183m"

  echo -e "${m}╔══════════════════════════════════════════════════════════════╗${z}"
  echo -e "${m}║${z}  ${c}✿  FlowerOS Shell Reference${z}  ${d}(lib/shell_extras.sh)${z}       ${m}║${z}"
  echo -e "${m}╚══════════════════════════════════════════════════════════════╝${z}"
  echo ""

  echo -e "${c}── Games ──────────────────────────────────────────────────────${z}"
  echo -e "  ${g}chess${z}          ${d}→ flower-chess    (alpha-beta engine)${z}"
  echo -e "  ${g}colony${z}         ${d}→ flower-colony   (hex survival)${z}"
  echo -e "  ${g}td${z}             ${d}→ flower-td       (tower defense)${z}"
  echo -e "  ${g}games${z}          ${d}→ flower-play     (launcher menu)${z}"
  echo ""

  echo -e "${c}── Tools ──────────────────────────────────────────────────────${z}"
  echo -e "  ${g}todo${z}           ${d}→ flower-todo     (task notepad)${z}"
  echo -e "  ${g}fp${z}             ${d}→ fp              (LaTeX publish)${z}"
  echo -e "  ${g}motd${z}           ${d}→ flower-motd     (login screen)${z}"
  echo -e "  ${g}guy${z}            ${d}→ flower-guy      (character art)${z}"
  echo -e "  ${g}guy-random${z}     ${d}→ flower-guy --random${z}"
  echo ""

  echo -e "${c}── Runner ─────────────────────────────────────────────────────${z}"
  echo -e "  ${g}frun${z}  <file>   ${d}→ flower-run      (auto-detect lang)${z}"
  echo -e "  ${g}fhpc${z}  <file>   ${d}→ flower-run --hpc --time${z}"
  echo -e "  ${g}fgpu${z}  <file>   ${d}→ flower-run --gpu --hpc --time${z}"
  echo ""

  echo -e "${c}── Core Utils ─────────────────────────────────────────────────${z}"
  echo -e "  ${g}fbanner${z}  text  ${d}→ flower_banner   (ASCII banner)${z}"
  echo -e "  ${g}ffortune${z}      ${d}→ flower_fortune   (wisdom)${z}"
  echo -e "  ${g}fcolor${z}        ${d}→ flower_colortest (256-color diag)${z}"
  echo -e "  ${g}fvisual${z}       ${d}→ flower_visual    (charts/sparklines)${z}"
  echo -e "  ${g}fanimate${z}      ${d}→ flower_animate   (play .anim)${z}"
  echo ""

  echo -e "${c}── System ─────────────────────────────────────────────────────${z}"
  echo -e "  ${g}freload${z}       ${d}→ re-source .flowerrc${z}"
  echo -e "  ${g}fversion${z}      ${d}→ print FlowerOS version${z}"
  echo -e "  ${g}fconfig${z}       ${d}→ edit user preferences${z}"
  echo -e "  ${g}floweros-info${z} ${d}→ installed version from config${z}"
  echo ""

  echo -e "${c}── Shell Shortcuts ────────────────────────────────────────────${z}"
  echo -e "  ${g}ll${z}  ${d}ls -lAhF${z}      ${g}lt${z}  ${d}ls -lAhFt (newest)${z}  ${g}lS${z}  ${d}ls -lAhFS (largest)${z}"
  echo -e "  ${g}..${z}  ${d}cd ..${z}          ${g}...${z} ${d}cd ../..${z}            ${g}-${z}   ${d}cd - (back)${z}"
  echo -e "  ${g}gs${z}  ${d}git status${z}     ${g}ga${z}  ${d}git add${z}             ${g}gc${z}  ${d}git commit${z}"
  echo -e "  ${g}gp${z}  ${d}git push${z}       ${g}gl${z}  ${d}git log --oneline${z}   ${g}gd${z}  ${d}git diff${z}"
  echo -e "  ${g}gpl${z} ${d}git pull${z}       ${g}gco${z} ${d}git checkout${z}        ${g}gb${z}  ${d}git branch${z}"
  echo ""

  echo -e "${c}── Safety ─────────────────────────────────────────────────────${z}"
  echo -e "  ${g}rm${z}  ${d}→ rm_safe (blocks rm /, prompts bulk)${z}"
  echo -e "  ${g}cp${z}  ${d}→ cp -iv${z}       ${g}mv${z}  ${d}→ mv -iv${z}       ${g}mkdir${z}  ${d}→ mkdir -pv${z}"
  echo ""

  echo -e "${c}── Dev Mode ───────────────────────────────────────────────────${z}"
  local _dev_st="${y}OFF${z}"
  (( FLOWEROS_DEV )) && _dev_st="${g}ON${z}"
  echo -e "  FLOWEROS_DEV=${_dev_st}"
  echo -e "  ${g}trash${z} <files>  ${d}→ move to ~/.local/share/Trash/files/${z}"
  if ! (( FLOWEROS_DEV )); then
    echo -e "                ${d}  (enable: export FLOWEROS_DEV=1 && freload)${z}"
  fi
  echo ""

  echo -e "${c}── File Watchers ──────────────────────────────────────────────${z}"
  echo -e "  ${g}watch_build${z}  [dir]       ${d}→ inotify cmake rebuild loop${z}"
  echo -e "  ${g}watch_make${z}   [dir]       ${d}→ inotify make rebuild loop${z}"
  echo -e "  ${g}watch_latex${z}  <file.tex>  ${d}→ inotify pdflatex recompile${z}"
  echo -e "  ${g}watch_test${z}   [dir]       ${d}→ inotify ctest / make test loop${z}"
  echo -e "  ${g}watch_run${z}    <file>      ${d}→ inotify frun re-execute${z}"
  echo ""

  echo -e "${d}Tip: fhelp | grep <keyword>${z}"
}
alias helpAlias='fhelp'

# ═══════════════════════════════════════════════════════════════════════════
#  8. File watchers  (inotifywait-based automation hooks)
#     Requires: inotify-tools  (apt install inotify-tools)
# ═══════════════════════════════════════════════════════════════════════════

_fos_require_inotify() {
  if ! command -v inotifywait >/dev/null 2>&1; then
    echo -e "\033[33m⚠ inotifywait not found.\033[0m"
    echo "  Install:  sudo apt install inotify-tools"
    return 1
  fi
  return 0
}

# ── watch_build: cmake --build loop ──────────────────────────────────────
watch_build() {
  _fos_require_inotify || return 1
  local target="${1:-.}"
  local build_dir="${2:-build}"
  echo -e "\033[36m✿ Watching ${target} → cmake --build ${build_dir}\033[0m"
  echo -e "\033[38;5;245m  Ctrl-C to stop\033[0m"
  while true; do
    inotifywait -qqre modify,create,delete \
      --include '\.(c|cpp|h|hpp|cxx|cmake|txt)$' "$target"
    echo -e "\n\033[33m⟳ Change detected — rebuilding…\033[0m"
    cmake --build "$build_dir" -j"$(nproc)" 2>&1
    echo -e "\033[32m✓ Build finished\033[0m\n"
  done
}

# ── watch_make: plain make loop ──────────────────────────────────────────
watch_make() {
  _fos_require_inotify || return 1
  local target="${1:-.}"
  echo -e "\033[36m✿ Watching ${target} → make\033[0m"
  echo -e "\033[38;5;245m  Ctrl-C to stop\033[0m"
  while true; do
    inotifywait -qqre modify,create,delete \
      --include '\.(c|cpp|h|hpp|s|S|asm|mk)$' "$target"
    echo -e "\n\033[33m⟳ Change detected — rebuilding…\033[0m"
    make -C "$target" -j"$(nproc)" 2>&1
    echo -e "\033[32m✓ Build finished\033[0m\n"
  done
}

# ── watch_latex: pdflatex recompile on .tex change ───────────────────────
watch_latex() {
  _fos_require_inotify || return 1
  local texfile="${1:?Usage: watch_latex <file.tex>}"
  [[ -f "$texfile" ]] || { echo -e "\033[31m✗ $texfile not found\033[0m"; return 1; }
  local dir
  dir="$(dirname "$texfile")"
  echo -e "\033[36m✿ Watching ${texfile} → pdflatex\033[0m"
  echo -e "\033[38;5;245m  Ctrl-C to stop\033[0m"
  while true; do
    inotifywait -qqe modify "$texfile"
    echo -e "\n\033[33m⟳ Recompiling…\033[0m"
    pdflatex -interaction=nonstopmode -output-directory="$dir" "$texfile" 2>&1 \
      | tail -5
    echo -e "\033[32m✓ pdflatex finished\033[0m\n"
  done
}

# ── watch_test: rerun tests on source change ─────────────────────────────
watch_test() {
  _fos_require_inotify || return 1
  local target="${1:-.}"
  local build_dir="${2:-build}"
  echo -e "\033[36m✿ Watching ${target} → rebuild + ctest\033[0m"
  echo -e "\033[38;5;245m  Ctrl-C to stop\033[0m"
  while true; do
    inotifywait -qqre modify,create,delete \
      --include '\.(c|cpp|h|hpp|py|sh)$' "$target"
    echo -e "\n\033[33m⟳ Change detected — testing…\033[0m"
    cmake --build "$build_dir" -j"$(nproc)" 2>&1 && \
      ctest --test-dir "$build_dir" --output-on-failure 2>&1
    echo -e "\033[32m✓ Tests finished\033[0m\n"
  done
}

# ── watch_run: re-execute any file via flower-run on change ──────────────
watch_run() {
  _fos_require_inotify || return 1
  local target="${1:?Usage: watch_run <file>}"
  [[ -f "$target" ]] || { echo -e "\033[31m✗ $target not found\033[0m"; return 1; }
  echo -e "\033[36m✿ Watching ${target} → frun\033[0m"
  echo -e "\033[38;5;245m  Ctrl-C to stop\033[0m"
  while true; do
    inotifywait -qqe modify "$target"
    echo -e "\n\033[33m⟳ Re-running…\033[0m"
    flower-run "$target" 2>&1 || true
    echo -e "\033[32m✓ Done\033[0m\n"
  done
}

# ═══════════════════════════════════════════════════════════════════════════
#  End lib/shell_extras.sh
# ═══════════════════════════════════════════════════════════════════════════
