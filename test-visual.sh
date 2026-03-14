#!/usr/bin/env bash
# FlowerOS v1.2.4 - Quick Visual System Test
# Tests visual.c compilation and basic functionality

set -eu

echo "🌸 FlowerOS Visual System - Quick Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Color codes
g='\033[32m' r='\033[31m' y='\033[33m' c='\033[36m' z='\033[0m'

# Test 1: Check if visual.c exists
echo -n "Checking lib/visual.c... "
if [[ -f lib/visual.c ]]; then
  echo -e "${g}✓${z}"
else
  echo -e "${r}✗${z} Not found!"
  exit 1
fi

# Test 2: Check if gcc is available
echo -n "Checking gcc compiler... "
if command -v gcc &> /dev/null; then
  echo -e "${g}✓${z} $(gcc --version | head -n1)"
else
  echo -e "${y}⚠${z} gcc not found (WSL/Git Bash required on Windows)"
fi

# Test 3: Try to compile
echo -n "Compiling visual.c... "
if gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c 2>&1 | grep -q "error:"; then
  echo -e "${r}✗${z} Compilation failed"
  gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c
  exit 1
elif command -v gcc &> /dev/null; then
  gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c 2>/dev/null || true
  if [[ -x ./visual ]] || [[ -x ./visual.exe ]]; then
    echo -e "${g}✓${z}"
  else
    echo -e "${y}⚠${z} Could not verify binary"
  fi
else
  echo -e "${y}⚠${z} Skipped (no gcc)"
fi

# Test 4: Check if binary exists
echo -n "Checking visual binary... "
if [[ -x ./visual ]] || [[ -x ./visual.exe ]]; then
  echo -e "${g}✓${z}"
  
  # Test 5: Run help
  echo -n "Testing help output... "
  if ./visual 2>&1 | grep -q "FlowerOS Visual Output System"; then
    echo -e "${g}✓${z}"
  else
    echo -e "${r}✗${z}"
  fi
  
  # Test 6: Run bar chart
  echo -n "Testing bar chart mode... "
  if ./visual bar 2>&1 | grep -q "Test Results"; then
    echo -e "${g}✓${z}"
  else
    echo -e "${r}✗${z}"
  fi
  
  echo ""
  echo -e "${c}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${z}"
  echo -e "${g}✓ Visual system ready!${z}"
  echo ""
  echo "Try these commands:"
  echo -e "  ${c}./visual demo${z}          # See all visualizations"
  echo -e "  ${c}./visual bar${z}           # Bar chart"
  echo -e "  ${c}./visual table${z}         # ASCII table"
  echo -e "  ${c}bash lib/visualize.sh demo${z}  # Wrapper demo"
else
  echo -e "${y}⚠${z} Not found (compile first)"
  echo ""
  echo "To build:"
  echo "  gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c"
fi

echo ""
