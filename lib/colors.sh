#!/usr/bin/env bash
# lib/colors.sh - Shared color and output functions for FlowerOS
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

# Color codes
g="\033[32m"    # green
r="\033[31m"    # red
c="\033[36m"    # cyan
y="\033[33m"    # yellow
b="\033[34m"    # blue
m="\033[35m"    # magenta
z="\033[0m"     # reset

# Symbols
OK="✓"
NO="✗"
FLOWER="✿"
SPARK="❊"
WARN="⚠"

# Output functions
ok()   { printf "${g}${OK}${z} %s\n" "$*"; }
err()  { printf "${r}${NO}${z} %s\n" "$*" >&2; }
info() { printf "${c}${FLOWER}${z} %s\n" "$*"; }
warn() { printf "${y}${WARN}${z} %s\n" "$*"; }
die()  { err "$*"; exit 1; }

# GCC check function
check_gcc() {
    if ! command -v gcc >/dev/null 2>&1; then
        err "gcc not found!"
        echo ""
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt install build-essential"
        echo "  Fedora/RHEL:   sudo dnf install gcc"
        echo "  Arch:          sudo pacman -S gcc"
        echo ""
        return 1
    fi
    ok "Found gcc: $(gcc --version | head -n1)"
    return 0
}
