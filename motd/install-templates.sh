#!/bin/bash
# ============================================================================
# FlowerOS MOTD Template System Installer
# Code Injection Style - Self-contained installer
# ============================================================================

CYAN='\033[96m'
GREEN='\033[92m'
YELLOW='\033[93m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}🌸 FlowerOS MOTD Template System${RESET}\n"

# Installation directory
INSTALL_DIR="${HOME}/.local/share/floweros/motd"
mkdir -p "${INSTALL_DIR}"

# Copy templates
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "${SCRIPT_DIR}/sysinfo.py" "${INSTALL_DIR}/"
cp "${SCRIPT_DIR}/weather.py" "${INSTALL_DIR}/"
cp "${SCRIPT_DIR}/stocks.py" "${INSTALL_DIR}/"

chmod +x "${INSTALL_DIR}"/*.py

# Create config directory
mkdir -p "${HOME}/.config/floweros"

# Create default stocks watchlist
if [ ! -f "${HOME}/.config/floweros/stocks.conf" ]; then
    cat > "${HOME}/.config/floweros/stocks.conf" << 'EOF'
# FlowerOS Stock Watchlist
# Add one symbol per line
AAPL
MSFT
GOOGL
BTC-USD
ETH-USD
EOF
fi

# Create MOTD template selector config
cat > "${HOME}/.config/floweros/motd.conf" << 'EOF'
# FlowerOS MOTD Configuration
# Set DEFAULT_TEMPLATE to: sysinfo, weather, or stocks
DEFAULT_TEMPLATE=sysinfo

# Enable/disable auto-display
AUTO_DISPLAY=true
EOF

echo -e "${GREEN}✓ Templates installed to: ${INSTALL_DIR}${RESET}"
echo -e "${GREEN}✓ Configuration created: ~/.config/floweros/${RESET}\n"

echo -e "${YELLOW}Usage:${RESET}"
echo -e "  python3 ${INSTALL_DIR}/sysinfo.py    # System information"
echo -e "  python3 ${INSTALL_DIR}/weather.py    # Weather forecast"
echo -e "  python3 ${INSTALL_DIR}/stocks.py     # Market watch"
echo -e ""
echo -e "${YELLOW}Add to your .bashrc for auto-display!${RESET}\n"
