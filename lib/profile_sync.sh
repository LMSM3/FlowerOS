#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Profile Sync — Bash Side              (lib/profile_sync.sh)
#
#  Sources the active FlowerOS theme, exports color variables through
#  WSLENV so PowerShell inherits the same palette, detects the Linux
#  distro, and initialises Oh My Posh with the shared OMP template.
#
#  Source from ~/.bashrc (or ~/.zshrc):
#
#    export FLOWEROS_ROOT="/path/to/FlowerOS"
#    [ -f "$FLOWEROS_ROOT/lib/profile_sync.sh" ] && \
#        source "$FLOWEROS_ROOT/lib/profile_sync.sh"
#
#  Part of FlowerOS v1.3.0 — Core Architecture.
# ═══════════════════════════════════════════════════════════════════════════

# ── Guard: only source once per session ──────────────────────────────────
[[ -n "${_FLOWEROS_PROFILE_SYNCED:-}" ]] && return 0
export _FLOWEROS_PROFILE_SYNCED=1

# ── Resolve root ─────────────────────────────────────────────────────────
_FPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${FLOWEROS_ROOT:=$(cd "$_FPS_DIR/.." 2>/dev/null && pwd)}"
export FLOWEROS_ROOT
export FLOWEROS_LIB="${FLOWEROS_ROOT}/lib"

# ═══════════════════════════════════════════════════════════════════════════
#  1. Distro Detection
# ═══════════════════════════════════════════════════════════════════════════

_fos_detect_distro() {
    local id=""
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        id="${ID:-unknown}"
    fi
    export FLOWEROS_DISTRO="${id}"

    case "${id}" in
        ubuntu)
            export FLOWEROS_PKG_MGR="sudo apt"
            export FLOWEROS_PREFER_FLATPAK="false"
            ;;
        pop)
            export FLOWEROS_PKG_MGR="sudo apt"
            export FLOWEROS_PREFER_FLATPAK="true"
            ;;
        debian)
            if command -v sudo >/dev/null 2>&1; then
                export FLOWEROS_PKG_MGR="sudo apt"
            else
                export FLOWEROS_PKG_MGR="su -c 'apt install'"
            fi
            export FLOWEROS_PREFER_FLATPAK="false"
            ;;
        fedora|rhel|centos|rocky|alma)
            export FLOWEROS_PKG_MGR="sudo dnf"
            export FLOWEROS_PREFER_FLATPAK="false"
            ;;
        arch|manjaro|endeavouros)
            export FLOWEROS_PKG_MGR="sudo pacman -S"
            export FLOWEROS_PREFER_FLATPAK="false"
            ;;
        *)
            export FLOWEROS_PKG_MGR=""
            export FLOWEROS_PREFER_FLATPAK="false"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  2. Theme Colour Maps (ANSI → hex for OMP / Windows Terminal)
#
#     Each FlowerOS theme stores ANSI escape codes (e.g. \033[32m).
#     Oh My Posh and Windows Terminal need hex (#rrggbb).  This table
#     maps the base-16 codes we actually use.
# ═══════════════════════════════════════════════════════════════════════════

declare -A _ANSI_TO_HEX=(
    # Standard (30–37)
    ["31"]="#cc4444"   ["32"]="#5faf5f"   ["33"]="#afaf00"
    ["34"]="#5f87df"   ["35"]="#af5faf"   ["36"]="#5fafaf"
    ["37"]="#c0c0c0"   ["90"]="#808080"
    # Bright (91–97)
    ["91"]="#ff5555"   ["92"]="#5fdf5f"   ["93"]="#ffff55"
    ["94"]="#7fafff"   ["95"]="#ff7fff"   ["96"]="#5fdfdf"
    ["97"]="#ffffff"
)

# Extract the ANSI code number from an escape string like \033[32m → 32
_fos_ansi_code() {
    local raw="$1"
    # handles \033[XXm  \e[XXm  \x1b[XXm
    echo "$raw" | sed -E 's/.*\[([0-9]+)m.*/\1/'
}

