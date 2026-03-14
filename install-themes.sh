#!/usr/bin/env bash
# FlowerOS Theme Installation Script
# Run this to install themes in current shell

set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║         🌱 FlowerOS Theme Installation 🌱                                 ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Set environment variables
echo "Step 1: Setting up environment variables..."
export FLOWEROS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLOWEROS_LIB="${FLOWEROS_ROOT}/lib"
export FLOWEROS_BIN="${FLOWEROS_ROOT}/bin"
export FLOWEROS_ASCII="${FLOWEROS_ROOT}/ascii"

echo "✓ FLOWEROS_ROOT=${FLOWEROS_ROOT}"
echo "✓ FLOWEROS_LIB=${FLOWEROS_LIB}"
echo ""

# Step 2: Source theme system
echo "Step 2: Loading theme system..."
if [[ -f "${FLOWEROS_LIB}/theme_self_init.sh" ]]; then
    source "${FLOWEROS_LIB}/theme_self_init.sh"
    echo "✓ Theme system loaded"
else
    echo "✗ Error: theme_self_init.sh not found"
    exit 1
fi
echo ""

# Step 3: Run initialization
echo "Step 3: Initializing theme system..."
flower_theme_self_init "true" "false"
echo ""

# Step 4: Load default theme
echo "Step 4: Loading default theme..."
flower_theme_load "garden"
echo "✓ Garden theme loaded"
echo ""

# Step 5: Show status
echo "Step 5: Theme system status..."
flower_theme_info
echo ""

# Step 6: List available themes
echo "Step 6: Available themes..."
flower_theme_list
echo ""

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                    ✓ Installation Complete! ✓                            ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "Test commands:"
echo "  flower_theme_list           # List themes"
echo "  flower_theme_set spring     # Change theme"
echo "  flower_theme_info           # Show info"
echo ""

echo "🌸 Theme system ready!"
echo ""
