#!/usr/bin/env bash
# FlowerOS v1.2.0 Quick Test & Demo
# Tests all features and shows what's working

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║     🌸 FlowerOS v1.2.0 - Quick Test & Demo 🌸                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_CYAN="\033[36m"
C_RESET="\033[0m"

# Image import path
IMAGE_IMPORT_PATH="$SCRIPT_DIR/motd/Import"
IMAGE_OUTPUT_PATH="$SCRIPT_DIR/motd/ascii-output"

test_count=0
pass_count=0

run_test() {
    local name="$1"
    local command="$2"
    
    test_count=$((test_count + 1))
    echo -n "  Testing $name... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${C_GREEN}✓ PASS${C_RESET}"
        pass_count=$((pass_count + 1))
        return 0
    else
        echo -e "${C_RED}✗ FAIL${C_RESET}"
        return 1
    fi
}

echo -e "${C_CYAN}📦 Checking File Structure:${C_RESET}"
echo ""

run_test "Core files" "test -f build.sh && test -f install.sh"
run_test "v1.1 theming" "test -d features/v1.1/theming-pro"
run_test "v1.2 visual" "test -d features/v1.2/visual-experience"
run_test "Image tools" "test -f features/v1.2/visual-experience/image-tools/img2term.sh"
run_test "ASCII art" "test -f features/v1.2/visual-experience/ascii/floweros-medium.txt"
run_test "motd/Import directory" "test -d motd/Import"

echo ""
echo -e "${C_CYAN}🔧 Checking Dependencies:${C_RESET}"
echo ""

run_test "bash" "command -v bash"
run_test "python3" "command -v python3"

echo ""
echo -e "${C_CYAN}🎨 Testing Visual Features:${C_RESET}"
echo ""

# Test ASCII art display
if test -f features/v1.2/visual-experience/ascii/floweros-small.txt; then
    echo -e "${C_YELLOW}  Preview of ASCII art:${C_RESET}"
    echo ""
    cat features/v1.2/visual-experience/ascii/floweros-small.txt
    echo ""
    pass_count=$((pass_count + 1))
else
    echo -e "${C_RED}  ✗ ASCII art files missing${C_RESET}"
fi

test_count=$((test_count + 1))

# Show image import info
echo ""
echo -e "${C_CYAN}📸 Image Import System:${C_RESET}"
echo ""
echo "  Import directory: $IMAGE_IMPORT_PATH"
echo "  Output directory: $IMAGE_OUTPUT_PATH"

# Check for images in Import
image_count=$(find "$IMAGE_IMPORT_PATH" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | wc -l)
if [[ $image_count -gt 0 ]]; then
    echo -e "  ${C_GREEN}✓ Found $image_count image(s) ready to process${C_RESET}"
else
    echo -e "  ${C_YELLOW}ℹ No images in Import directory${C_RESET}"
    echo "    Copy images to: $IMAGE_IMPORT_PATH"
    echo "    Then run: bash process-images.sh"
fi

echo ""
echo -e "${C_CYAN}📊 Test Results:${C_RESET}"
echo ""
echo "  Passed: $pass_count / $test_count"

if [ $pass_count -eq $test_count ]; then
    echo ""
    echo -e "${C_GREEN}✨ All tests passed! FlowerOS is ready!${C_RESET}"
    echo ""
    echo -e "${C_CYAN}🚀 Next Steps:${C_RESET}"
    echo ""
    echo "  1. Install Bash welcome system:"
    echo "     bash features/v1.2/visual-experience/FlowerOS-Welcome.sh install"
    echo ""
    echo "  2. Or try the full experience:"
    echo "     bash features/v1.2/visual-experience/Install-BreathtakingExperience.sh"
    echo ""
    echo "  3. Process custom images:"
    echo "     # Copy images to motd/Import/"
    echo "     bash process-images.sh"
    echo ""
    echo "  4. Then reload:"
    echo "     source ~/.bashrc"
    echo ""
else
    echo ""
    echo -e "${C_YELLOW}⚠ Some tests failed. See above for details.${C_RESET}"
    echo ""
fi

echo "🌺 FlowerOS v1.2.0 - Every terminal session is a garden 🌺"
echo ""
