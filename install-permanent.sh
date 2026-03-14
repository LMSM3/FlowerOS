#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Permanent System-Level Installation
#  v1.3.0 — parasitic attach (system mode)
#
#  Shares build logic and markers with install.sh via lib/install-core.sh.
#  Do not duplicate install logic here.
#
#  Installs FlowerOS to /opt/floweros and grafts it into /etc/bash.bashrc
#  and /etc/profile.d/.  Requires root.
# ═══════════════════════════════════════════════════════════════════════════

set -eu
set -o pipefail 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/install-core.sh"

# ── Additional output helpers (permanent install needs header/warn/banner) ──
readonly _PI_MAG='\033[35m'
readonly _PI_BOLD='\033[1m'
readonly _PI_RST='\033[0m'
_header() { printf "\n${_PI_MAG}${_PI_BOLD}%s${_PI_RST}\n\n" "$*"; }

# System paths
readonly FLOWEROS_ROOT_DIR="/opt/floweros"
readonly FLOWEROS_BIN_DIR="${FLOWEROS_ROOT_DIR}/bin"
readonly FLOWEROS_LIB_DIR="${FLOWEROS_ROOT_DIR}/lib"
readonly FLOWEROS_ASCII_DIR="${FLOWEROS_ROOT_DIR}/ascii"
readonly FLOWEROS_DATA_DIR="${FLOWEROS_ROOT_DIR}/data"
readonly FLOWEROS_CONFIG_DIR="/etc/floweros"
readonly SYSTEM_BASHRC="/etc/bash.bashrc"
readonly PROFILE_D="/etc/profile.d"

# Shared state (set by backup_system_files, read by summary)
_FOS_BACKUP_DIR=""

