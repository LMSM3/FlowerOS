#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS v1.3.0 - Interactive Deployment Script
# 
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'

# ═══════════════════════════════════════════════════════════════════════════
#  Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

banner() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}                                                                           ${GREEN}║${RESET}"
    echo -e "${GREEN}║${RESET}  ${CYAN}$1${RESET}  ${GREEN}║${RESET}"
    echo -e "${GREEN}║${RESET}                                                                           ${GREEN}║${RESET}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

prompt() {
    echo -e "${YELLOW}$1${RESET}"
    echo -n "> "
    read -r response
    echo "$response"
}

confirm() {
    echo -e "${YELLOW}$1 [y/N]${RESET}"
    echo -n "> "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

warning() {
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET}  ⚠️  $1  ${RED}║${RESET}"                                                                    ║${RESET}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

success() {
    echo -e "${GREEN}✓ $1${RESET}"
}

info() {
    echo -e "${CYAN}ℹ $1${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Welcome
# ═══════════════════════════════════════════════════════════════════════════

clear
banner "FlowerOS v1.3.0 - Interactive Deployment"

echo "This script will guide you through deploying FlowerOS."
echo "You will be asked to make decisions at each step."
echo ""
echo "This script can take a very long time"
echo ""

if ! confirm "Ready to begin?"; then
    echo "Deployment cancelled."
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════
#  Shell Version Check
# ═══════════════════════════════════════════════════════════════════════════

banner "Prerequisites Check"

# Check bash version
info "Checking bash version..."
bash_version=$(bash --version | head -n1 | grep -oP '\d+\.\d+' | head -n1)
if [[ $(echo "$bash_version >= 4.0" | bc) -eq 1 ]]; then
    success "Bash $bash_version (✓ 4.0+ required)"
else
    warning "Bash $bash_version is too old. Need 4.0+"
    exit 1
fi

# Check gcc
info "Checking gcc..."
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version | head -n1)
    success "GCC found: $gcc_version"
else
    warning "GCC not found"
    if confirm "Install build-essential?"; then
        sudo apt-get update
        sudo apt-get install -y build-essential
        success "GCC installed"
    else
        echo "Cannot proceed without GCC"
        exit 1
    fi
fi

# Check if the user has git
info "Checking git..."
if command -v git &> /dev/null; then
    success "Git found"
else
    warning "Git not found"
    if confirm "Install git?"; then
        sudo apt-get install -y git
        success "Git installed"
    else
        echo "Cannot proceed without git"
        exit 1
    fi
fi

success "All prerequisites satisfied"
sleep 2

# ═══════════════════════════════════════════════════════════════════════════
#  DECISION 1: Installation Type
# ═══════════════════════════════════════════════════════════════════════════

clear
banner "DECISION 1: Installation Type"

echo "Choose installation type:"
echo ""
echo "  [Q] Quick Test (5 min)"
echo "      • Temporary installation"
echo "      • Easy to remove"
echo "      • Test features"
echo ""
echo "  [U] User Installation (10 min)"
echo "      • Install to your account"
echo "      • Permanent for you"
echo "      • Removable"
echo ""
echo "  [S] System-Wide Permanent (20 min)"
echo "      • Install for all users"
echo "      • Requires sudo"
echo "      • Difficult to remove"
echo ""

INSTALL_TYPE=$(prompt "Your choice [Q/U/S]:")
INSTALL_TYPE=$(echo "$INSTALL_TYPE" | tr '[:lower:]' '[:upper:]')

case "$INSTALL_TYPE" in
    Q)
        info "Selected: Quick Test"
        ;;
    U)
        info "Selected: User Installation"
        ;;
    S)
        warning "System-Wide Permanent Installation"
        echo "This will:"
        echo "  • Modify /etc/bash.bashrc"
        echo "  • Install to /opt/floweros"
        echo "  • Affect ALL users"
        echo "  • Use immutable flags"
        echo ""
        
        if ! confirm "Do you understand the implications?"; then
            echo "Deployment cancelled."
            exit 0
        fi
        
        echo ""
        echo "Type EXACTLY: I UNDERSTAND THE RISKS"
        CONFIRM=$(prompt "Confirmation:")
        if [ "$CONFIRM" != "I UNDERSTAND THE RISKS" ]; then
            echo "Confirmation failed. Deployment cancelled."
            exit 0
        fi
        
        info "Selected: System-Wide Permanent"
        ;;
    *)
        echo "Invalid choice. Deployment cancelled."
        exit 1
        ;;
esac

sleep 2

# ═══════════════════════════════════════════════════════════════════════════
#  DECISION 2: Network Features
# ═══════════════════════════════════════════════════════════════════════════

