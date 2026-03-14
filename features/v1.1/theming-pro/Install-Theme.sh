#!/usr/bin/env bash
# FlowerOS Professional Theme Installer (Bash)
# One-command installation for bash & WSL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_FILE="$SCRIPT_DIR/FlowerOS-Bash.sh"

# Colors for output
C_CYAN="\033[36m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_GRAY="\033[90m"
C_RESET="\033[0m"

show_header() {
    echo ""
    echo -e "${C_CYAN}╔═══════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  🌸 FlowerOS Professional Theme Installer                    ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╚═══════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

install_theme() {
    show_header
    echo -e "${C_YELLOW}Installing FlowerOS bash theme...${C_RESET}"
    echo ""
    
    if [[ ! -f "$THEME_FILE" ]]; then
        echo -e "${C_RED}✗ Theme file not found: $THEME_FILE${C_RESET}"
        exit 1
    fi
    
    # Load theme
    source "$THEME_FILE"
    
    # Run installer
    floweros_install_bash_theme
    
    echo -e "${C_GREEN}✨ Installation complete!${C_RESET}"
    echo ""
    echo -e "${C_YELLOW}Next steps:${C_RESET}"
    echo -e "  1. Run: ${C_CYAN}source ~/.bashrc${C_RESET}"
    echo -e "  2. Or open a new terminal"
    echo ""
}

uninstall_theme() {
    show_header
    echo -e "${C_YELLOW}Removing FlowerOS bash theme...${C_RESET}"
    echo ""
    
    source "$THEME_FILE"
    floweros_uninstall_bash_theme
    
    echo -e "${C_GREEN}✨ Uninstallation complete!${C_RESET}"
    echo ""
}

show_status() {
    show_header
    
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "FlowerOS Theme" "$HOME/.bashrc"; then
            echo -e "${C_GREEN}✓ FlowerOS theme is installed${C_RESET}"
            echo -e "  ${C_GRAY}File: ~/.bashrc${C_RESET}"
            
            # Extract version
            local version=$(grep "FlowerOS Theme v" "$HOME/.bashrc" | grep -oP 'v\K[\d\.]+' || echo "unknown")
            echo -e "  ${C_GRAY}Version: $version${C_RESET}"
        else
            echo -e "${C_RED}✗ FlowerOS theme is not installed${C_RESET}"
        fi
    else
        echo -e "${C_RED}✗ No ~/.bashrc found${C_RESET}"
    fi
    echo ""
}

# Main
case "${1:-install}" in
    install)
        install_theme
        ;;
    uninstall)
        uninstall_theme
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {install|uninstall|status}"
        exit 1
        ;;
esac
