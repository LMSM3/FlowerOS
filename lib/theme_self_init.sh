#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Theme System - Self-Initialization
#  Botanical naming: "Garden Theme" - visual cultivation system
#
#  Handles first-time user initialization and missing data recovery
# ═══════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════
#  Theme Configuration Paths
# ═══════════════════════════════════════════════════════════════════════════

FLOWEROS_THEME_DIR="${FLOWEROS_ROOT:-/opt/floweros}/themes"
FLOWEROS_THEME_USER="${HOME}/.floweros/theme"
FLOWEROS_THEME_CONFIG="${HOME}/.floweros/theme.conf"
FLOWEROS_THEME_CACHE="${HOME}/.floweros/theme.cache"
FLOWEROS_FIRST_RUN_MARKER="${HOME}/.floweros/.first_run_complete"

# ═══════════════════════════════════════════════════════════════════════════
#  Theme Color Palettes (Botanical)
# ═══════════════════════════════════════════════════════════════════════════

# Palette 1: Garden Colors (default)
declare -A THEME_GARDEN=(
    [primary]="\033[32m"      # Green (leaves)
    [secondary]="\033[35m"    # Magenta (flowers)
    [accent]="\033[36m"       # Cyan (water)
    [warning]="\033[33m"      # Yellow (sun)
    [error]="\033[31m"        # Red (caution)
    [success]="\033[92m"      # Bright green (growth)
    [info]="\033[34m"         # Blue (sky)
    [muted]="\033[90m"        # Gray (stones)
    [reset]="\033[0m"         # Reset
)

# Palette 2: Spring Bloom
declare -A THEME_SPRING=(
    [primary]="\033[92m"      # Light green (new growth)
    [secondary]="\033[95m"    # Light magenta (cherry blossom)
    [accent]="\033[96m"       # Light cyan (spring water)
    [warning]="\033[93m"      # Light yellow (warm sun)
    [error]="\033[91m"        # Light red
    [success]="\033[32m"      # Green (established)
    [info]="\033[94m"         # Light blue (clear sky)
    [muted]="\033[37m"        # White (clouds)
    [reset]="\033[0m"
)

# Palette 3: Autumn Harvest
declare -A THEME_AUTUMN=(
    [primary]="\033[33m"      # Yellow (golden leaves)
    [secondary]="\033[31m"    # Red (maple leaves)
    [accent]="\033[35m"       # Magenta (late flowers)
    [warning]="\033[93m"      # Bright yellow (harvest)
    [error]="\033[91m"        # Bright red
    [success]="\033[32m"      # Green (evergreen)
    [info]="\033[34m"         # Blue (cool sky)
    [muted]="\033[90m"        # Gray (bare branches)
    [reset]="\033[0m"
)

# Palette 4: Night Garden
declare -A THEME_NIGHT=(
    [primary]="\033[34m"      # Blue (moonlight)
    [secondary]="\033[35m"    # Magenta (night flowers)
    [accent]="\033[36m"       # Cyan (dew)
    [warning]="\033[33m"      # Yellow (fireflies)
    [error]="\033[31m"        # Red (warning)
    [success]="\033[32m"      # Green (phosphorescence)
    [info]="\033[94m"         # Light blue (stars)
    [muted]="\033[90m"        # Dark gray (shadows)
    [reset]="\033[0m"
)

# ═══════════════════════════════════════════════════════════════════════════
#  First-Time User Detection
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_is_first_run() {
    # Check if this is the first time FlowerOS runs for this user
    [[ ! -f "${FLOWEROS_FIRST_RUN_MARKER}" ]]
}