check_root() {
  [[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)"
}

banner() {
  echo ""
  printf "${_PI_MAG}${_PI_BOLD}%s${_PI_RST}\n" \
    "═══════════════════════════════════════════════════════════════════════════" \
    "  FlowerOS v1.3.0 — Permanent System Installation" \
    "═══════════════════════════════════════════════════════════════════════════"
  echo ""
}

confirm_installation() {
  warn "This will install FlowerOS as a PERMANENT system component:"
  echo "  - Installs to /opt/floweros (system-level)"
  echo "  - Integrates with /etc/bash.bashrc (all users)"
  echo "  - Creates /etc/profile.d/floweros.sh (auto-load)"
  echo "  - Marks as native distro package"
  echo "  - Cannot be easily uninstalled"
  echo ""
  read -p "Continue? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
}

backup_system_files() {
  _header "Creating System Backups"

  local backup_dir="/root/floweros-backup-$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$backup_dir"

  [[ -f "$SYSTEM_BASHRC" ]] && cp "$SYSTEM_BASHRC" "$backup_dir/" && ok "Backed up: $SYSTEM_BASHRC"
  [[ -f "/etc/profile" ]] && cp "/etc/profile" "$backup_dir/" && ok "Backed up: /etc/profile"

  _FOS_BACKUP_DIR="$backup_dir"
  ok "Backup location: $backup_dir"
}

build_binaries() {
  _header "Building FlowerOS Binaries"

  # Core binaries (shared logic from install-core.sh)
  fos_build_core "-pedantic"

  # Build src/ C twins via master Makefile (Tier 5 production binaries)
  if [[ -d "src" ]] && [[ -f "src/Makefile" ]]; then
    [[ -n "${FOS_FEATURES+x}" ]] || fos_detect_features
    info "Building Tier 5 C binaries (src/Makefile)..."
    make -C src CC=gcc CFLAGS="-O2 -std=c11 -Wall -Wextra -pedantic $FOS_FEATURES -Isrc" \
      flower-guy flower-walk fp 2>&1 | grep -E '(built|error|warning)' || true
    for b in flower-guy flower-walk fp; do
      [[ -f "src/$b" ]] && ok "Built: $b" || warn "Optional binary not built: $b"
    done
  fi

  # Build visual if available
  if [[ -f "lib/visual.c" ]]; then
    info "Compiling visual.c..."
    gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c \
      || warn "Visual compilation failed (optional)"
    [[ -f "visual" ]] && ok "Built: visual"
  fi
}

install_to_system() {
  _header "Installing to System Directories"

  # Create directory structure
  info "Creating system directories..."
  mkdir -p "$FLOWEROS_ROOT_DIR" "$FLOWEROS_BIN_DIR" "$FLOWEROS_LIB_DIR" \
           "$FLOWEROS_ASCII_DIR" "$FLOWEROS_DATA_DIR" "$FLOWEROS_CONFIG_DIR"
  ok "Created: $FLOWEROS_ROOT_DIR"

  # Core + extended binaries (shared logic from install-core.sh)
  fos_install_core_bins "$FLOWEROS_BIN_DIR"
  fos_install_extended_bins "$FLOWEROS_BIN_DIR"

  # Shell fallback for walk demo
  install -m 755 experimental/animations/flower_walk_demo.sh \
    "$FLOWEROS_BIN_DIR/flower-walk-sh" 2>/dev/null && \
    ok "Installed: flower-walk-sh (shell fallback)" || true

  # Assets
  fos_copy_assets "$FLOWEROS_ASCII_DIR"

  # Libraries
  fos_copy_libs "$FLOWEROS_LIB_DIR"

  # Features
  if [[ -d "features" ]]; then
    cp -r features "$FLOWEROS_ROOT_DIR/" 2>/dev/null || true
    ok "Installed features"
  fi

  # MOTD data
  if [[ -d "motd" ]]; then
    cp -r motd "$FLOWEROS_DATA_DIR/" 2>/dev/null || true
    ok "Installed motd"
  fi

  # Permissions
  chmod -R 755 "$FLOWEROS_BIN_DIR"
  chmod -R 755 "$FLOWEROS_LIB_DIR"
  chmod -R 644 "$FLOWEROS_ASCII_DIR"/* 2>/dev/null || true
  chmod -R 644 "$FLOWEROS_DATA_DIR"/* 2>/dev/null || true
  ok "Set system permissions"
}

install_flowerrc() {
  _header "Installing .flowerrc System Configuration"

  if [[ -f ".flowerrc" ]]; then
    install -m 644 .flowerrc "$FLOWEROS_CONFIG_DIR/.flowerrc"
    ok "Installed: $FLOWEROS_CONFIG_DIR/.flowerrc"
  else
    die ".flowerrc not found in current directory"
  fi

  fos_write_version "$FLOWEROS_CONFIG_DIR/VERSION" "PERMANENT_ROOT"
}

# Content emitted inside the sentinel block for /etc/bash.bashrc
_permanent_bashrc_block() {
  cat <<'BLOCK'
# FlowerOS Native System Integration (Permanent)
# WARNING: This is a system-level component.  Do not remove.
[[ -f /etc/floweros/.flowerrc ]] && source /etc/floweros/.flowerrc
BLOCK
}

integrate_system_bashrc() {
  _header "Integrating with System Shell Configuration"

  if [[ -f "$SYSTEM_BASHRC" ]]; then
    fos_inject_bashrc "$SYSTEM_BASHRC" _permanent_bashrc_block 11
    chmod 644 "$SYSTEM_BASHRC"
  else
    warn "$SYSTEM_BASHRC not found, skipping"
  fi
}

create_profile_d_integration() {
  _header "Creating Profile.d Integration"

  if [[ -d "$PROFILE_D" ]]; then
    cat > "$PROFILE_D/floweros.sh" <<'EOF'
#!/bin/bash
# FlowerOS System Integration
# Auto-sourced for all login shells
[[ -f /etc/floweros/.flowerrc ]] && source /etc/floweros/.flowerrc
EOF
    chmod 755 "$PROFILE_D/floweros.sh"
    ok "Created: $PROFILE_D/floweros.sh"
  else
    warn "$PROFILE_D not found, skipping"
  fi
}

# Content emitted inside the sentinel block for per-user ~/.bashrc
_user_bashrc_block() {
  cat <<'BLOCK'
# FlowerOS Integration (System-Level)
[[ -f ~/.flowerrc ]] && source ~/.flowerrc
BLOCK
}

create_user_symlinks() {
  _header "Creating User Symlinks"

  local users
  users=($(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1":"$6}'))

  for user_info in "${users[@]}"; do
    IFS=':' read -r username homedir <<< "$user_info"

    if [[ -d "$homedir" ]] && [[ -n "$username" ]]; then
      info "Setting up for user: $username"

      # Symlink .flowerrc into home
      ln -sf "$FLOWEROS_CONFIG_DIR/.flowerrc" "$homedir/.flowerrc" 2>/dev/null || true
      chown -h "$username:$username" "$homedir/.flowerrc" 2>/dev/null || true

      # Inject sentinel block into user bashrc
      local user_bashrc="$homedir/.bashrc"
      if [[ -f "$user_bashrc" ]]; then
        fos_inject_bashrc "$user_bashrc" _user_bashrc_block 11
        chown "$username:$username" "$user_bashrc"
        chmod 644 "$user_bashrc"
      fi
    fi
  done
}

mark_as_system_package() {
  _header "Marking as System Package"

  # dpkg status entry (Debian/Ubuntu)
  if command -v dpkg >/dev/null 2>&1; then
    info "Creating package marker..."
    mkdir -p "$FLOWEROS_CONFIG_DIR/package"
    cat > "$FLOWEROS_CONFIG_DIR/package/status" <<EOF
Package: floweros
Status: install ok installed
Priority: optional
Section: utils
Installed-Size: $(du -sk "$FLOWEROS_ROOT_DIR" | cut -f1)
Maintainer: FlowerOS System <system@floweros>
Architecture: $(dpkg --print-architecture 2>/dev/null || echo "amd64")
Version: 1.3.0
Description: FlowerOS Native System Integration
 Permanent terminal enhancement system integrated at the distribution level.
Homepage: https://github.com/floweros
EOF
    ok "Marked as system package"
  fi

  # systemd marker (optional)
  if command -v systemctl >/dev/null 2>&1; then
    cat > "/etc/systemd/system/floweros.service" <<EOF
[Unit]
Description=FlowerOS Native System Integration
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable floweros.service 2>/dev/null || true
    ok "Created systemd service marker"
  fi
}

create_uninstall_protection() {
  _header "Creating Uninstall Protection"

  # Make files immutable (requires chattr)
  if command -v chattr >/dev/null 2>&1; then
    info "Setting immutable flags..."
    chattr +i "$FLOWEROS_CONFIG_DIR/.flowerrc" 2>/dev/null \
      || warn "Could not set immutable flag (optional)"
    chattr +i "$FLOWEROS_CONFIG_DIR/VERSION" 2>/dev/null || true
  fi

  # Removal reference doc
  cat > "$FLOWEROS_ROOT_DIR/REMOVAL_WARNING.txt" <<'EOF'
===============================================================================
  WARNING: FlowerOS is a PERMANENT system integration
===============================================================================

FlowerOS has been installed as a native system component at the root level.
It is designed to be permanent.  The recommended removal tool is:

   sudo bash remove-permanent.sh

Manual steps if the script is unavailable:

  1.  sudo chattr -i /etc/floweros/.flowerrc /etc/floweros/VERSION 2>/dev/null
  2.  Remove sentinel block from /etc/bash.bashrc:
        sudo sed -i '/^# BEGIN FlowerOS$/,/^# END FlowerOS$/d' /etc/bash.bashrc
  3.  sudo rm -f /etc/profile.d/floweros.sh
  4.  For each user: remove sentinel block from ~/.bashrc (same sed pattern)
      rm -f ~/.flowerrc
  5.  sudo rm -rf /opt/floweros /etc/floweros
  6.  sudo systemctl disable floweros.service 2>/dev/null; \
      sudo rm -f /etc/systemd/system/floweros.service
  7.  source ~/.bashrc

===============================================================================
EOF
  ok "Created removal warning"
}

summary() {
  _header "Installation Complete"

  ok "FlowerOS v1.3.0 has been permanently installed"
  echo ""
  echo "  Root directory : $FLOWEROS_ROOT_DIR"
  echo "  Configuration  : $FLOWEROS_CONFIG_DIR"
  echo "  System bashrc  : $SYSTEM_BASHRC (sentinel block)"
  echo "  Profile.d      : $PROFILE_D/floweros.sh"
  echo "  Status         : NATIVE SYSTEM INTEGRATION"
  echo ""

  local backup_loc="${_FOS_BACKUP_DIR:-}"
  [[ -n "$backup_loc" ]] && info "Backup location: $backup_loc"
  echo ""

  warn "To activate: source ~/.bashrc  (or open a new terminal)"
  echo ""

  printf "${_PI_MAG}%s${_PI_RST}\n" \
    "===============================================================================" \
    "  Every terminal session is a garden." \
    "==============================================================================="
  echo ""

  # Post-install setup
  if [[ -f "lib/post-install.sh" ]]; then
    echo ""
    read -p "Run post-install setup for optional tools? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      source "lib/post-install.sh"
      run_post_install "permanent"
    else
      info "Skipped post-install. Run later: bash lib/post-install.sh permanent"
    fi
  fi
}

main() {
  banner
  check_root
  confirm_installation
  backup_system_files
  build_binaries
  install_to_system
  install_flowerrc
  integrate_system_bashrc
  create_profile_d_integration
  create_user_symlinks
  mark_as_system_package
  create_uninstall_protection
  summary
}

main "$@"