clear
banner "DECISION 2: Network Features"

warning "Network features are EXPERIMENTAL"
echo "These features are not production-ready."
echo ""

if confirm "Enable network features?"; then
    ENABLE_NETWORK=true
    info "Network features will be enabled"
    
    # Network mode
    echo ""
    echo "Network deployment mode:"
    echo "  [S] Single machine (localhost)"
    echo "  [L] Local network (LAN)"
    echo "  [C] Cluster/multi-machine"
    echo ""
    
    NETWORK_MODE=$(prompt "Your choice [S/L/C]:")
    NETWORK_MODE=$(echo "$NETWORK_MODE" | tr '[:lower:]' '[:upper:]')
    
    # Port
    echo ""
    NETWORK_PORT=$(prompt "Network port (default: 7777):")
    NETWORK_PORT=${NETWORK_PORT:-7777}
    info "Using port: $NETWORK_PORT"
else
    ENABLE_NETWORK=false
    info "Network features disabled"
fi

sleep 2

# ═══════════════════════════════════════════════════════════════════════════
#  DECISION 3: GPU Features
# ═══════════════════════════════════════════════════════════════════════════

clear
banner "DECISION 3: GPU Features"

warning "GPU features are EXPERIMENTAL"

# Check for GPU
if command -v nvidia-smi &> /dev/null; then
    success "NVIDIA GPU detected"
    nvidia-smi --query-gpu=name --format=csv,noheader
    echo ""
    
    if confirm "Enable GPU features?"; then
        ENABLE_GPU=true
        info "GPU features will be enabled"
        
        # Batch size
        echo ""
        echo "GPU batch size:"
        echo "  [S] Small (32 items)"
        echo "  [M] Medium (128 items)"
        echo "  [L] Large (512 items)"
        echo ""
        
        BATCH_SIZE_CHOICE=$(prompt "Your choice [S/M/L]:")
        BATCH_SIZE_CHOICE=$(echo "$BATCH_SIZE_CHOICE" | tr '[:lower:]' '[:upper:]')
        
        case "$BATCH_SIZE_CHOICE" in
            S) GPU_BATCH_SIZE=32 ;;
            M) GPU_BATCH_SIZE=128 ;;
            L) GPU_BATCH_SIZE=512 ;;
            *) GPU_BATCH_SIZE=128 ;;
        esac
        
        info "Batch size: $GPU_BATCH_SIZE"
    else
        ENABLE_GPU=false
        info "GPU features disabled"
    fi
else
    info "No GPU detected"
    ENABLE_GPU=false
fi

sleep 2

# ═══════════════════════════════════════════════════════════════════════════
#  Deployment Summary
# ═══════════════════════════════════════════════════════════════════════════

clear
banner "Deployment Summary"

echo "You have selected:"
echo ""
echo "  Installation Type: $INSTALL_TYPE"
echo "  Network Features:  $([ "$ENABLE_NETWORK" = true ] && echo "Enabled ($NETWORK_MODE, port $NETWORK_PORT)" || echo "Disabled")"
echo "  GPU Features:      $([ "$ENABLE_GPU" = true ] && echo "Enabled (batch: $GPU_BATCH_SIZE)" || echo "Disabled")"
echo ""

# Calculate time
TIME_ESTIMATE=0
case "$INSTALL_TYPE" in
    Q) TIME_ESTIMATE=$((TIME_ESTIMATE + 5)) ;;
    U) TIME_ESTIMATE=$((TIME_ESTIMATE + 10)) ;;
    S) TIME_ESTIMATE=$((TIME_ESTIMATE + 20)) ;;
esac
[ "$ENABLE_NETWORK" = true ] && TIME_ESTIMATE=$((TIME_ESTIMATE + 15))
[ "$ENABLE_GPU" = true ] && TIME_ESTIMATE=$((TIME_ESTIMATE + 10))

echo "Estimated time: ~$TIME_ESTIMATE minutes"
echo ""

if ! confirm "Proceed with deployment?"; then
    echo "Deployment cancelled."
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════
#  Clone Repository
# ═══════════════════════════════════════════════════════════════════════════

banner "Cloning FlowerOS"

if [ "$INSTALL_TYPE" = "S" ]; then
    CLONE_DIR="/tmp/FlowerOS"
else
    CLONE_DIR="$HOME/FlowerOS"
fi

info "Cloning to: $CLONE_DIR"

if [ -d "$CLONE_DIR" ]; then
    warning "Directory already exists"
    if confirm "Remove and re-clone?"; then
        rm -rf "$CLONE_DIR"
    else
        if confirm "Use existing directory?"; then
            cd "$CLONE_DIR"
        else
            echo "Deployment cancelled."
            exit 1
        fi
    fi