flower_theme_mark_initialized() {
    # Mark that initialization is complete
    mkdir -p "$(dirname "${FLOWEROS_FIRST_RUN_MARKER}")"
    date +%s > "${FLOWEROS_FIRST_RUN_MARKER}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Theme Data Validation
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_validate_data() {
    local missing=0
    
    # Check theme directory
    if [[ ! -d "${FLOWEROS_THEME_DIR}" ]]; then
        echo "⚠ Theme directory missing: ${FLOWEROS_THEME_DIR}" >&2
        missing=1
    fi
    
    # Check user theme config
    if [[ ! -d "${HOME}/.floweros" ]]; then
        echo "⚠ User config directory missing: ${HOME}/.floweros" >&2
        missing=1
    fi
    
    # Check theme config file
    if [[ ! -f "${FLOWEROS_THEME_CONFIG}" ]]; then
        echo "⚠ Theme config missing: ${FLOWEROS_THEME_CONFIG}" >&2
        missing=1
    fi
    
    return $missing
}

# ═══════════════════════════════════════════════════════════════════════════
#  Theme Self-Initialization (Main Function)
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_self_init() {
    local force_reinit="${1:-false}"
    local quiet="${2:-false}"
    
    # Check if initialization needed
    if ! flower_theme_is_first_run && [[ "${force_reinit}" != "true" ]]; then
        # Already initialized - just validate
        if flower_theme_validate_data >/dev/null 2>&1; then
            return 0
        fi
        # Data missing - need to reinitialize
    fi
    
    [[ "${quiet}" != "true" ]] && echo "🌱 FlowerOS Theme: Initializing for first-time user..."
    
    # Create user directories
    mkdir -p "${HOME}/.floweros"
    mkdir -p "${FLOWEROS_THEME_USER}"
    
    # Generate default theme config
    flower_theme_generate_config
    
    # Install default theme
    flower_theme_install_default
    
    # Create cache
    flower_theme_rebuild_cache
    
    # Mark as initialized
    flower_theme_mark_initialized
    
    [[ "${quiet}" != "true" ]] && echo "✓ Theme initialization complete!"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  Generate Default Theme Configuration
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_generate_config() {
    cat > "${FLOWEROS_THEME_CONFIG}" << 'EOF'
# FlowerOS Theme Configuration
# Generated automatically on first run
# Edit this file to customize your theme

# Active theme (garden, spring, autumn, night)
FLOWEROS_THEME_ACTIVE="garden"

# Unicode symbols enabled (true/false)
FLOWEROS_THEME_UNICODE="true"

# Color palette (1=botanical, 2=flowers)
FLOWEROS_THEME_PALETTE="1"

# Theme features
FLOWEROS_THEME_COLORS="true"
FLOWEROS_THEME_GRADIENT="true"
FLOWEROS_THEME_ANIMATIONS="true"

# ASCII art preferences
FLOWEROS_THEME_ASCII_STYLE="pastel"  # pastel, bold, minimal
FLOWEROS_THEME_ASCII_WIDTH="120"     # characters

# Welcome message
FLOWEROS_THEME_WELCOME="true"
FLOWEROS_THEME_MOTD="true"

# Advanced
FLOWEROS_THEME_DEBUG="false"
FLOWEROS_THEME_CACHE_ENABLED="true"

# Custom colors (override defaults)
# Format: FLOWEROS_THEME_COLOR_<name>="<ansi_code>"
# Example: FLOWEROS_THEME_COLOR_primary="\033[32m"

# ═══════════════════════════════════════════════════════════════════════════
#  Do not edit below this line (auto-generated)
# ═══════════════════════════════════════════════════════════════════════════
FLOWEROS_THEME_VERSION="1.3.0"
FLOWEROS_THEME_INIT_DATE="$(date +%Y-%m-%d)"
FLOWEROS_THEME_INIT_USER="${USER}"
EOF
    
    chmod 644 "${FLOWEROS_THEME_CONFIG}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Install Default Theme Files
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_install_default() {
    # Copy default themes from system to user directory
    if [[ -d "${FLOWEROS_THEME_DIR}" ]]; then
        cp -r "${FLOWEROS_THEME_DIR}"/* "${FLOWEROS_THEME_USER}/" 2>/dev/null || true
    fi
    
    # Generate default theme data if system themes missing
    if [[ ! -f "${FLOWEROS_THEME_USER}/garden.theme" ]]; then
        flower_theme_generate_defaults
    fi
}

flower_theme_generate_defaults() {
    # Generate garden theme (default)
    cat > "${FLOWEROS_THEME_USER}/garden.theme" << 'EOF'
# FlowerOS Garden Theme (Default)
# Botanical colors inspired by nature

name="Garden"
description="Natural garden colors - green leaves, colorful flowers"
palette="1"

# Colors
color_primary="\033[32m"      # Green (leaves)
color_secondary="\033[35m"    # Magenta (flowers)
color_accent="\033[36m"       # Cyan (water)
color_warning="\033[33m"      # Yellow (sun)
color_error="\033[31m"        # Red (caution)
color_success="\033[92m"      # Bright green (growth)
color_info="\033[34m"         # Blue (sky)
color_muted="\033[90m"        # Gray (stones)
color_reset="\033[0m"

# Unicode symbols (palette 1)
symbol_seed="🌱"
symbol_leaf="🌿"
symbol_flower="✿"
symbol_bloom="🌸"
symbol_tree="🌳"
EOF

    # Generate spring theme
    cat > "${FLOWEROS_THEME_USER}/spring.theme" << 'EOF'
# FlowerOS Spring Theme
# Fresh growth and cherry blossoms

name="Spring Bloom"
description="Light, fresh colors of spring"
palette="1"

color_primary="\033[92m"      # Light green (new growth)
color_secondary="\033[95m"    # Light magenta (cherry blossom)
color_accent="\033[96m"       # Light cyan (spring water)
color_warning="\033[93m"      # Light yellow (warm sun)
color_error="\033[91m"        # Light red
color_success="\033[32m"      # Green
color_info="\033[94m"         # Light blue (clear sky)
color_muted="\033[37m"        # White (clouds)
color_reset="\033[0m"

symbol_seed="🌱"
symbol_leaf="🌿"
symbol_flower="🌸"
symbol_bloom="🌺"
symbol_tree="🌳"
EOF

    # Generate autumn theme
    cat > "${FLOWEROS_THEME_USER}/autumn.theme" << 'EOF'
# FlowerOS Autumn Theme
# Golden leaves and harvest colors

name="Autumn Harvest"
description="Warm colors of fall"
palette="1"

color_primary="\033[33m"      # Yellow (golden leaves)
color_secondary="\033[31m"    # Red (maple leaves)
color_accent="\033[35m"       # Magenta (late flowers)
color_warning="\033[93m"      # Bright yellow (harvest)
color_error="\033[91m"        # Bright red
color_success="\033[32m"      # Green (evergreen)
color_info="\033[34m"         # Blue (cool sky)
color_muted="\033[90m"        # Gray (bare branches)
color_reset="\033[0m"

symbol_seed="🍂"
symbol_leaf="🍁"
symbol_flower="🌾"
symbol_bloom="🍄"
symbol_tree="🎃"
EOF

    # Generate night theme
    cat > "${FLOWEROS_THEME_USER}/night.theme" << 'EOF'
# FlowerOS Night Garden Theme
# Moonlit garden with night flowers

name="Night Garden"
description="Cool colors of the night garden"
palette="1"

color_primary="\033[34m"      # Blue (moonlight)
color_secondary="\033[35m"    # Magenta (night flowers)
color_accent="\033[36m"       # Cyan (dew)
color_warning="\033[33m"      # Yellow (fireflies)
color_error="\033[31m"        # Red
color_success="\033[32m"      # Green (phosphorescence)
color_info="\033[94m"         # Light blue (stars)
color_muted="\033[90m"        # Dark gray (shadows)
color_reset="\033[0m"

symbol_seed="🌙"
symbol_leaf="⭐"
symbol_flower="✨"
symbol_bloom="🌟"
symbol_tree="🌌"
EOF
}

# ═══════════════════════════════════════════════════════════════════════════
#  Rebuild Theme Cache
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_rebuild_cache() {
    # Build cache of available themes for fast loading
    local cache_file="${FLOWEROS_THEME_CACHE}"
    
    {
        echo "# FlowerOS Theme Cache"
        echo "# Generated: $(date)"
        echo ""
        
        # List available themes
        if [[ -d "${FLOWEROS_THEME_USER}" ]]; then
            for theme in "${FLOWEROS_THEME_USER}"/*.theme; do
                [[ -f "$theme" ]] || continue
                local theme_name=$(basename "$theme" .theme)
                echo "theme_${theme_name}=\"${theme}\""
            done
        fi
    } > "${cache_file}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Theme Loading (with auto-recovery)
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_load() {
    local theme_name="${1:-garden}"
    
    # Check if initialized - auto-initialize if needed
    if ! flower_theme_validate_data >/dev/null 2>&1; then
        echo "🌱 Theme data missing - auto-initializing..." >&2
        flower_theme_self_init "false" "false"
    fi
    
    # Load theme config
    if [[ -f "${FLOWEROS_THEME_CONFIG}" ]]; then
        source "${FLOWEROS_THEME_CONFIG}"
    else
        echo "⚠ Theme config not found - using defaults" >&2
        return 1
    fi
    
    # Load requested theme
    local theme_file="${FLOWEROS_THEME_USER}/${theme_name}.theme"
    if [[ -f "${theme_file}" ]]; then
        source "${theme_file}"
        export FLOWEROS_THEME_LOADED="${theme_name}"
        return 0
    else
        echo "⚠ Theme '${theme_name}' not found - using garden" >&2
        source "${FLOWEROS_THEME_USER}/garden.theme"
        export FLOWEROS_THEME_LOADED="garden"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Theme Management Commands
# ═══════════════════════════════════════════════════════════════════════════

flower_theme_list() {
    echo "Available themes:"
    if [[ -d "${FLOWEROS_THEME_USER}" ]]; then
        for theme in "${FLOWEROS_THEME_USER}"/*.theme; do
            [[ -f "$theme" ]] || continue
            local name=$(basename "$theme" .theme)
            echo "  • ${name}"
        done
    else
        echo "  (none - run initialization)"
    fi
}

flower_theme_set() {
    local theme_name="$1"
    
    if [[ -z "${theme_name}" ]]; then
        echo "Usage: flower_theme_set <theme_name>"
        echo ""
        flower_theme_list
        return 1
    fi
    
    # Update config
    sed -i "s/^FLOWEROS_THEME_ACTIVE=.*/FLOWEROS_THEME_ACTIVE=\"${theme_name}\"/" "${FLOWEROS_THEME_CONFIG}"
    
    echo "✓ Theme set to: ${theme_name}"
    echo "  Reload shell to apply: source ~/.bashrc"
}

flower_theme_reset() {
    echo "🌱 Resetting theme to defaults..."
    flower_theme_self_init "true" "false"
    echo "✓ Theme reset complete"
}

flower_theme_info() {
    echo "FlowerOS Theme System"
    echo "════════════════════════════════════════"
    echo "Config:  ${FLOWEROS_THEME_CONFIG}"
    echo "Themes:  ${FLOWEROS_THEME_USER}"
    echo "Cache:   ${FLOWEROS_THEME_CACHE}"
    echo ""
    
    if [[ -f "${FLOWEROS_THEME_CONFIG}" ]]; then
        echo "Active theme: ${FLOWEROS_THEME_ACTIVE:-unknown}"
        echo "Unicode:      ${FLOWEROS_THEME_UNICODE:-unknown}"
        echo "Colors:       ${FLOWEROS_THEME_COLORS:-unknown}"
    else
        echo "Status: Not initialized"
        echo ""
        echo "Run: flower_theme_self_init"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Auto-Initialize on Load (Catch Missing Data)
# ═══════════════════════════════════════════════════════════════════════════

# This runs automatically when theme system is sourced
# Catches missing data and initializes silently
if ! flower_theme_validate_data >/dev/null 2>&1; then
    # Data missing - initialize quietly
    flower_theme_self_init "false" "true" >/dev/null 2>&1
fi

# ═══════════════════════════════════════════════════════════════════════════
#  Export Functions
# ═══════════════════════════════════════════════════════════════════════════

export -f flower_theme_self_init
export -f flower_theme_load
export -f flower_theme_list
export -f flower_theme_set
export -f flower_theme_reset
export -f flower_theme_info
export -f flower_theme_validate_data
export -f flower_theme_is_first_run