_fos_ansi_to_hex() {
    local code
    code=$(_fos_ansi_code "$1")
    echo "${_ANSI_TO_HEX[$code]:-#808080}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  3. Load Active Theme + Export Colours
# ═══════════════════════════════════════════════════════════════════════════

_fos_sync_theme() {
    # --- 3a. Source the theme system (creates palettes + loads .theme) ---
    local theme_init="${FLOWEROS_LIB}/theme_self_init.sh"
    if [[ -f "$theme_init" ]]; then
        # shellcheck source=theme_self_init.sh
        source "$theme_init"
    fi

    local theme_loader="${FLOWEROS_LIB}/theme_loader.sh"
    if [[ -f "$theme_loader" ]]; then
        # shellcheck source=theme_loader.sh
        source "$theme_loader"
    fi

    # After sourcing, the active .theme file has set these shell vars:
    #   color_primary  color_secondary  color_accent  color_warning
    #   color_error    color_success    color_info    color_muted
    #   color_reset

    # --- 3b. Export as FLOWEROS_CLR_* (what banners.sh already reads) ---
    export FLOWEROS_CLR_RED="${color_error:-\033[31m}"
    export FLOWEROS_CLR_GREEN="${color_primary:-\033[32m}"
    export FLOWEROS_CLR_YELLOW="${color_warning:-\033[33m}"
    export FLOWEROS_CLR_BLUE="${color_info:-\033[34m}"
    export FLOWEROS_CLR_MAGENTA="${color_secondary:-\033[35m}"
    export FLOWEROS_CLR_CYAN="${color_accent:-\033[36m}"
    export FLOWEROS_CLR_DIM="${color_muted:-\033[90m}"
    export FLOWEROS_CLR_RESET="${color_reset:-\033[0m}"

    # --- 3c. Export hex versions for OMP palette ---
    export FLOWEROS_OMP_PRIMARY="$(_fos_ansi_to_hex   "${color_primary:-\033[32m}")"
    export FLOWEROS_OMP_SECONDARY="$(_fos_ansi_to_hex "${color_secondary:-\033[35m}")"
    export FLOWEROS_OMP_ACCENT="$(_fos_ansi_to_hex    "${color_accent:-\033[36m}")"
    export FLOWEROS_OMP_WARNING="$(_fos_ansi_to_hex   "${color_warning:-\033[33m}")"
    export FLOWEROS_OMP_ERROR="$(_fos_ansi_to_hex     "${color_error:-\033[31m}")"
    export FLOWEROS_OMP_SUCCESS="$(_fos_ansi_to_hex   "${color_success:-\033[92m}")"
    export FLOWEROS_OMP_INFO="$(_fos_ansi_to_hex      "${color_info:-\033[34m}")"
    export FLOWEROS_OMP_MUTED="$(_fos_ansi_to_hex     "${color_muted:-\033[90m}")"

    # Background / foreground for the OMP template (theme-independent defaults)
    export FLOWEROS_OMP_BG="#1e1e2e"
    export FLOWEROS_OMP_FG="#cdd6f4"

    # Theme variant (light/dark hint for PowerShell side)
    export FLOWEROS_THEME_VARIANT="${FLOWEROS_THEME_VARIANT:-dark}"

    # --- 3d. Push everything through WSLENV ---
    #   /u = make available to Win32 processes spawned from this shell
    local _wslvars=""
    _wslvars+="FLOWEROS_CLR_RED/u:"
    _wslvars+="FLOWEROS_CLR_GREEN/u:"
    _wslvars+="FLOWEROS_CLR_YELLOW/u:"
    _wslvars+="FLOWEROS_CLR_BLUE/u:"
    _wslvars+="FLOWEROS_CLR_MAGENTA/u:"
    _wslvars+="FLOWEROS_CLR_CYAN/u:"
    _wslvars+="FLOWEROS_CLR_DIM/u:"
    _wslvars+="FLOWEROS_CLR_RESET/u:"
    _wslvars+="FLOWEROS_OMP_PRIMARY/u:"
    _wslvars+="FLOWEROS_OMP_SECONDARY/u:"
    _wslvars+="FLOWEROS_OMP_ACCENT/u:"
    _wslvars+="FLOWEROS_OMP_WARNING/u:"
    _wslvars+="FLOWEROS_OMP_ERROR/u:"
    _wslvars+="FLOWEROS_OMP_SUCCESS/u:"
    _wslvars+="FLOWEROS_OMP_INFO/u:"
    _wslvars+="FLOWEROS_OMP_MUTED/u:"
    _wslvars+="FLOWEROS_OMP_BG/u:"
    _wslvars+="FLOWEROS_OMP_FG/u:"
    _wslvars+="FLOWEROS_THEME_VARIANT/u:"
    _wslvars+="FLOWEROS_THEME_LOADED/u:"
    _wslvars+="FLOWEROS_DISTRO/u"

    # Append to existing WSLENV (don't clobber other entries)
    if [[ -n "${WSLENV:-}" ]]; then
        export WSLENV="${WSLENV}:${_wslvars}"
    else
        export WSLENV="${_wslvars}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  4. Write sync manifest (consumed by PowerShell side)
#
#     Writes a small key=value file that the PS1 module reads so it
#     doesn't depend on WSLENV alone (which only works for processes
#     launched from WSL → Windows).
# ═══════════════════════════════════════════════════════════════════════════

_fos_write_sync_manifest() {
    # Write to ~/.floweros/ (legacy location)
    local manifest="${HOME}/.floweros/theme_sync.env"
    mkdir -p "$(dirname "$manifest")"
    cat > "$manifest" <<EOF
# FlowerOS Theme Sync Manifest — auto-generated by profile_sync.sh
# $(date)
FLOWEROS_THEME_LOADED="${FLOWEROS_THEME_LOADED:-garden}"
FLOWEROS_THEME_VARIANT="${FLOWEROS_THEME_VARIANT:-dark}"
FLOWEROS_DISTRO="${FLOWEROS_DISTRO:-unknown}"
FLOWEROS_OMP_PRIMARY="${FLOWEROS_OMP_PRIMARY}"
FLOWEROS_OMP_SECONDARY="${FLOWEROS_OMP_SECONDARY}"
FLOWEROS_OMP_ACCENT="${FLOWEROS_OMP_ACCENT}"
FLOWEROS_OMP_WARNING="${FLOWEROS_OMP_WARNING}"
FLOWEROS_OMP_ERROR="${FLOWEROS_OMP_ERROR}"
FLOWEROS_OMP_SUCCESS="${FLOWEROS_OMP_SUCCESS}"
FLOWEROS_OMP_INFO="${FLOWEROS_OMP_INFO}"
FLOWEROS_OMP_MUTED="${FLOWEROS_OMP_MUTED}"
FLOWEROS_OMP_BG="${FLOWEROS_OMP_BG}"
FLOWEROS_OMP_FG="${FLOWEROS_OMP_FG}"
EOF

    # Write to ~/.config/flower/ (Pollen 0.4.0 canonical location)
    local pollen_dir="${HOME}/.config/flower"
    mkdir -p "$pollen_dir"
    cp "$manifest" "$pollen_dir/theme.env" 2>/dev/null || true

    # Copy OMP theme into Pollen config dir
    local omp_master="${FLOWEROS_LIB}/floweros.omp.json"
    if [[ -f "$omp_master" ]]; then
        cp "$omp_master" "$pollen_dir/theme.omp.json" 2>/dev/null || true
        # Legacy location for direct OMP init
        cp "$omp_master" "$HOME/.mytheme.omp.json" 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  5. Oh My Posh Initialisation
# ═══════════════════════════════════════════════════════════════════════════

_fos_init_omp() {
    # Prefer the FlowerOS shared theme; fall back to user's own config
    local omp_config="${FLOWEROS_LIB}/floweros.omp.json"

    # If the theme file is on a Windows mount, translate path
    if [[ "$omp_config" == /mnt/* ]]; then
        : # already a WSL path — fine
    fi

    if ! command -v oh-my-posh >/dev/null 2>&1; then
        # OMP not installed — skip silently (not a hard dependency)
        return 0
    fi

    if [[ ! -f "$omp_config" ]]; then
        # No FlowerOS theme — let OMP use its default or user config
        return 0
    fi

    # Ensure 256-color (important for SSH / RHEL / older terms)
    export TERM="${TERM:-xterm-256color}"

    # Determine shell (bash vs zsh)
    local shell_name
    shell_name="$(basename "${SHELL:-bash}")"

    eval "$(oh-my-posh init "$shell_name" --config "$omp_config")"
}

# ═══════════════════════════════════════════════════════════════════════════
#  6. Install helper — idempotent OMP binary install
# ═══════════════════════════════════════════════════════════════════════════

flower_install_omp() {
    if command -v oh-my-posh >/dev/null 2>&1; then
        echo "✓ oh-my-posh already installed: $(oh-my-posh --version)"
        return 0
    fi

    echo "🌱 Installing Oh My Posh..."

    # Distro-aware install
    if [[ -z "${FLOWEROS_DISTRO:-}" ]]; then
        _fos_detect_distro
    fi

    case "${FLOWEROS_DISTRO}" in
        ubuntu|pop|debian)
            echo "  Detected: ${FLOWEROS_DISTRO} (Debian family)"
            ;;
        fedora|rhel|centos|rocky|alma)
            echo "  Detected: ${FLOWEROS_DISTRO} (RHEL family)"
            ;;
        arch|manjaro|endeavouros)
            echo "  Detected: ${FLOWEROS_DISTRO} (Arch family)"
            ;;
        *)
            echo "  Detected: ${FLOWEROS_DISTRO:-unknown}"
            ;;
    esac

    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    export PATH="${HOME}/.local/bin:${PATH}"

    if command -v oh-my-posh >/dev/null 2>&1; then
        echo "✓ oh-my-posh installed: $(oh-my-posh --version)"
    else
        echo "⚠ Installation finished but oh-my-posh not found in PATH"
        echo "  Ensure ~/.local/bin is in your PATH"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  7. flower-theme (bash command to change theme and re-sync)
# ═══════════════════════════════════════════════════════════════════════════

flower_profile_apply() {
    local theme="${1:-}"
    if [[ -z "$theme" ]]; then
        echo "Usage: flower_profile_apply <garden|spring|autumn|night>"
        echo ""
        echo "Current: ${FLOWEROS_THEME_LOADED:-none}"
        return 1
    fi

    # Change the active theme via the existing theme system
    if declare -f flower_theme_set >/dev/null 2>&1; then
        flower_theme_set "$theme"
    else
        echo "⚠ flower_theme_set not available — loading theme directly"
    fi

    # Reload theme into current session
    if declare -f flower_theme_load >/dev/null 2>&1; then
        flower_theme_load "$theme"
    fi

    # Re-run the sync pipeline
    _fos_sync_theme
    _fos_write_sync_manifest
    _fos_init_omp

    echo "✓ Profile sync applied: theme=${theme}"
    echo "  PowerShell side will pick up changes via WSLENV / manifest"
}
export -f flower_profile_apply

# ═══════════════════════════════════════════════════════════════════════════
#  Entry — run everything on source
# ═══════════════════════════════════════════════════════════════════════════

_fos_detect_distro
_fos_sync_theme
_fos_write_sync_manifest
_fos_init_omp
