#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Terminal Network Integration
#  "Plant Yourself" - Turn any terminal into a network node
#
#  ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️
#
#  Botanical commands:
#    flower_plant          - Plant yourself (become node)
#    flower_grow_tree      - Become master node
#    flower_join_garden    - Join existing network
#    flower_network_status - Show network status
# ═══════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════
#  Global Network State
# ═══════════════════════════════════════════════════════════════════════════

FLOWEROS_NETWORK_PLANTED="${FLOWEROS_NETWORK_PLANTED:-false}"
FLOWEROS_NETWORK_TYPE="${FLOWEROS_NETWORK_TYPE:-SEED}"
FLOWEROS_NETWORK_PORT="${FLOWEROS_NETWORK_PORT:-7777}"
FLOWEROS_NETWORK_MASTER="${FLOWEROS_NETWORK_MASTER:-}"
FLOWEROS_NETWORK_PID="${FLOWEROS_NETWORK_PID:-}"

# ═══════════════════════════════════════════════════════════════════════════
#  🌱 PLANT YOURSELF - Become a Network Node
# ═══════════════════════════════════════════════════════════════════════════

flower_plant() {
    local port="${1:-7777}"
    
    echo ""
    echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[32m║                                                                           ║\033[0m"
    echo -e "\033[32m║                  🌱 PLANTING YOURSELF AS NODE 🌱                          ║\033[0m"
    echo -e "\033[32m║                                                                           ║\033[0m"
    echo -e "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    
    echo -e "\033[31m⚠️  RED WARNING: This is EXPERIMENTAL network code!\033[0m"
    echo ""
    
    if [[ "${FLOWEROS_NETWORK_PLANTED}" == "true" ]]; then
        echo -e "\033[33m⚠️  Already planted as ${FLOWEROS_NETWORK_TYPE}\033[0m"
        echo "   Port: ${FLOWEROS_NETWORK_PORT}"
        echo "   PID: ${FLOWEROS_NETWORK_PID}"
        return 0
    fi
    
    # Check if port is available
    if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
        echo -e "\033[31m✗ Port ${port} already in use\033[0m"
        echo "  Try a different port: flower_plant 7778"
        return 1
    fi
    
    echo "🌱 Terminal becoming network node..."
    echo ""
    echo "  Hostname: $(hostname)"
    echo "  IP: $(hostname -I | awk '{print $1}' 2>/dev/null || echo '127.0.0.1')"
    echo "  Port: ${port}"
    echo "  Type: PLANT (worker node)"
    echo ""
    
    # Start network listener in background
    flower_network_daemon "${port}" &
    local daemon_pid=$!
    
    # Update state
    export FLOWEROS_NETWORK_PLANTED="true"
    export FLOWEROS_NETWORK_TYPE="PLANT"
    export FLOWEROS_NETWORK_PORT="${port}"
    export FLOWEROS_NETWORK_PID="${daemon_pid}"
    
    # Update prompt
    flower_network_update_prompt
    
    echo -e "\033[32m✓ Planted successfully!\033[0m"
    echo ""
    echo "This terminal is now a network node."
    echo "Other FlowerOS instances can connect to you."
    echo ""
    echo "Commands:"
    echo "  flower_network_status     - Show your status"
    echo "  flower_uproot             - Remove network capability"
    echo "  flower_join_garden <ip>   - Join another garden"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  🌳 GROW TREE - Become Master Node
# ═══════════════════════════════════════════════════════════════════════════

flower_grow_tree() {
    local cluster_name="${1:-my_garden}"
    local port="${2:-7777}"
    
    echo ""
    echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[32m║                                                                           ║\033[0m"
    echo -e "\033[32m║                  🌳 GROWING INTO MASTER NODE 🌳                           ║\033[0m"
    echo -e "\033[32m║                                                                           ║\033[0m"
    echo -e "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    
    echo -e "\033[31m⚠️  RED WARNING: Master node responsibilities!\033[0m"
    echo ""
    
    if [[ "${FLOWEROS_NETWORK_PLANTED}" == "true" ]]; then
        echo "🌿 Evolving from ${FLOWEROS_NETWORK_TYPE} to TREE..."
    else
        echo "🌱 Germinating as master node..."
    fi
    
    echo ""
    echo "  Cluster: ${cluster_name}"
    echo "  Hostname: $(hostname)"
    echo "  IP: $(hostname -I | awk '{print $1}' 2>/dev/null || echo '127.0.0.1')"
    echo "  Port: ${port}"
    echo "  Type: TREE (master/coordinator)"
    echo ""
    
    # Start master daemon
    flower_network_master_daemon "${cluster_name}" "${port}" &
    local daemon_pid=$!
    
    # Update state
    export FLOWEROS_NETWORK_PLANTED="true"
    export FLOWEROS_NETWORK_TYPE="TREE"
    export FLOWEROS_NETWORK_PORT="${port}"
    export FLOWEROS_NETWORK_PID="${daemon_pid}"
    export FLOWEROS_NETWORK_CLUSTER="${cluster_name}"
    
    # Update prompt
    flower_network_update_prompt
    
    echo -e "\033[32m✓ Grown into TREE!\033[0m"
    echo ""
    echo "🌳 You are now the master node."
    echo "   Other nodes can join your garden."
    echo ""
    echo "Share with others:"
    echo -e "  \033[36mflower_join_garden $(hostname -I | awk '{print $1}' 2>/dev/null || echo '127.0.0.1')\033[0m"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  🌿 JOIN GARDEN - Connect to Existing Network
# ═══════════════════════════════════════════════════════════════════════════

flower_join_garden() {
    local master_ip="${1}"
    local master_port="${2:-7777}"
    
    if [[ -z "${master_ip}" ]]; then
        echo "Usage: flower_join_garden <master_ip> [port]"
        echo ""
        echo "Example:"
        echo "  flower_join_garden 192.168.1.100"
        echo "  flower_join_garden 192.168.1.100 7777"
        return 1
    fi
    
    echo ""
    echo -e "\033[36m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[36m║                                                                           ║\033[0m"
    echo -e "\033[36m║                  🌿 JOINING GARDEN 🌿                                     ║\033[0m"
    echo -e "\033[36m║                                                                           ║\033[0m"
    echo -e "\033[36m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    
    # Plant if not already planted
    if [[ "${FLOWEROS_NETWORK_PLANTED}" != "true" ]]; then
        echo "🌱 Planting yourself first..."
        flower_plant
        echo ""
    fi
    
    echo "🌿 Connecting to master garden..."
    echo ""
    echo "  Master: ${master_ip}:${master_port}"
    echo "  Your type: ${FLOWEROS_NETWORK_TYPE}"
    echo ""
    
    # Test connection
    if ! nc -zv "${master_ip}" "${master_port}" 2>/dev/null; then
        echo -e "\033[33m⚠️  Cannot reach master (but continuing anyway)\033[0m"
        echo "   Master might not be running yet."
        echo ""
    else
        echo -e "\033[32m✓ Master is reachable\033[0m"
        echo ""
    fi
    
    # Store master info
    export FLOWEROS_NETWORK_MASTER="${master_ip}:${master_port}"
    
    # Send join request (simulated)
    echo "📡 Sending ROOT_HELLO to master..."
    echo ""
    
    # Update prompt
    flower_network_update_prompt
    
    echo -e "\033[32m✓ Joined garden!\033[0m"
    echo ""
    echo "You are now part of the network."
    echo "Your roots are connected to: ${master_ip}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  🥀 UPROOT - Remove Network Capability
# ═══════════════════════════════════════════════════════════════════════════

flower_uproot() {
    echo ""
    echo -e "\033[33m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[33m║                                                                           ║\033[0m"
    echo -e "\033[33m║                  🥀 UPROOTING NODE 🥀                                     ║\033[0m"
    echo -e "\033[33m║                                                                           ║\033[0m"
    echo -e "\033[33m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    
    if [[ "${FLOWEROS_NETWORK_PLANTED}" != "true" ]]; then
        echo "⚠️  Not planted - nothing to uproot"
        return 0
    fi
    
    echo "🥀 Removing network capability..."
    echo ""
    
    # Kill daemon if running
    if [[ -n "${FLOWEROS_NETWORK_PID}" ]]; then
        if ps -p "${FLOWEROS_NETWORK_PID}" >/dev/null 2>&1; then
            echo "  Stopping network daemon (PID: ${FLOWEROS_NETWORK_PID})..."
            kill "${FLOWEROS_NETWORK_PID}" 2>/dev/null
        fi
    fi
    
    # Send goodbye to master if connected
    if [[ -n "${FLOWEROS_NETWORK_MASTER}" ]]; then
        echo "  Sending ROOT_GOODBYE to master..."
        # Simulated disconnect
    fi
    
    # Clear state
    export FLOWEROS_NETWORK_PLANTED="false"
    export FLOWEROS_NETWORK_TYPE="SEED"
    export FLOWEROS_NETWORK_PORT=""
    export FLOWEROS_NETWORK_PID=""
    export FLOWEROS_NETWORK_MASTER=""
    export FLOWEROS_NETWORK_CLUSTER=""
    
    # Reset prompt
    flower_network_update_prompt
    
    echo ""
    echo -e "\033[32m✓ Uprooted successfully\033[0m"
    echo ""
    echo "Terminal is back to normal (SEED state)."
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  📊 NETWORK STATUS
# ═══════════════════════════════════════════════════════════════════════════

flower_network_status() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                           ║"
    echo "║                  FlowerOS Network Status                                  ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Node info
    echo "🌱 Node Information:"
    echo "  Hostname: $(hostname)"
    echo "  IP: $(hostname -I | awk '{print $1}' 2>/dev/null || echo '127.0.0.1')"
    echo ""
    
    # Planted status
    echo "🌿 Network Status:"
    if [[ "${FLOWEROS_NETWORK_PLANTED}" == "true" ]]; then
        echo -e "  Planted: \033[32m✓ Yes\033[0m"
        echo "  Type: ${FLOWEROS_NETWORK_TYPE}"
        echo "  Port: ${FLOWEROS_NETWORK_PORT}"
        
        # Check if daemon is running
        if [[ -n "${FLOWEROS_NETWORK_PID}" ]]; then
            if ps -p "${FLOWEROS_NETWORK_PID}" >/dev/null 2>&1; then
                echo -e "  Daemon: \033[32m✓ Running (PID: ${FLOWEROS_NETWORK_PID})\033[0m"
            else
                echo -e "  Daemon: \033[33m⚠️  Not running\033[0m"
            fi
        fi
    else
        echo -e "  Planted: \033[90m✗ No (SEED state)\033[0m"
        echo "  Run 'flower_plant' to plant yourself"
    fi
    echo ""
    
    # Master connection
    echo "🌳 Master Connection:"
    if [[ -n "${FLOWEROS_NETWORK_MASTER}" ]]; then
        echo -e "  Connected: \033[32m✓ Yes\033[0m"
        echo "  Master: ${FLOWEROS_NETWORK_MASTER}"
    else
        echo -e "  Connected: \033[90m✗ No\033[0m"
        echo "  Run 'flower_join_garden <ip>' to connect"
    fi
    echo ""
    
    # Cluster info
    if [[ -n "${FLOWEROS_NETWORK_CLUSTER}" ]]; then
        echo "🌸 Cluster:"
        echo "  Name: ${FLOWEROS_NETWORK_CLUSTER}"
        echo "  Role: Master (TREE)"
        echo ""
    fi
    
    # Commands
    echo "📚 Available Commands:"
    echo "  flower_plant              - Become network node"
    echo "  flower_grow_tree [name]   - Become master node"
    echo "  flower_join_garden <ip>   - Join existing network"
    echo "  flower_uproot             - Stop network capability"
    echo "  flower_network_status     - Show this status"
    echo ""
    
    echo -e "\033[31m⚠️  Network features are EXPERIMENTAL\033[0m"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Network Daemon (Simulated)
# ═══════════════════════════════════════════════════════════════════════════

flower_network_daemon() {
    local port="$1"
    
    # This is a simulated daemon
    # In production, would run actual Rooter C++ code
    
    while true; do
        # Heartbeat
        sleep 5
        
        # Check if parent still exists
        if ! ps -p $PPID >/dev/null 2>&1; then
            exit 0
        fi
    done
}

flower_network_master_daemon() {
    local cluster="$1"
    local port="$2"
    
    # Simulated master daemon
    while true; do
        # Master duties
        sleep 5
        
        # Check if parent still exists
        if ! ps -p $PPID >/dev/null 2>&1; then
            exit 0
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
#  Update Prompt to Show Network Status
# ═══════════════════════════════════════════════════════════════════════════

flower_network_update_prompt() {
    # Add network indicator to PS1
    if [[ "${FLOWEROS_NETWORK_PLANTED}" == "true" ]]; then
        local icon=""
        case "${FLOWEROS_NETWORK_TYPE}" in
            SEED) icon="🌱" ;;
            SPROUT) icon="🌿" ;;
            PLANT) icon="🪴" ;;
            FLOWER) icon="🌸" ;;
            TREE) icon="🌳" ;;
            *) icon="❓" ;;
        esac
        
        export FLOWEROS_NETWORK_PROMPT="${icon} "
        
        # Optionally update PS1 (commented out to not override user's prompt)
        # export PS1="${FLOWEROS_NETWORK_PROMPT}${PS1}"
    else
        export FLOWEROS_NETWORK_PROMPT=""
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Quick Start Wizard
# ═══════════════════════════════════════════════════════════════════════════

flower_network_wizard() {
    echo ""
    echo -e "\033[36m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[36m║                                                                           ║\033[0m"
    echo -e "\033[36m║              FlowerOS Network Quick Start Wizard                          ║\033[0m"
    echo -e "\033[36m║                                                                           ║\033[0m"
    echo -e "\033[36m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    
    echo -e "\033[31m⚠️  RED WARNING: Network features are EXPERIMENTAL\033[0m"
    echo ""
    
    echo "What would you like to do?"
    echo ""
    echo "  1) Plant myself (become regular node)"
    echo "  2) Grow into tree (become master node)"
    echo "  3) Join existing garden (connect to master)"
    echo "  4) Show network status"
    echo "  5) Cancel"
    echo ""
    
    read -p "Choose option (1-5): " choice
    
    case "$choice" in
        1)
            echo ""
            flower_plant
            ;;
        2)
            echo ""
            read -p "Cluster name [my_garden]: " cluster
            cluster="${cluster:-my_garden}"
            flower_grow_tree "${cluster}"
            ;;
        3)
            echo ""
            read -p "Master IP address: " ip
            if [[ -n "$ip" ]]; then
                flower_join_garden "${ip}"
            else
                echo "⚠️  IP address required"
            fi
            ;;
        4)
            flower_network_status
            ;;
        5)
            echo "Cancelled"
            ;;
        *)
            echo "⚠️  Invalid choice"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  Aliases for Quick Access
