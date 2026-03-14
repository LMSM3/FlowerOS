#!/usr/bin/env bash
# FlowerOS Breathtaking Experience Installer (Bash/WSL Version)
# One-command transformation for Linux/WSL users

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_YELLOW="\033[33m"
C_GREEN="\033[32m"
C_RED="\033[31m"
C_GRAY="\033[90m"
C_RESET="\033[0m"

show_header() {
    clear
    echo ""
    echo -e "${C_MAGENTA}╔══════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║                                                                          ║${C_RESET}"
    echo -e "${C_MAGENTA}║     🌸 FlowerOS v1.2.0 - Breathtaking Experience Installer 🌸           ║${C_RESET}"
    echo -e "${C_MAGENTA}║                                                                          ║${C_RESET}"
    echo -e "${C_MAGENTA}║         Transform your terminal from boring to BEAUTIFUL!               ║${C_RESET}"
    echo -e "${C_MAGENTA}║                                                                          ║${C_RESET}"
    echo -e "${C_MAGENTA}╚══════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

show_step() {
    echo ""
    echo -e "${C_CYAN}  $1${C_RESET}"
    echo -e "${C_GRAY}  $(printf '─%.0s' {1..70})${C_RESET}"
}

show_success() {
    echo -e "${C_GREEN}  ✓ $1${C_RESET}"
}

show_warning() {
    echo -e "${C_YELLOW}  ⚠ $1${C_RESET}"
}

show_error() {
    echo -e "${C_RED}  ✗ $1${C_RESET}"
}

install_nerd_font() {
    show_step "📦 Installing Nerd Fonts"
    
    if fc-list | grep -i "CaskaydiaCove" >/dev/null 2>&1; then
        show_success "CaskaydiaCove Nerd Font already installed"
        return 0
    fi
    
    echo -e "${C_GRAY}  → Downloading Cascadia Code Nerd Font...${C_RESET}"
    
    local temp_dir="/tmp/floweros-fonts"
    local zip_path="$temp_dir/CascadiaCode.zip"
    
    mkdir -p "$temp_dir"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" -O "$zip_path"
    elif command -v curl >/dev/null 2>&1; then
        curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" -o "$zip_path"
    else
        show_error "Neither wget nor curl found"
        return 1
    fi
    
    echo -e "${C_GRAY}  → Extracting...${C_RESET}"
    unzip -q "$zip_path" -d "$temp_dir"
    
    echo -e "${C_GRAY}  → Installing fonts...${C_RESET}"
    
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    
    find "$temp_dir" -name "*.ttf" -exec cp {} "$font_dir/" \;
    
    # Refresh font cache
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$font_dir"
    fi
    
    rm -rf "$temp_dir"
    
    show_success "Nerd Fonts installed"
    show_warning "Restart terminal to see fonts"
}

install_welcome_system() {
    show_step "🌸 Installing Welcome System"
    
    local welcome_sh="$SCRIPT_DIR/FlowerOS-Welcome.sh"
    
    if [[ ! -f "$welcome_sh" ]]; then
        show_error "Welcome script not found: $welcome_sh"
        return 1
    fi
    
    # Check if already installed
    if grep -q "FlowerOS Welcome" "$HOME/.bashrc" 2>/dev/null; then
        show_warning "FlowerOS Welcome already in ~/.bashrc"
        return 0
    fi
    
    # Backup bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        show_success "Backed up ~/.bashrc"
    fi
    
    # Add to bashrc
    cat >> "$HOME/.bashrc" <<EOF

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Welcome v1.2.0
#  Installed: $(date '+%Y-%m-%d %H:%M:%S')
# ═══════════════════════════════════════════════════════════════════════════

source "$welcome_sh"
floweros_welcome auto

EOF
    
    show_success "Welcome system installed to ~/.bashrc"
}

install_python_deps() {
    show_step "🐍 Checking Python Dependencies"
    
    if ! command -v python3 >/dev/null 2>&1; then
        show_warning "Python3 not found - image tools will not work"
        return 1
    fi
    
    if python3 -c "import PIL" 2>/dev/null; then
        show_success "Pillow already installed"
        return 0
    fi
    
    echo -e "${C_GRAY}  → Installing Pillow...${C_RESET}"
    
    if python3 -m pip install --user pillow >/dev/null 2>&1; then
        show_success "Pillow installed"
    else
        show_warning "Could not install Pillow (image tools disabled)"
    fi
}

show_preview() {
    show_step "🎉 Installation Complete!"
    
    echo ""
    echo -e "${C_CYAN}  Your terminal transformation includes:${C_RESET}"
    echo ""
    echo -e "${C_MAGENTA}    🌸  Beautiful ASCII art welcome screen${C_RESET}"
    echo -e "${C_MAGENTA}    📊  System info display with icons${C_RESET}"
    echo -e "${C_MAGENTA}    🎨  Image-to-terminal converters${C_RESET}"
    echo -e "${C_MAGENTA}    🔠  Nerd Font icons${C_RESET}"
    echo -e "${C_MAGENTA}    🌈  Color palette display${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}  Next Steps:${C_RESET}"
    echo ""
    echo -e "${C_GRAY}    1. Run: ${C_CYAN}source ~/.bashrc${C_RESET}"
    echo -e "${C_GRAY}    2. Or open a new terminal${C_RESET}"
    echo -e "${C_GRAY}    3. See the magic! 🎭${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}  Convert images:${C_RESET}"
    echo -e "${C_GRAY}    bash $SCRIPT_DIR/image-tools/img2term.sh yourimage.png${C_RESET}"
    echo ""
    
    echo -e "${C_MAGENTA}  🌺 Every terminal session is now a garden! 🌺${C_RESET}"
    echo ""
}

# Main installation
show_header

echo -e "${C_CYAN}This installer will:${C_RESET}"
echo -e "${C_GRAY}  • Install Nerd Fonts (for beautiful icons)${C_RESET}"
echo -e "${C_GRAY}  • Set up welcome screen (ASCII art, system info)${C_RESET}"
echo -e "${C_GRAY}  • Install Python dependencies (for image tools)${C_RESET}"
echo ""

read -p "Continue? (Y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""

# Run installations
install_nerd_font
install_python_deps
install_welcome_system

# Show preview
show_preview

# Test welcome screen
echo -e "${C_CYAN}  Preview of welcome screen:${C_RESET}"
echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""

source "$SCRIPT_DIR/FlowerOS-Welcome.sh"
floweros_welcome small

echo ""
echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""
