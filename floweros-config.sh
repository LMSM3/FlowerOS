#!/usr/bin/env bash
# FlowerOS User Preferences System
# Saves account-specific preferences for themes, MOTD, etc.

set -e

# Config location
FLOWEROS_CONFIG="$HOME/.floweros/config"
FLOWEROS_PREFS="$HOME/.floweros/preferences.conf"

# Initialize config directory
init_config() {
    mkdir -p "$HOME/.floweros"
    
    if [[ ! -f "$FLOWEROS_PREFS" ]]; then
        cat > "$FLOWEROS_PREFS" <<'EOF'
# FlowerOS User Preferences
# Auto-generated on first run

# Theme preferences
FLOWEROS_THEME="default"
FLOWEROS_THEME_AUTO_APPLY="true"

# MOTD preferences
FLOWEROS_MOTD_ENABLED="true"
FLOWEROS_MOTD_SIZE="medium"  # small, medium, large
FLOWEROS_MOTD_CUSTOM=""      # Path to custom MOTD

# Welcome screen preferences
FLOWEROS_WELCOME_SHOW_SYSTEM_INFO="true"
FLOWEROS_WELCOME_SHOW_COLORS="true"
FLOWEROS_WELCOME_SHOW_WISDOM="true"
FLOWEROS_WELCOME_STYLE="auto"  # auto, neofetch, small, medium, large, full

# Visual preferences
FLOWEROS_NERD_FONTS_ENABLED="true"
FLOWEROS_TRANSPARENCY="90"
FLOWEROS_COLOR_SCHEME="dracula"  # dracula, tokyo-night, nord

# Image processing defaults
FLOWEROS_IMAGE_COLS="120"
FLOWEROS_IMAGE_PASTEL="0.55"
FLOWEROS_IMAGE_MODE="half"

# Installation tracking
FLOWEROS_INSTALLED_DATE="$(date +%Y-%m-%d)"
FLOWEROS_VERSION="1.2.0"
FLOWEROS_USER="$USER"
EOF
    fi
}

# Load preferences
load_prefs() {
    [[ -f "$FLOWEROS_PREFS" ]] && source "$FLOWEROS_PREFS"
}

# Save preference
set_pref() {
    local key="$1"
    local value="$2"
    
    init_config
    
    if grep -q "^$key=" "$FLOWEROS_PREFS" 2>/dev/null; then
        sed -i "s|^$key=.*|$key=\"$value\"|" "$FLOWEROS_PREFS"
    else
        echo "$key=\"$value\"" >> "$FLOWEROS_PREFS"
    fi
    
    echo "✓ Set $key = $value"
}

# Get preference
get_pref() {
    local key="$1"
    load_prefs
    eval echo "\$$key"
}

# Show all preferences
show_prefs() {
    echo ""
    echo "🌸 FlowerOS User Preferences"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [[ ! -f "$FLOWEROS_PREFS" ]]; then
        echo "No preferences found. Run: floweros-config init"
        echo ""
        return 1
    fi
    
    load_prefs
    
    echo "📁 Config: $FLOWEROS_PREFS"
    echo ""
    echo "Theme Settings:"
    echo "  Theme:        $FLOWEROS_THEME"
    echo "  Auto-apply:   $FLOWEROS_THEME_AUTO_APPLY"
    echo ""
    echo "MOTD Settings:"
    echo "  Enabled:      $FLOWEROS_MOTD_ENABLED"
    echo "  Size:         $FLOWEROS_MOTD_SIZE"
    echo "  Custom:       ${FLOWEROS_MOTD_CUSTOM:-none}"
    echo ""
    echo "Welcome Screen:"
    echo "  System info:  $FLOWEROS_WELCOME_SHOW_SYSTEM_INFO"
    echo "  Colors:       $FLOWEROS_WELCOME_SHOW_COLORS"
    echo "  Wisdom:       $FLOWEROS_WELCOME_SHOW_WISDOM"
    echo "  Style:        $FLOWEROS_WELCOME_STYLE"
    echo ""
    echo "Visual:"
    echo "  Nerd Fonts:   $FLOWEROS_NERD_FONTS_ENABLED"
    echo "  Transparency: $FLOWEROS_TRANSPARENCY%"
    echo "  Color Scheme: $FLOWEROS_COLOR_SCHEME"
    echo ""
    echo "Installation:"
    echo "  Version:      $FLOWEROS_VERSION"
    echo "  User:         $FLOWEROS_USER"
    echo "  Installed:    $FLOWEROS_INSTALLED_DATE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# CLI
case "${1:-}" in
    init)
        init_config
        echo "✓ Initialized FlowerOS config: $FLOWEROS_PREFS"
        ;;
    set)
        if [[ -z "$2" ]] || [[ -z "$3" ]]; then
            echo "Usage: $0 set KEY VALUE"
            exit 1
        fi
        set_pref "$2" "$3"
        ;;
    get)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 get KEY"
            exit 1
        fi
        get_pref "$2"
        ;;
    show)
        show_prefs
        ;;
    edit)
        ${EDITOR:-nano} "$FLOWEROS_PREFS"
        ;;
    *)
        echo "FlowerOS Configuration Manager v1.2.0"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init           Initialize config (first time)"
        echo "  show           Show all preferences"
        echo "  get KEY        Get a preference value"
        echo "  set KEY VALUE  Set a preference"
        echo "  edit           Edit config file"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 show"
        echo "  $0 set FLOWEROS_THEME dracula"
        echo "  $0 set FLOWEROS_MOTD_SIZE large"
        echo "  $0 get FLOWEROS_THEME"
        echo ""
        echo "Config location: $FLOWEROS_PREFS"
        echo ""
        ;;
esac
