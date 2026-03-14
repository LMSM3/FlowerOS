#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS User-Mode Installer
#  Parasitic attach: graft FlowerOS into ~/FlowerOS + ~/.bashrc
#
#  Shares build logic and markers with install-permanent.sh via
#  lib/install-core.sh.  Do not duplicate install logic here.
# ═══════════════════════════════════════════════════════════════════════════
set -eu
set -o pipefail 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/install-core.sh"

readonly INSTALL_DIR="${HOME}/FlowerOS"
readonly ASCII_DIR="${INSTALL_DIR}/ascii"
readonly BIN_DIR="${INSTALL_DIR}/bin"
readonly LIB_DIR="${INSTALL_DIR}/lib"
readonly BASHRC="${HOME}/.bashrc"
readonly CONFIG_DIR="${HOME}/.floweros"

# ── Bashrc block content (user mode) ────────────────────────────────────
# Sets FLOWEROS_ROOT before sourcing .flowerrc so all paths resolve to
# ~/FlowerOS instead of the permanent-install default (/opt/floweros).
_user_bashrc_block() {
  cat <<'BLOCK'
export FLOWEROS_ROOT="${HOME}/FlowerOS"
export FLOWEROS_BIN="${FLOWEROS_ROOT}/bin"
export FLOWEROS_LIB="${FLOWEROS_ROOT}/lib"
export FLOWEROS_ASCII="${FLOWEROS_ROOT}/ascii"
export FLOWEROS_DATA="${FLOWEROS_ROOT}/data"
export FLOWEROS_CONFIG="${HOME}/.floweros"
export FLOWEROS_BUILD_TYPE="USER"
[[ -f "${FLOWEROS_ROOT}/.flowerrc" ]] && source "${FLOWEROS_ROOT}/.flowerrc"
BLOCK
}

# ── Post-install prompt helper ───────────────────────────────────────────
_ask_yes_no() {
  local prompt="$1" response
  printf "\033[33m%s [y/N]\033[0m " "$prompt"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

# ═══════════════════════════════════════════════════════════════════════════

main() {
  info "Installing FlowerOS (user mode)..."

  # 1. Directory structure
  mkdir -p "$ASCII_DIR" "$BIN_DIR" "$LIB_DIR" "$CONFIG_DIR" \
    || die "Failed to create install directories"
  ok "Directories: $INSTALL_DIR"

  # 2. Core binaries  (shared logic from install-core.sh)
  fos_install_core_bins "$BIN_DIR"

  # 3. Extended binaries (if pre-built by build.sh)
  fos_install_extended_bins "$BIN_DIR"

  # 4. Asset files
  fos_copy_assets "$ASCII_DIR"

  # 5. Library files
  fos_copy_libs "$LIB_DIR"

  # 6. Copy .flowerrc into install dir
  if [[ -f ".flowerrc" ]]; then
    cp ".flowerrc" "$INSTALL_DIR/.flowerrc"
    ok "Installed .flowerrc"
  fi

  # 7. Install flower entry-point command
  if [[ -f "bin/flower" ]]; then
    install -m 755 "bin/flower" "$BIN_DIR/flower"
    ok "Installed: flower (entry point)"
  fi

  # 8. Version file
  fos_write_version "$CONFIG_DIR/VERSION" "user"

  # 9. Network binaries (optional, experimental)
  if [[ -d "network/build" ]]; then
    local net_dir="${INSTALL_DIR}/network"
    mkdir -p "$net_dir"
    local net_copied=0
    for net_bin in node_monitor node_discovery terminal_node; do
      [[ -x "network/build/$net_bin" ]] && {
        cp "network/build/$net_bin" "$net_dir/" && net_copied=$((net_copied + 1))
      }
    done
    (( net_copied > 0 )) && ok "Copied $net_copied network binaries (experimental)"
    [[ -f "lib/terminal_network.sh" ]] && {
      cp "lib/terminal_network.sh" "$LIB_DIR/" && ok "Copied terminal_network.sh"
    }
  fi

  # 10. Bashrc integration  (shared sentinel from install-core.sh)
  fos_inject_bashrc "$BASHRC" _user_bashrc_block

  echo ""
  info "Installation complete.  Run: source ~/.bashrc"
  echo "  Or open a new terminal."
  echo ""

  # 10. Optional post-install
  if [[ -f "lib/post-install.sh" ]]; then
    if _ask_yes_no "Run post-install setup for optional tools?"; then
      source "lib/post-install.sh"
      run_post_install "user"
    else
      info "Skipped post-install.  Run later: bash lib/post-install.sh"
    fi
  fi
}

main "$@"
