#!/usr/bin/env bash
# FlowerOS Complete System Test
# Tests all C programs, scripts, and features

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_CYAN="\033[36m"
C_GRAY="\033[90m"
C_RESET="\033[0m"

total=0
passed=0
failed=0

test_item() {
    local name="$1"
    local command="$2"
    
    total=$((total + 1))
    echo -n "  Testing $name... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${C_GREEN}✓${C_RESET}"
        passed=$((passed + 1))
        return 0
    else
        echo -e "${C_RED}✗${C_RESET}"
        failed=$((failed + 1))
        return 1
    fi
}

echo ""
echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_CYAN}║     🌸 FlowerOS Complete System Test v1.2.0 🌸                          ║${C_RESET}"
echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════════╝${C_RESET}"
echo ""

# Fix line endings first
echo -e "${C_YELLOW}🔧 Fixing line endings...${C_RESET}"
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null
find . -name "*.sh" -type f -exec chmod +x {} \;
echo -e "${C_GREEN}✓ Fixed${C_RESET}"
echo ""

# Test C programs
echo -e "${C_CYAN}🔧 Testing C Programs:${C_RESET}"
echo ""

if command -v gcc >/dev/null 2>&1; then
    echo -e "${C_GREEN}✓ gcc found${C_RESET}"
    echo ""
    
    # Test colortest.c
    echo -n "  Compiling colortest.c... "
    if gcc -O2 -std=c11 -Wall -Wextra -o colortest colortest.c 2>/dev/null; then
        echo -e "${C_GREEN}✓${C_RESET}"
        test_item "colortest execution" "./colortest"
        passed=$((passed + 1))
    else
        echo -e "${C_RED}✗${C_RESET}"
        failed=$((failed + 1))
    fi
    
    # Test other C programs
    for prog in random animate banner fortune; do
        if [[ -f "${prog}.c" ]]; then
            echo -n "  Compiling ${prog}.c... "
            if gcc -O2 -std=c11 -Wall -Wextra -o "$prog" "${prog}.c" 2>/dev/null; then
                echo -e "${C_GREEN}✓${C_RESET}"
                passed=$((passed + 1))
            else
                echo -e "${C_RED}✗${C_RESET}"
                failed=$((failed + 1))
            fi
            total=$((total + 1))
        fi
    done
else
    echo -e "${C_YELLOW}⚠ gcc not found (C programs skipped)${C_RESET}"
fi

echo ""

# Test file structure
echo -e "${C_CYAN}📦 Testing File Structure:${C_RESET}"
echo ""

test_item "Core files" "test -f build.sh && test -f install.sh"
test_item "v1.1 theming" "test -d features/v1.1/theming-pro"
test_item "v1.2 visual" "test -d features/v1.2/visual-experience"
test_item "Image tools" "test -f features/v1.2/visual-experience/image-tools/img2term.sh"
test_item "ASCII art" "test -f features/v1.2/visual-experience/ascii/floweros-medium.txt"
test_item "motd/Import" "test -d motd/Import"
test_item "Config system" "test -f floweros-config.sh"

echo ""

# Test dependencies
echo -e "${C_CYAN}🔧 Testing Dependencies:${C_RESET}"
echo ""

test_item "bash" "command -v bash"
test_item "python3" "command -v python3"

echo ""

# Test installed commands
echo -e "${C_CYAN}🌸 Testing Installed Commands:${C_RESET}"
echo ""

test_item "floweros-tree" "command -v floweros-tree"
test_item "flower" "command -v flower"
test_item "f" "command -v f"
test_item "F" "command -v F"
test_item "floweros-config" "command -v floweros-config"

echo ""

# Test config system
echo -e "${C_CYAN}⚙️  Testing Config System:${C_RESET}"
echo ""

if command -v floweros-config >/dev/null 2>&1; then
    test_item "config show" "floweros-config show"
    test_item "config get" "floweros-config get FLOWEROS_VERSION"
else
    echo -e "${C_YELLOW}⚠ floweros-config not installed${C_RESET}"
fi

echo ""

# Test image system
echo -e "${C_CYAN}📸 Testing Image System:${C_RESET}"
echo ""

image_count=$(find motd/Import -type f \( -iname "*.png" -o -iname "*.jpg" \) 2>/dev/null | wc -l)
echo "  Images in motd/Import: $image_count"

if [[ $image_count -gt 0 ]]; then
    echo -e "  ${C_GREEN}✓ Ready to process${C_RESET}"
else
    echo -e "  ${C_YELLOW}ℹ No images (add some!)${C_RESET}"
fi

echo ""

# Summary
echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_CYAN}║     📊 Test Results                                                      ║${C_RESET}"
echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════════╝${C_RESET}"
echo ""
echo "  Total:  $total"
echo -e "  ${C_GREEN}Passed: $passed${C_RESET}"
if [[ $failed -gt 0 ]]; then
    echo -e "  ${C_RED}Failed: $failed${C_RESET}"
fi
echo ""

if [[ $failed -eq 0 ]]; then
    echo -e "${C_GREEN}✨ All tests passed! FlowerOS is fully operational! ✨${C_RESET}"
    echo ""
    echo -e "${C_CYAN}Quick Commands:${C_RESET}"
    echo "  f                    Show file tree"
    echo "  floweros-config show Show preferences"
    echo "  bash build-motd.sh   Build ASCII art"
    echo ""
else
    echo -e "${C_YELLOW}⚠ Some tests failed. Check above for details.${C_RESET}"
    echo ""
fi

echo -e "${C_CYAN}🌺 FlowerOS v1.2.0 - Every terminal session is a garden 🌺${C_RESET}"
echo ""
