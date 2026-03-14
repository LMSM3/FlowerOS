#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS - Quick Network Connection Test
#  Try to connect to the network right now!
# ═══════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/banners.sh"

clear

FOS_BANNER_COLOR="$_FOS_CYAN" fos_banner_title "🌐 FlowerOS Network - Quick Connection Test 🌐"

# Check if network is built
if [ ! -f "network/build/node_monitor" ]; then
    echo -e "${_FOS_YELLOW}Network not built yet. Building now...${_FOS_RESET}"
    echo ""

    cd network/
    mkdir -p build

    echo "Compiling network components..."
    make all 2>&1 | tail -n 10

    if [ -f "build/node_monitor" ]; then
        echo ""
        fos_status_ok "Build successful!"
    else
        echo ""
        fos_banner_error "Build failed"
        echo "Try manually:"
        echo "  cd network/"
        echo "  make all"
        exit 1
    fi

    cd ..
    echo ""
fi

# Load terminal network functions
echo -e "${_FOS_CYAN}Loading network functions...${_FOS_RESET}"
if [ -f "lib/terminal_network.sh" ]; then
    source lib/terminal_network.sh
    fos_status_ok "Network functions loaded"
else
    fos_banner_error "lib/terminal_network.sh not found"
    exit 1
fi

echo ""
echo -e "${_FOS_CYAN}What do you want to do?${_FOS_RESET}"
echo ""
echo "  ${_FOS_GREEN}[1]${_FOS_RESET} Become a worker node (plant yourself)"
echo "  ${_FOS_GREEN}[2]${_FOS_RESET} Become a master node (grow a tree)"
echo "  ${_FOS_GREEN}[3]${_FOS_RESET} Join existing network (join garden)"
echo "  ${_FOS_GREEN}[4]${_FOS_RESET} Show network status"
echo "  ${_FOS_GREEN}[5]${_FOS_RESET} Start node monitor dashboard"
echo "  ${_FOS_GREEN}[6]${_FOS_RESET} Run node discovery"
echo "  ${_FOS_GREEN}[7]${_FOS_RESET} Show all options"
echo "  ${_FOS_GREEN}[Q]${_FOS_RESET} Quit"
echo ""

read -p "Your choice: " choice
echo ""

case "$choice" in
    1)
        fos_banner_header "Planting yourself as a worker node" "$_FOS_CYAN"
        flower_plant
        echo ""
        fos_status_ok "You are now a worker node!"
        echo ""
        echo "Next: Check status with option [4]"
        ;;
        
    2)
        fos_banner_header "Growing as a master node" "$_FOS_CYAN"
        read -p "Enter cluster name (e.g., test_cluster): " cluster_name
        cluster_name=${cluster_name:-test_cluster}
        echo ""
        flower_grow_tree "$cluster_name"
        echo ""
        fos_status_ok "You are now a master node!"
        echo ""
        echo "Next: Start monitor with option [5]"
        ;;
        
    3)
        fos_banner_header "Joining existing network" "$_FOS_CYAN"
        read -p "Enter master IP (e.g., 192.168.1.100 or 127.0.0.1): " master_ip
        master_ip=${master_ip:-127.0.0.1}
        echo ""
        flower_join_garden "$master_ip"
        echo ""
        fos_status_ok "Joining network!"
        echo ""
        echo "Next: Check status with option [4]"
        ;;
        
    4)
        fos_banner_header "Network Status" "$_FOS_CYAN"
        flower_network_status
        echo ""
        ;;
        
    5)
        fos_banner_header "Starting Node Monitor" "$_FOS_CYAN"
        read -p "Port number (default 7777): " port
        port=${port:-7777}
        echo ""
        echo -e "${_FOS_YELLOW}Starting monitor on port $port...${_FOS_RESET}"
        echo -e "${_FOS_YELLOW}Press Ctrl+C to stop${_FOS_RESET}"
        echo ""
        sleep 1
        ./network/build/node_monitor "$port"
        ;;
        
    6)
        fos_banner_header "Node Discovery" "$_FOS_CYAN"
        echo -e "${_FOS_YELLOW}This shows all nodes in the network${_FOS_RESET}"
        echo -e "${_FOS_YELLOW}Use the interactive menu to explore${_FOS_RESET}"
        echo ""
        read -p "Press Enter to start..."
        echo ""
        ./network/build/node_discovery
        ;;
        
    7)
        fos_banner_header "All Available Commands" "$_FOS_CYAN"
        echo -e "${_FOS_GREEN}Terminal Network Functions:${_FOS_RESET}"
        echo "  flower_plant              - Become worker node"
        echo "  flower_grow_tree <name>   - Become master node"
        echo "  flower_join_garden <ip>   - Join existing network"
        echo "  flower_network_status     - Show network status"
        echo ""
        echo -e "${_FOS_GREEN}Monitoring Tools:${_FOS_RESET}"
        echo "  ./network/build/node_monitor <port>   - Live dashboard"
        echo "  ./network/build/node_discovery        - Node discovery"
        echo ""
        echo -e "${_FOS_GREEN}Direct Usage:${_FOS_RESET}"
        echo "  source lib/terminal_network.sh"
        echo "  flower_plant"
        echo ""
        ;;
        
    q|Q)
        echo "Bye! 🌱"
        exit 0
        ;;
        
    *)
        echo -e "${_FOS_RED}Invalid choice${_FOS_RESET}"
        ;;
esac

echo ""
echo -e "${_FOS_YELLOW}Run this script again to try other options!${_FOS_RESET}"
echo ""
fos_banner_experimental
echo ""
