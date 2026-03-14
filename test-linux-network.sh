#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Network - Linux End User Test
#  Real deployment test on Linux
# ═══════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/banners.sh"

clear

fos_banner_title "🌐 FlowerOS Network Test (Linux) 🌐"

# Check if we're on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    fos_banner_warn "This script is for Linux"
    echo "Current OS: $OSTYPE"
    echo ""
    echo "To test on Linux:"
    echo "  1. Use WSL (Windows Subsystem for Linux)"
    echo "  2. Use a Linux VM"
    echo "  3. Use a Linux machine"
    exit 1
fi

fos_status_ok "Running on Linux"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 1: Check Prerequisites
# ═══════════════════════════════════════════════════════════════════════════

fos_banner_header "Checking Prerequisites" "$_FOS_YELLOW"


# Check g++
if command -v g++ &> /dev/null; then
    fos_status_ok "g++ found: $(g++ --version | head -n1)"
else
    fos_status_fail "g++ not found"
    echo ""
    echo "Install with:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install build-essential"
    exit 1
fi

# Check network directory
if [ -d "network" ]; then
    fos_status_ok "network/ directory exists"
else
    fos_status_fail "network/ directory not found"
    echo "Run this from FlowerOS root directory"
    exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 2: Build Network
# ═══════════════════════════════════════════════════════════════════════════

fos_banner_header "Building Network Components" "$_FOS_YELLOW"

cd network/

# Create build directory
mkdir -p build

echo "Compiling..."
echo ""

# Build manually (since Makefile might have issues)
fos_status "Building libflowernetwork..." "→"
g++ -std=c++17 -Wall -Wextra -O2 -fPIC -c Rooting.cpp -o build/Rooting.o
g++ -shared build/Rooting.o -o build/libflowernetwork.so
fos_status_ok "libflowernetwork.so"

fos_status "Building node_monitor..." "→"
g++ -std=c++17 -Wall -Wextra -O2 node_monitor.cpp -o build/node_monitor -lpthread
fos_status_ok "node_monitor"

fos_status "Building node_discovery..." "→"
g++ -std=c++17 -Wall -Wextra -O2 node_discovery.cpp -o build/node_discovery -lpthread
fos_status_ok "node_discovery"

fos_status "Building terminal_node..." "→"
g++ -std=c++17 -Wall -Wextra -O2 terminal_node.cpp -o build/terminal_node -lpthread
fos_status_ok "terminal_node"

cd ..

echo ""
fos_status_ok "Build complete!"
echo ""
sleep 2

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 3: Interactive Menu
# ═══════════════════════════════════════════════════════════════════════════

