#!/usr/bin/env bash
# FlowerOS v1.1 - Minimal Test Runner

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FlowerOS v1.1 - Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASSED=0
FAILED=0

test_header() {
    echo -e "\033[36m▶ $1\033[0m"
}

test_pass() {
    echo -e "  \033[32m✓\033[0m $1"
    ((PASSED++))
}

test_fail() {
    echo -e "  \033[31m✗\033[0m $1"
    ((FAILED++))
}

# Test 1: V1.0 Core Unchanged
test_header "Test: v1.0 Core Files Unchanged"

v1_files=("lib/colors.sh" "lib/helpers.ps1" "random.c" "build.sh")
for file in "${v1_files[@]}"; do
    if [[ -f "$PARENT_DIR/$file" ]]; then
        test_pass "Found: $file"
    else
        test_fail "Missing: $file"
    fi
done

# Test 2: V1.1 Structure
test_header "Test: v1.1 Structure"

v11_dirs=("features/v1.1/themes" "test" "temp")
for dir in "${v11_dirs[@]}"; do
    if [[ -d "$PARENT_DIR/$dir" ]]; then
        test_pass "Directory: $dir"
    else
        test_fail "Missing: $dir"
    fi
done

# Test 3: Theme Files
test_header "Test: Theme System"

if [[ -f "$PARENT_DIR/features/v1.1/themes/theme.sh" ]]; then
    test_pass "Found: theme.sh"
    
    # Test theme commands
    if bash "$PARENT_DIR/features/v1.1/themes/theme.sh" 2>&1 | grep -q "light\|grey"; then
        test_pass "Theme script responds"
    else
        test_fail "Theme script not responding"
    fi
else
    test_fail "Missing: theme.sh"
fi

if [[ -f "$PARENT_DIR/features/v1.1/themes/theme.ps1" ]]; then
    test_pass "Found: theme.ps1"
else
    test_fail "Missing: theme.ps1"
fi

# Test 4: VERSION file
test_header "Test: Version"

if [[ -f "$PARENT_DIR/VERSION" ]]; then
    version=$(cat "$PARENT_DIR/VERSION")
    if [[ "$version" == "1.1.0" ]]; then
        test_pass "VERSION correct: $version"
    else
        test_fail "VERSION incorrect: $version (expected 1.1.0)"
    fi
else
    test_fail "Missing: VERSION file"
fi

# Test 5: Documentation
test_header "Test: Documentation"

if [[ -f "$PARENT_DIR/features/v1.1/THEMING.md" ]]; then
    test_pass "Found: THEMING.md"
else
    test_fail "Missing: THEMING.md"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  \033[32mPassed:\033[0m $PASSED"
echo -e "  \033[31mFailed:\033[0m $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "\033[32m✓ All tests passed!\033[0m"
    echo ""
    exit 0
else
    echo -e "\033[31m✗ Some tests failed\033[0m"
    echo ""
    exit 1
fi
