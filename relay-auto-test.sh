#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS - Quick Relay Test with Auto Buddy Windows
#  One command to test entire relay system
# ═══════════════════════════════════════════════════════════════════════════

clear
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║        🌐 FLOWEROS RELAY TEST - AUTO BUDDY WINDOWS 🌐                     ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "This will automatically:"
echo "  1. Build network components (if needed)"
echo "  2. Open 3 terminal windows"
echo "  3. Configure each as: Master → Relay → Worker"
echo "  4. Start network monitoring"
echo ""
echo "Press Ctrl+C in this terminal to close all windows"
echo ""
read -p "Press Enter to start..."

# Build if needed
if [ ! -f "network/build/node_monitor" ]; then
    echo ""
    echo "Building network components..."
    cd network/
    mkdir -p build
    g++ -std=c++17 -O2 -c Rooting.cpp -o build/Rooting.o 2>/dev/null
    g++ -std=c++17 -O2 node_monitor.cpp build/Rooting.o -o build/node_monitor -lpthread 2>/dev/null
    cd ..
    echo "✓ Build complete"
    echo ""
fi

# Open buddy windows
echo "Opening buddy windows..."
bash buddy-windows.sh open

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Buddy windows are now open!"
echo ""
echo "  Watch the 3 terminal windows to see:"
echo "    • Master node broadcasting"
echo "    • Relay node forwarding messages"
echo "    • Worker node receiving relayed data"
echo ""
echo "  Press Ctrl+C here to close all windows"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

# Wait for Ctrl+C
trap 'echo ""; echo "Closing buddy windows..."; bash buddy-windows.sh close; exit 0' SIGINT
while true; do
    sleep 1
done