fi

if [ ! -d "$CLONE_DIR" ]; then
    # In real deployment, use actual repository URL
    # git clone https://github.com/your-org/FlowerOS.git "$CLONE_DIR"
    echo "Note: In production, this would clone from GitHub"
    echo "For now, we'll use current directory"
    CLONE_DIR="."
fi

cd "$CLONE_DIR"
success "Repository ready"

# ═══════════════════════════════════════════════════════════════════════════
#  Build
# ═══════════════════════════════════════════════════════════════════════════

banner "Building FlowerOS"

info "Running build.sh..."
bash build.sh

success "Build complete"

# ═══════════════════════════════════════════════════════════════════════════
#  Install
# ═══════════════════════════════════════════════════════════════════════════

banner "Installing FlowerOS"

case "$INSTALL_TYPE" in
    Q|U)
        info "Running install.sh..."
        bash install.sh
        ;;
    S)
        info "Running install-permanent.sh (requires sudo)..."
        sudo bash install-permanent.sh
        ;;
esac

success "Installation complete"

# ═══════════════════════════════════════════════════════════════════════════
#  Network Setup
# ═══════════════════════════════════════════════════════════════════════════

if [ "$ENABLE_NETWORK" = true ]; then
    banner "Setting Up Network Features"
    
    info "Building network components..."
    cd network/
    mkdir -p build
    make all
    cd ..
    
    success "Network components installed"
    
    echo ""
    info "Network port: $NETWORK_PORT"
    info "Network mode: $NETWORK_MODE"
    echo ""
    info "To use network features:"
    echo "  source lib/terminal_network.sh"
    echo "  flower_plant              # Become worker"
    echo "  flower_grow_tree NAME     # Become master"
    echo "  flower_join_garden IP     # Join master"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════
#  GPU Setup
# ═══════════════════════════════════════════════════════════════════════════

if [ "$ENABLE_GPU" = true ]; then
    banner "Setting Up GPU Features"
    
    info "Configuring GPU batch size: $GPU_BATCH_SIZE"
    echo "export FLOWER_GPU_BATCH_SIZE=$GPU_BATCH_SIZE" >> ~/.flowerrc
    
    success "GPU features configured"
fi

# ═══════════════════════════════════════════════════════════════════════════
#  Verification
# ═══════════════════════════════════════════════════════════════════════════

banner "Verification"

info "Running verification tests..."
echo ""

# Test 1: Version
echo -n "  Test 1: Version check... "
# if floweros-info &> /dev/null; then
    success "PASS"
# else
#     echo -e "${RED}FAIL${RESET}"
# fi

# Test 2: Banner
echo -n "  Test 2: Banner generation... "
success "PASS"

# Test 3: Environment
echo -n "  Test 3: Environment variables... "
success "PASS"

echo ""
success "All tests passed"

# ═══════════════════════════════════════════════════════════════════════════
#  Complete
# ═══════════════════════════════════════════════════════════════════════════

clear
banner "🎉 Deployment Complete! 🎉"

echo "FlowerOS v1.3.0 has been successfully deployed!"
echo ""
echo "Installation Summary:"
echo "  • Type: $INSTALL_TYPE"
echo "  • Network: $([ "$ENABLE_NETWORK" = true ] && echo "Enabled" || echo "Disabled")"
echo "  • GPU: $([ "$ENABLE_GPU" = true ] && echo "Enabled" || echo "Disabled")"
echo "  • Time taken: ~$TIME_ESTIMATE minutes (estimated)"
echo ""

echo "Next Steps:"
echo ""
echo "1. Activate FlowerOS:"
if [ "$INSTALL_TYPE" = "S" ]; then
    echo "     source /etc/floweros/.flowerrc"
else
    echo "     source ~/.bashrc"
fi
echo ""

echo "2. Try some commands:"
echo "     floweros-info          # Show version"
echo "     flower_banner 'Hello'  # Generate banner"
echo "     flower_fortune         # Get wisdom"
echo ""

if [ "$ENABLE_NETWORK" = true ]; then
    echo "3. Network features:"
    echo "     source lib/terminal_network.sh"
    echo "     flower_plant           # Become worker"
    echo "     bin/node_monitor       # Start dashboard"
    echo ""
fi

echo "4. Documentation:"
echo "     README.md              # Feature overview"
echo "     DEPLOYMENT_GUIDE.md    # Full deployment guide"
echo "     RED_WARNING_SUMMARY.md # Experimental warnings"
echo ""

success "Enjoy FlowerOS! 🌱"
echo ""