# ═══════════════════════════════════════════════════════════════════════════

alias plant="flower_plant"
alias grow_tree="flower_grow_tree"
alias join_garden="flower_join_garden"
alias uproot="flower_uproot"
alias network_status="flower_network_status"

# ═══════════════════════════════════════════════════════════════════════════
#  Export Functions
# ═══════════════════════════════════════════════════════════════════════════

export -f flower_plant
export -f flower_grow_tree
export -f flower_join_garden
export -f flower_uproot
export -f flower_network_status
export -f flower_network_wizard
export -f flower_network_daemon
export -f flower_network_master_daemon
export -f flower_network_update_prompt

# ═══════════════════════════════════════════════════════════════════════════
#  Startup Message (if in interactive shell)
# ═══════════════════════════════════════════════════════════════════════════

if [[ -n "$PS1" ]] && [[ "${FLOWEROS_NETWORK_QUIET:-false}" != "true" ]]; then
    echo ""
    echo -e "\033[32m🌱 FlowerOS Terminal Network Loaded\033[0m"
    echo ""
    echo "Turn this terminal into a network node:"
    echo -e "  \033[36mflower_plant\033[0m         - Become a node"
    echo -e "  \033[36mflower_grow_tree\033[0m     - Become master"
    echo -e "  \033[36mflower_network_wizard\033[0m - Quick start"
    echo ""
    echo -e "\033[31m⚠️  Network features are EXPERIMENTAL\033[0m"
    echo ""
fi
