#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Theme Loader - Main Integration
#  Automatically loads theme system with self-initialization
#
#  This file is sourced by .flowerrc
# ═══════════════════════════════════════════════════════════════════════════

# Source theme initialization system
if [[ -f "${FLOWEROS_LIB:-/opt/floweros/lib}/theme_self_init.sh" ]]; then
    source "${FLOWEROS_LIB:-/opt/floweros/lib}/theme_self_init.sh"
else
    echo "⚠ FlowerOS: Theme system not found" >&2
fi

# Load active theme (with auto-recovery)
if [[ -f "${HOME}/.floweros/theme.conf" ]]; then
    source "${HOME}/.floweros/theme.conf"
    flower_theme_load "${FLOWEROS_THEME_ACTIVE:-garden}" >/dev/null 2>&1
else
    # Config missing - initialize
    flower_theme_self_init "false" "true" >/dev/null 2>&1
    flower_theme_load "garden" >/dev/null 2>&1
fi

# Export theme status
export FLOWEROS_THEME_INITIALIZED=1
