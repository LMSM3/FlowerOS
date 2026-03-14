#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Emergency Removal Script  (system-level / permanent install)
#  v1.3.0 — parasitic attach (system mode)
#
#  Shares marker definitions and bashrc removal with lib/install-core.sh.
#
#  WARNING: This will remove all FlowerOS system components.
# ═══════════════════════════════════════════════════════════════════════════

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/install-core.sh"

check_root() {
  [[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)"
}

confirm_removal() {
  warn "This will REMOVE FlowerOS from your system."
  echo ""
  read -p "Are you absolutely sure? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || die "Removal cancelled"

  echo ""
  read -p "Type 'REMOVE FLOWEROS' to confirm: " confirm
  [[ "$confirm" == "REMOVE FLOWEROS" ]] || die "Confirmation failed.  Removal cancelled."
}

remove_immutable_flags() {
  info "Removing immutable flags..."
  if command -v chattr >/dev/null 2>&1; then
    chattr -i /etc/floweros/.flowerrc 2>/dev/null || true
    chattr -i /etc/floweros/VERSION   2>/dev/null || true
    ok "Removed immutable flags"
  fi
}

remove_from_system_bashrc() {
  info "Cleaning /etc/bash.bashrc..."
  if [[ -f /etc/bash.bashrc ]]; then
    cp /etc/bash.bashrc "/etc/bash.bashrc.backup-removal-$(date +%Y%m%d_%H%M%S)"
    fos_remove_bashrc_block /etc/bash.bashrc
  fi
}

remove_from_profile_d() {
  info "Removing /etc/profile.d/floweros.sh..."
  rm -f /etc/profile.d/floweros.sh
  ok "Removed /etc/profile.d/floweros.sh"
}

remove_user_integrations() {
  info "Removing per-user integrations..."

  local users
  users=($(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1":"$6}'))

  for user_info in "${users[@]}"; do
    IFS=':' read -r username homedir <<< "$user_info"

    if [[ -d "$homedir" ]]; then
      rm -f "$homedir/.flowerrc"

      if [[ -f "$homedir/.bashrc" ]]; then
        cp "$homedir/.bashrc" "$homedir/.bashrc.backup-floweros-removal" 2>/dev/null || true
        fos_remove_bashrc_block "$homedir/.bashrc"
        ok "Cleaned $username's configuration"
      fi
    fi
  done
}

remove_systemd_service() {
  info "Removing systemd service..."
  if command -v systemctl >/dev/null 2>&1; then
    systemctl stop floweros.service    2>/dev/null || true
    systemctl disable floweros.service 2>/dev/null || true
    rm -f /etc/systemd/system/floweros.service
    systemctl daemon-reload            2>/dev/null || true
    ok "Removed systemd service"
  fi
}

remove_system_files() {
  info "Removing system files..."
  rm -rf /opt/floweros  && ok "Removed /opt/floweros"
  rm -rf /etc/floweros  && ok "Removed /etc/floweros"
}

summary() {
  echo ""
  ok "FlowerOS has been removed from the system"
  echo ""
  echo "  Next steps:"
  echo "    1. source ~/.bashrc   (or open a new terminal)"
  echo ""
  echo "  Backups:"
  echo "    /etc/bash.bashrc.backup-removal-*"
  echo "    ~/.bashrc.backup-floweros-removal  (per user)"
  echo ""
}

main() {
  echo ""
  echo "==============================================================================="
  echo "  FlowerOS Emergency Removal"
  echo "==============================================================================="

  check_root
  confirm_removal
  remove_immutable_flags
  remove_from_system_bashrc
  remove_from_profile_d
  remove_user_integrations
  remove_systemd_service
  remove_system_files
  summary
}

main "$@"
