#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Post-Installation Setup
#  Interactive prompts for optional tools and configuration
# ═══════════════════════════════════════════════════════════════════════════

# Colors
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly CYAN='\033[36m'
readonly RED='\033[31m'
readonly MAGENTA='\033[35m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "${WINDIR:-}" ]]; then
        echo "windows"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

OS_TYPE=$(detect_os)

# ═══════════════════════════════════════════════════════════════════════════
#  Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

ok()   { echo -e "${GREEN}✓${RESET} $*"; }
info() { echo -e "${CYAN}✿${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "${RED}✗${RESET} $*" >&2; }

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        echo -en "${YELLOW}$prompt [Y/n]${RESET} "
    else
        echo -en "${YELLOW}$prompt [y/N]${RESET} "
    fi
    
    read -r response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}═══════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}${BOLD}  $1${RESET}"
    echo -e "${MAGENTA}${BOLD}═══════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Tool Detection
# ═══════════════════════════════════════════════════════════════════════════

check_tool() {
    command -v "$1" >/dev/null 2>&1
}

# ═══════════════════════════════════════════════════════════════════════════
#  Optional Tool Installers
# ═══════════════════════════════════════════════════════════════════════════

install_msys2() {
    if [[ "$OS_TYPE" != "windows" ]]; then
        warn "MSYS2 is only for Windows"
        return 1
    fi
    
    info "MSYS2 provides Unix tools (gcc, make, bash) on Windows"
    echo ""
    echo "  What it provides:"
    echo "    • gcc/g++ compilers"
    echo "    • make, cmake build tools"
    echo "    • Unix shell utilities"
    echo "    • Package manager (pacman)"
    echo ""
    echo "  Installation:"
    echo "    1. Download from: https://www.msys2.org/"
    echo "    2. Run installer"
    echo "    3. Open MSYS2 terminal"
    echo "    4. Run: pacman -S mingw-w64-x86_64-gcc make"
    echo ""
    
    if ask_yes_no "Open MSYS2 download page?"; then
        start "https://www.msys2.org/" 2>/dev/null || \
        powershell.exe -Command "Start-Process 'https://www.msys2.org/'" 2>/dev/null || \
        echo "Visit: https://www.msys2.org/"
        ok "Opened MSYS2 download page"
    fi
}

install_ollama() {
    info "Ollama - Run local LLMs (Llama, Mistral, etc.)"
    echo ""
    echo "  What it provides:"
    echo "    • Run AI models locally"
    echo "    • No internet required after download"
    echo "    • Privacy-focused AI assistant"
    echo "    • Integration with FlowerOS features"
    echo ""
    echo "  Models available:"
    echo "    • llama3.2 (4GB)"
    echo "    • mistral (4GB)"
    echo "    • codellama (4GB)"
    echo "    • phi3 (2GB)"
    echo ""
    
    if check_tool ollama; then
        ok "Ollama already installed"
        if ask_yes_no "Pull recommended model (llama3.2)?"; then
            ollama pull llama3.2
        fi
        return 0
    fi
    
    if ask_yes_no "Install Ollama?"; then
        case "$OS_TYPE" in
            linux)
                info "Installing Ollama via curl..."
                curl -fsSL https://ollama.com/install.sh | sh && ok "Ollama installed" || err "Install failed"
                ;;
            macos)
                if check_tool brew; then
                    info "Installing Ollama via Homebrew..."
                    brew install ollama && ok "Ollama installed" || err "Install failed"
                else
                    info "Opening Ollama download page..."
                    open "https://ollama.com/download" 2>/dev/null || echo "Visit: https://ollama.com/download"
                fi
                ;;
            windows)
                info "Opening Ollama download page..."
                start "https://ollama.com/download" 2>/dev/null || \
                powershell.exe -Command "Start-Process 'https://ollama.com/download'" 2>/dev/null || \
                echo "Visit: https://ollama.com/download"
                ;;
        esac
    fi
}

