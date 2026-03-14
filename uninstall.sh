#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS User-Mode Uninstaller
#  v1.3.0 — parasitic attach (user mode)
#
#  Shares marker definitions and bashrc removal with lib/install-core.sh.
# ═══════════════════════════════════════════════════════════════════════════

set -eu
set -o pipefail 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/install-core.sh"

readonly INSTALL_DIR="${HOME}/FlowerOS"
readonly BASHRC="${HOME}/.bashrc"

main() {
  info "Uninstalling FlowerOS (user mode)..."

  # 1. Remove sentinel block (and any legacy blocks) from ~/.bashrc
  if [[ -f "$BASHRC" ]]; then
    cp "$BASHRC" "${BASHRC}.backup.$(date +%s)" || die "Failed to backup bashrc"
    ok "Backed up ~/.bashrc"

    fos_remove_bashrc_block "$BASHRC"

    # Clean up stacked blank lines (keep max 2)
    awk 'NF {blank=0; print} !NF {blank++; if (blank <= 2) print}' \
      "$BASHRC" > "${BASHRC}.tmp"
    mv "${BASHRC}.tmp" "$BASHRC"
  else
    info "~/.bashrc not found (skipping)"
  fi

  # 2. Remove installation directory
  if [[ -d "$INSTALL_DIR" ]]; then
    read -r -p "Delete $INSTALL_DIR? [y/N] " response
    if [[ "${response,,}" == "y" ]]; then
      rm -rf "$INSTALL_DIR" || die "Failed to remove $INSTALL_DIR"
      ok "Removed $INSTALL_DIR"
    else
      info "Kept $INSTALL_DIR"
    fi
  else
    info "$INSTALL_DIR not found (skipping)"
  fi

  # 3. Remove state directory
  if [[ -d "${HOME}/.floweros" ]]; then
    rm -rf "${HOME}/.floweros" && ok "Removed ~/.floweros"
  fi

  echo ""
  info "Uninstallation complete.  Run: source ~/.bashrc"
  echo "  Or open a new terminal."
}

main "$@"
