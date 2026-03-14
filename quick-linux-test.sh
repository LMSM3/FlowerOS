#!/bin/bash
# FlowerOS Network - One Command Test

echo "🌐 FlowerOS Network - Quick Build & Test"
echo ""

# Build
echo "Building network components..."
cd network && mkdir -p build && \
g++ -std=c++17 -O2 node_monitor.cpp -o build/node_monitor -lpthread && \
g++ -std=c++17 -O2 node_discovery.cpp -o build/node_discovery -lpthread && \
echo "✓ Build complete!" && cd .. || exit 1

echo ""
echo "Choose test:"
echo "  1. Node Monitor (live dashboard)"
echo "  2. Node Discovery (interactive)"
echo ""
read -p "Choice [1/2]: " choice

case "$choice" in
    1)
        echo ""
        echo "Starting node monitor on port 7777..."
        echo "Press Ctrl+C to exit"
        echo ""
        ./network/build/node_monitor 7777
        ;;
    2)
        echo ""
        ./network/build/node_discovery
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
