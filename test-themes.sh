#!/usr/bin/env bash
# FlowerOS Theme System Test (Debian/WSL)

echo ""
echo "==================================="
echo "  FlowerOS Theme System Test"
echo "==================================="
echo ""

# Set environment
export FLOWEROS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLOWEROS_LIB="${FLOWEROS_ROOT}/lib"
export HOME="/mnt/c/Users/Liam"

echo "Step 1: Environment"
echo "  FLOWEROS_ROOT=$FLOWEROS_ROOT"
echo "  FLOWEROS_LIB=$FLOWEROS_LIB"
echo "  HOME=$HOME"
echo ""

echo "Step 2: Check installation"
if [[ -d "$HOME/.floweros" ]]; then
    echo "  ✓ User directory exists"
    ls -la "$HOME/.floweros/"
else
    echo "  ✗ User directory missing"
    exit 1
fi
echo ""

echo "Step 3: Load theme system"
if [[ -f "${FLOWEROS_LIB}/theme_self_init.sh" ]]; then
    source "${FLOWEROS_LIB}/theme_self_init.sh"
    echo "  ✓ Theme system loaded"
else
    echo "  ✗ theme_self_init.sh not found"
    exit 1
fi
echo ""

echo "Step 4: Available themes"
flower_theme_list
echo ""

echo "Step 5: Theme info"
flower_theme_info
echo ""

echo "==================================="
echo "  Test Complete!"
echo "==================================="
echo ""