while true; do
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  FlowerOS Network - What do you want to test?                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  [1] Show node monitor (live dashboard)"
    echo "  [2] Run node discovery (interactive menu)"
    echo "  [3] Test terminal network functions"
    echo "  [4] Full multi-terminal test guide"
    echo "  [5] Quick localhost test"
    echo "  [Q] Quit"
    echo ""
    read -p "Your choice: " choice
    
    case "$choice" in
        1)
            echo ""
            echo "═══ Node Monitor ═══"
            echo ""
            echo "This shows:"
            echo "  • Node info (hostname, IP, port)"
            echo "  • Network stats (upload/download)"
            echo "  • Hardware allocation (CPU/memory)"
            echo "  • Live updates every 1 second"
            echo ""
            echo "🔴 EXPERIMENTAL FEATURE"
            echo ""
            read -p "Port (default 7777): " port
            port=${port:-7777}
            echo ""
            echo "Starting monitor on port $port..."
            echo "Press Ctrl+C to exit"
            echo ""
            sleep 2
            ./network/build/node_monitor "$port"
            ;;
            
        2)
            echo ""
            echo "═══ Node Discovery ═══"
            echo ""
            echo "Interactive menu to:"
            echo "  • Load hard-coded network nodes"
            echo "  • Scan local network"
            echo "  • Show all relations"
            echo "  • Auto-link to nodes"
            echo ""
            echo "🔴 EXPERIMENTAL FEATURE"
            echo ""
            read -p "Press Enter to start..."
            ./network/build/node_discovery
            ;;
            
        3)
            echo ""
            echo "═══ Terminal Network Functions ═══"
            echo ""
            
            if [ ! -f "lib/terminal_network.sh" ]; then
                echo "✗ lib/terminal_network.sh not found"
                read -p "Press Enter to continue..."
                continue
            fi
            
            echo "Loading functions..."
            source lib/terminal_network.sh
            echo "✓ Loaded"
            echo ""
            
            echo "Available commands:"
            echo "  flower_plant              - Become worker node"
            echo "  flower_grow_tree <name>   - Become master node"
            echo "  flower_join_garden <ip>   - Join network"
            echo "  flower_network_status     - Show status"
            echo ""
            
            while true; do
                echo ""
                echo "What to do?"
                echo "  [p] Plant (become worker)"
                echo "  [t] Tree (become master)"
                echo "  [j] Join network"
                echo "  [s] Show status"
                echo "  [b] Back to main menu"
                echo ""
                read -p "Choice: " subchoice
                
                case "$subchoice" in
                    p)
                        echo ""
                        flower_plant
                        ;;
                    t)
                        echo ""
                        read -p "Cluster name: " cluster
                        cluster=${cluster:-test_cluster}
                        flower_grow_tree "$cluster"
                        ;;
                    j)
                        echo ""
                        read -p "Master IP: " ip
                        ip=${ip:-127.0.0.1}
                        flower_join_garden "$ip"
                        ;;
                    s)
                        echo ""
                        flower_network_status
                        ;;
                    b)
                        break
                        ;;
                esac
            done
            ;;
            
        4)
            clear
            echo ""
            echo "╔════════════════════════════════════════════════════════════════╗"
            echo "║  Multi-Terminal Test Guide                                     ║"
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo ""
            echo "For full network test, open 3 terminals:"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Terminal 1 (Master Node):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  cd $(pwd)"
            echo "  source lib/terminal_network.sh"
            echo "  flower_grow_tree my_cluster"
            echo "  ./network/build/node_monitor 7777"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Terminal 2 (Worker Node):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  cd $(pwd)"
            echo "  source lib/terminal_network.sh"
            echo "  flower_join_garden 127.0.0.1"
            echo "  ./network/build/node_monitor 7778"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Terminal 3 (Discovery):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  cd $(pwd)"
            echo "  ./network/build/node_discovery"
            echo "  > Choose: 1 (Load relationships)"
            echo "  > Choose: 3 (Show all)"
            echo "  > Choose: 5 (Auto-link)"
            echo ""
            echo "This will demonstrate:"
            echo "  ✓ Network formation"
            echo "  ✓ Node discovery"
            echo "  ✓ Live monitoring"
            echo "  ✓ Connection status"
            echo ""
            read -p "Press Enter to continue..."
            ;;
            
        5)
            echo ""
            echo "═══ Quick Localhost Test ═══"
            echo ""
            echo "This will:"
            echo "  1. Load terminal network"
            echo "  2. Plant this terminal as worker"
            echo "  3. Show network status"
            echo "  4. Run monitor for 5 seconds"
            echo ""
            read -p "Continue? [y/N] " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo ""
                echo "→ Loading terminal network..."
                source lib/terminal_network.sh
                echo "  ✓ Loaded"
                sleep 1
                
                echo ""
                echo "→ Planting as worker node..."
                flower_plant
                sleep 1
                
                echo ""
                echo "→ Network status:"
                flower_network_status
                sleep 2
                
                echo ""
                echo "→ Starting monitor (5 seconds)..."
                timeout 5 ./network/build/node_monitor 7777 || true
                
                echo ""
                echo "✓ Quick test complete!"
            fi
            
            echo ""
            read -p "Press Enter to continue..."
            ;;
            
        q|Q)
            echo ""
            echo "Bye! 🌱"
            exit 0
            ;;
            
        *)
            echo ""
            echo "Invalid choice"
            sleep 1
            ;;
    esac
done
