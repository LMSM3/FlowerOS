#!/usr/bin/env bash
# FlowerOS Professional Theme System (Bash/WSL)
# Simple, elegant light/grey themes only

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.floweros/theme.conf"

set_theme() {
    local theme="$1"
    
    echo ""
    echo -e "\033[36m🎨 FlowerOS Professional Theme\033[0m"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    case "$theme" in
        light)
            # Clean light theme (minimal colors)
            export FLOWEROS_THEME="light"
            export PS1="\[\033[90m\]\w\[\033[0m\] \[\033[34m\]❯\[\033[0m\] "
            
            # Set terminal colors if supported
            if [[ -n "${TERM:-}" ]]; then
                printf "\033]10;#000000\007"  # foreground: black
                printf "\033]11;#FFFFFF\007"  # background: white
            fi
            
            echo "✓ Light theme applied"
            ;;
            
        grey)
            # Professional grey theme
            export FLOWEROS_THEME="grey"
            export PS1="\[\033[90m\]\w\[\033[0m\] \[\033[36m\]❯\[\033[0m\] "
            
            # Set terminal colors if supported
            if [[ -n "${TERM:-}" ]]; then
                printf "\033]10;#B0B0B0\007"  # foreground: grey
                printf "\033]11;#000000\007"  # background: black
            fi
            
            echo "✓ Grey theme applied"
            ;;
            
        *)
            echo "Error: Theme must be 'light' or 'grey'" >&2
            return 1
            ;;
    esac
    
    # Save preference
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOF
# FlowerOS Theme Configuration
FLOWEROS_THEME="$theme"
FLOWEROS_VERSION="1.1.0"
EOF
    
    echo ""
    echo -e "\033[35m✨ Professional and clean!\033[0m"
    echo ""
}

get_theme() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo "${FLOWEROS_THEME:-none}"
    else
        echo "none"
    fi
}

# CLI
case "${1:-}" in
    light|grey)
        set_theme "$1"
        ;;
    get)
        get_theme
        ;;
    *)
        echo "FlowerOS Professional Theme v1.1"
        echo ""
        echo "Usage: $0 <light|grey|get>"
        echo ""
        echo "Themes:"
        echo "  light    Clean, minimal light theme"
        echo "  grey     Professional grey theme"
        echo "  get      Show current theme"
        echo ""
        ;;
esac
