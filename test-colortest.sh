#!/usr/bin/env bash
# Test colortest.c compilation and execution

echo "🔧 Testing colortest.c"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if gcc exists
if ! command -v gcc >/dev/null 2>&1; then
    echo "✗ gcc not found"
    echo "  Install: sudo apt-get install build-essential"
    exit 1
fi

echo "✓ gcc found"

# Compile
echo -n "Compiling... "
if gcc -O2 -std=c11 -Wall -Wextra -o colortest colortest.c 2>colortest.err; then
    echo "✓"
else
    echo "✗"
    echo ""
    echo "Compilation errors:"
    cat colortest.err
    rm -f colortest.err
    exit 1
fi

rm -f colortest.err

# Test execution
echo -n "Testing execution... "
if ./colortest >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ colortest.c is working!"
echo ""
echo "Run: ./colortest"
echo ""

# Show preview
echo "Preview:"
./colortest | head -30
echo "..."