install_fzf() {
    info "fzf - Fuzzy finder for terminal"
    echo ""
    echo "  What it provides:"
    echo "    • Fast file/command searching"
    echo "    • Ctrl+R for command history search"
    echo "    • Integration with flower_fortune, etc."
    echo ""
    
    if check_tool fzf; then
        ok "fzf already installed"
        return 0
    fi
    
    if ask_yes_no "Install fzf?"; then
        case "$OS_TYPE" in
            linux)
                if check_tool apt-get; then
                    sudo apt-get update && sudo apt-get install -y fzf && ok "fzf installed"
                elif check_tool dnf; then
                    sudo dnf install -y fzf && ok "fzf installed"
                elif check_tool pacman; then
                    sudo pacman -S --noconfirm fzf && ok "fzf installed"
                else
                    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
                fi
                ;;
            macos)
                brew install fzf && $(brew --prefix)/opt/fzf/install && ok "fzf installed"
                ;;
            windows)
                if check_tool choco; then
                    choco install fzf -y && ok "fzf installed"
                elif check_tool scoop; then
                    scoop install fzf && ok "fzf installed"
                else
                    warn "Install via Chocolatey: choco install fzf"
                    warn "Or Scoop: scoop install fzf"
                fi
                ;;
        esac
    fi
}

install_bat() {
    info "bat - A cat clone with syntax highlighting"
    echo ""
    echo "  What it provides:"
    echo "    • Syntax highlighting for code"
    echo "    • Git integration"
    echo "    • Automatic paging"
    echo "    • Better ASCII art display"
    echo ""
    
    if check_tool bat || check_tool batcat; then
        ok "bat already installed"
        return 0
    fi
    
    if ask_yes_no "Install bat?"; then
        case "$OS_TYPE" in
            linux)
                if check_tool apt-get; then
                    sudo apt-get update && sudo apt-get install -y bat && ok "bat installed (use 'batcat' on Debian/Ubuntu)"
                elif check_tool dnf; then
                    sudo dnf install -y bat && ok "bat installed"
                elif check_tool pacman; then
                    sudo pacman -S --noconfirm bat && ok "bat installed"
                fi
                ;;
            macos)
                brew install bat && ok "bat installed"
                ;;
            windows)
                if check_tool choco; then
                    choco install bat -y && ok "bat installed"
                elif check_tool scoop; then
                    scoop install bat && ok "bat installed"
                fi
                ;;
        esac
    fi
}

install_neofetch() {
    info "neofetch - System info with ASCII art"
    echo ""
    echo "  What it provides:"
    echo "    • Beautiful system info display"
    echo "    • Customizable ASCII art"
    echo "    • Pairs well with FlowerOS themes"
    echo ""
    
    if check_tool neofetch; then
        ok "neofetch already installed"
        return 0
    fi
    
    if ask_yes_no "Install neofetch?"; then
        case "$OS_TYPE" in
            linux)
                if check_tool apt-get; then
                    sudo apt-get update && sudo apt-get install -y neofetch && ok "neofetch installed"
                elif check_tool dnf; then
                    sudo dnf install -y neofetch && ok "neofetch installed"
                elif check_tool pacman; then
                    sudo pacman -S --noconfirm neofetch && ok "neofetch installed"
                fi
                ;;
            macos)
                brew install neofetch && ok "neofetch installed"
                ;;
            windows)
                if check_tool scoop; then
                    scoop install neofetch && ok "neofetch installed"
                else
                    warn "Install via Scoop: scoop install neofetch"
                fi
                ;;
        esac
    fi
}

install_lolcat() {
    info "lolcat - Rainbow colorizer"
    echo ""
    echo "  What it provides:"
    echo "    • Rainbow color output"
    echo "    • Fun ASCII art display"
    echo "    • Pipe any command through it"
    echo ""
    
    if check_tool lolcat; then
        ok "lolcat already installed"
        return 0
    fi
    
    if ask_yes_no "Install lolcat?"; then
        case "$OS_TYPE" in
            linux)
                if check_tool apt-get; then
                    sudo apt-get update && sudo apt-get install -y lolcat && ok "lolcat installed"
                elif check_tool gem; then
                    sudo gem install lolcat && ok "lolcat installed"
                fi
                ;;
            macos)
                brew install lolcat && ok "lolcat installed"
                ;;
            windows)
                warn "Install Ruby, then: gem install lolcat"
                ;;
        esac
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Configuration Questions
# ═══════════════════════════════════════════════════════════════════════════

configure_quiet_mode() {
    echo ""
    info "Quiet Mode Configuration"
    echo ""
    echo "  FlowerOS displays a random ASCII line on each new terminal."
    echo "  You can disable this for a quieter experience."
    echo ""
    
    if ask_yes_no "Enable quiet mode (no auto-ASCII on terminal open)?"; then
        echo 'export FLOWEROS_QUIET=1' >> ~/.bashrc
        ok "Quiet mode enabled (FLOWEROS_QUIET=1)"
    else
        ok "Kept default: ASCII art on each terminal open"
    fi
}

