#!/usr/bin/env bash
# FlowerOS Breathtaking Welcome System (Bash)
# Stunning visual experience with neofetch/fastfetch integration

set -e

# ═══════════════════════════════════════════════════════════════════════════
#  Configuration
# ═══════════════════════════════════════════════════════════════════════════

FLOWEROS_VERSION="1.2.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASCII_DIR="$SCRIPT_DIR/ascii"
CONFIG_DIR="$HOME/.floweros"

# Nerd Font Icons
ICON_OS=""
ICON_KERNEL=""
ICON_CPU=""
ICON_GPU="󰢮"
ICON_MEMORY=""
ICON_DISK="󰋊"
ICON_SHELL=""
ICON_TERMINAL=""
ICON_TIME=""
ICON_USER=""
ICON_HOST="󰒋"
ICON_FLOWER="🌸"

# Colors (ANSI)
C_RESET="\033[0m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_GREEN="\033[32m"
C_GRAY="\033[90m"
C_BOLD="\033[1m"

# ═══════════════════════════════════════════════════════════════════════════
#  ASCII Art Display
# ═══════════════════════════════════════════════════════════════════════════

show_floweros_art() {
    local size="${1:-medium}"
    local art_file="$ASCII_DIR/floweros-$size.txt"
    
    if [[ -f "$art_file" ]]; then
        echo -e "${C_MAGENTA}"
        cat "$art_file"
        echo -e "${C_RESET}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  System Information (neofetch-style)
# ═══════════════════════════════════════════════════════════════════════════

get_system_info() {
    # OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_INFO="$NAME $VERSION_ID"
    else
        OS_INFO="$(uname -s) $(uname -r)"
    fi
    
    # Kernel
    KERNEL_INFO="$(uname -r)"
    
    # Shell
    SHELL_INFO="$(basename "$SHELL") $(${SHELL} --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo '')"
    
    # CPU
    if [[ -f /proc/cpuinfo ]]; then
        CPU_INFO="$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')"
    else
        CPU_INFO="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
    fi
    
    # Memory
    if command -v free >/dev/null 2>&1; then
        local total=$(free -h | awk '/^Mem:/{print $2}')
        local used=$(free -h | awk '/^Mem:/{print $3}')
        MEMORY_INFO="$used / $total"
    else
        MEMORY_INFO="N/A"
    fi
    
    # Disk
    DISK_INFO="$(df -h / | awk 'NR==2{print $3 " / " $2}')"
    
    # Uptime
    if command -v uptime >/dev/null 2>&1; then
        UPTIME_INFO="$(uptime -p 2>/dev/null | sed 's/up //' || uptime | awk -F'( |,|:)+' '{print $6,$7",",$8,"hours,",$9,"minutes."}')"
    else
        UPTIME_INFO="N/A"
    fi
}

show_system_info() {
    get_system_info
    
    local left_width=15
    
    echo ""
    
    # OS
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_OS" "OS" "$OS_INFO"
    
    # User@Host
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_USER" "User" "${USER}@${HOSTNAME}"
    
    # Kernel
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_KERNEL" "Kernel" "$KERNEL_INFO"
    
    # Shell
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_SHELL" "Shell" "$SHELL_INFO"
    
    # Terminal
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_TERMINAL" "Terminal" "${TERM:-unknown}"
    
    # CPU
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_CPU" "CPU" "$CPU_INFO"
    
    # Memory
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_MEMORY" "Memory" "$MEMORY_INFO"
    
    # Disk
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_DISK" "Disk" "$DISK_INFO"
    
    # Uptime
    printf " ${C_CYAN}%s${C_RESET} ${C_GRAY}%-${left_width}s${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$ICON_TIME" "Uptime" "$UPTIME_INFO"
    
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Color Palette
# ═══════════════════════════════════════════════════════════════════════════

show_color_palette() {
    printf " ${C_GRAY}Color Palette  ${C_RESET}"
    printf "\033[30m█\033[0m"  # Black
    printf "\033[31m█\033[0m"  # Red
    printf "\033[32m█\033[0m"  # Green
    printf "\033[33m█\033[0m"  # Yellow
    printf "\033[34m█\033[0m"  # Blue
    printf "\033[35m█\033[0m"  # Magenta
    printf "\033[36m█\033[0m"  # Cyan
    printf "\033[37m█\033[0m"  # White
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Wisdom/Quotes
# ═══════════════════════════════════════════════════════════════════════════

show_wisdom() {
    local quotes=(
        "Every terminal session is a garden 🌸"
        "Code with beauty, debug with grace 🌺"
        "Professional tools deserve professional themes 💎"
        "Simplicity is the ultimate sophistication ✨"
        "Make your terminal a place you love to be 🎨"
        "Beautiful code starts with a beautiful environment 🌟"
    )
    
    local quote="${quotes[$RANDOM % ${#quotes[@]}]}"
    
    echo ""
    printf "  ${C_YELLOW}%s${C_RESET} ${C_GRAY}%s${C_RESET}\n" "$ICON_FLOWER" "$quote"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Neofetch Integration
# ═══════════════════════════════════════════════════════════════════════════

show_with_neofetch() {
    if command -v neofetch >/dev/null 2>&1; then
        neofetch --ascii "$ASCII_DIR/floweros-small.txt" \
                 --ascii_colors 5 \
                 --colors 5 6 2 4 7 6 \
                 --bold on \
                 --underline on
        show_wisdom
    elif command -v fastfetch >/dev/null 2>&1; then
        fastfetch --logo "$ASCII_DIR/floweros-small.txt" \
                  --logo-color-1 magenta \
                  --color magenta
        show_wisdom
    else
        show_welcome_fallback
    fi
}

show_welcome_fallback() {
    clear
    show_floweros_art "medium"
    show_system_info
    show_color_palette
    show_wisdom
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main Welcome
# ═══════════════════════════════════════════════════════════════════════════

floweros_welcome() {
    local style="${1:-auto}"
    
    case "$style" in
        neofetch)
            show_with_neofetch
            ;;
        full)
            clear
            show_floweros_art "large"
            show_system_info
            show_color_palette
            show_wisdom
            ;;
        medium)
            clear
            show_floweros_art "medium"
            show_system_info
            show_color_palette
            show_wisdom
            ;;
        small)
            show_floweros_art "small"
            show_wisdom
            ;;
        auto)
            # Auto-detect: use neofetch if available
            if command -v neofetch >/dev/null 2>&1 || command -v fastfetch >/dev/null 2>&1; then
                show_with_neofetch
            else
                show_welcome_fallback
            fi
            ;;
        *)
            show_welcome_fallback
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  Installation
# ═══════════════════════════════════════════════════════════════════════════

floweros_install_welcome() {
    echo ""
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET}  🌸 FlowerOS Welcome System Installer                    ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    # Check if already installed
    if grep -q "FlowerOS Welcome" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "${C_YELLOW}⚠ FlowerOS Welcome already installed${C_RESET}"
        echo ""
        return 1
    fi
    
    # Backup bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${C_GREEN}✓ Backed up ~/.bashrc${C_RESET}"
    fi
    
    # Get welcome script path
    local welcome_path="$SCRIPT_DIR/FlowerOS-Welcome.sh"
    
    # Add to bashrc
    cat >> "$HOME/.bashrc" <<EOF

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Welcome v${FLOWEROS_VERSION}
# ═══════════════════════════════════════════════════════════════════════════

source "$welcome_path"
floweros_welcome auto

EOF
    
    echo -e "${C_GREEN}✓ Installed to ~/.bashrc${C_RESET}"
    echo ""
    echo -e "${C_YELLOW}✨ Run 'source ~/.bashrc' or open a new terminal!${C_RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-}" in
    show)
        floweros_welcome "${2:-auto}"
        ;;
    install)
        floweros_install_welcome
        ;;
    *)
        # If sourced, don't auto-run (let bashrc handle it)
        if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
            floweros_welcome auto
        fi
        ;;
esac