configure_custom_dir() {
    echo ""
    info "Custom ASCII Directory"
    echo ""
    echo "  You can use a custom directory for your ASCII art files."
    echo "  Default: ~/FlowerOS/ascii"
    echo ""
    
    if ask_yes_no "Use custom ASCII directory?"; then
        echo -n "  Enter path: "
        read -r custom_path
        if [[ -n "$custom_path" ]]; then
            echo "export FLOWEROS_ASCII_DIR=\"$custom_path\"" >> ~/.bashrc
            ok "Custom directory set: $custom_path"
        fi
    else
        ok "Using default: ~/FlowerOS/ascii"
    fi
}

configure_network_features() {
    echo ""
    info "Network Features (v1.3.X Experimental)"
    echo ""
    echo -e "  ${RED}⚠ WARNING: These are experimental features${RESET}"
    echo ""
    echo "  Network features allow:"
    echo "    • Running terminal as network node"
    echo "    • Distributed theme synchronization"
    echo "    • GPU batch processing over network"
    echo ""
    
    if ask_yes_no "Enable network features?"; then
        echo "export FLOWEROS_NETWORK_ENABLED=1" >> ~/.bashrc
        echo "source ~/FlowerOS/lib/terminal_network.sh 2>/dev/null || true" >> ~/.bashrc
        ok "Network features enabled"
        warn "Remember: These are EXPERIMENTAL!"
    else
        ok "Network features disabled (stable mode)"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main Post-Install Flow
# ═══════════════════════════════════════════════════════════════════════════

run_post_install() {
    local install_type="${1:-user}"  # user, permanent, or quick
    
    header "FlowerOS Post-Installation Setup"
    
    echo "Detected OS: $OS_TYPE"
    echo "Install type: $install_type"
    echo ""
    
    # ─── Skip everything for quick install ─────────────────────────────────
    if [[ "$install_type" == "quick" ]]; then
        info "Quick install - skipping optional setup"
        echo ""
        echo "Run 'bash lib/post-install.sh' later for optional tools."
        return 0
    fi
    
    # ─── Ask about optional tools ──────────────────────────────────────────
    header "Optional Tools"
    
    echo "FlowerOS works better with some optional tools."
    echo "You can skip all of these if you prefer."
    echo ""
    
    if ask_yes_no "Would you like to see optional tool recommendations?" "y"; then
        echo ""
        
        # Windows-specific: MSYS2
        if [[ "$OS_TYPE" == "windows" ]]; then
            if ! check_tool gcc; then
                echo "─────────────────────────────────────────────────────────────────"
                install_msys2
                echo ""
            fi
        fi
        
        # Universal tools
        echo "─────────────────────────────────────────────────────────────────"
        install_fzf
        echo ""
        
        echo "─────────────────────────────────────────────────────────────────"
        install_bat
        echo ""
        
        echo "─────────────────────────────────────────────────────────────────"
        install_neofetch
        echo ""
        
        echo "─────────────────────────────────────────────────────────────────"
        install_lolcat
        echo ""
        
        # AI features
        if [[ "$install_type" == "permanent" ]] || ask_yes_no "Interested in local AI features?"; then
            echo "─────────────────────────────────────────────────────────────────"
            install_ollama
            echo ""
        fi
    else
        ok "Skipped optional tools"
    fi
    
    # ─── Configuration questions ───────────────────────────────────────────
    header "Configuration"
    
    if ask_yes_no "Configure FlowerOS settings now?" "y"; then
        configure_quiet_mode
        configure_custom_dir
        
        # Network only for permanent/advanced installs
        if [[ "$install_type" == "permanent" ]]; then
            configure_network_features
        fi
    else
        ok "Using default configuration"
    fi
    
    # ─── Summary ───────────────────────────────────────────────────────────
    header "Setup Complete!"
    
    echo "FlowerOS is ready to use."
    echo ""
    echo "Quick commands:"
    echo "  flower_banner 'Hello'    - Generate banner"
    echo "  flower_fortune           - Get wisdom"
    echo "  flower_colortest         - Test terminal colors"
    echo ""
    
    if [[ "$install_type" == "permanent" ]]; then
        echo "Permanent install commands:"
        echo "  floweros-info            - Show version"
        echo "  floweros-status          - Show status"
        echo ""
    fi
    
    echo -e "${MAGENTA}Every terminal session is a garden. 🌸${RESET}"
    echo ""
    
    info "To activate now, run: source ~/.bashrc"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Entry Point
# ═══════════════════════════════════════════════════════════════════════════

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_post_install "${1:-user}"
fi
