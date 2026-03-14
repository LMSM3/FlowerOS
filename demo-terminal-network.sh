#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Terminal Network Demo
#  "Plant Yourself" - Turn terminals into network nodes
#
#  ⚠️ RED WARNING: EXPERIMENTAL DEMONSTRATION
# ═══════════════════════════════════════════════════════════════════════════

clear

echo ""
echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[32m║                                                                           ║\033[0m"
echo -e "\033[32m║         🌱 FLOWEROS TERMINAL NETWORK DEMONSTRATION 🌱                     ║\033[0m"
echo -e "\033[32m║                                                                           ║\033[0m"
echo -e "\033[32m║              "Plant Yourself" - Turn Terminals into Nodes                ║\033[0m"
echo -e "\033[32m║                                                                           ║\033[0m"
echo -e "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
sleep 2

echo -e "\033[31m⚠️  RED WARNING: This demonstrates EXPERIMENTAL network features\033[0m"
echo ""
sleep 2

echo "═══ THE CONCEPT ═══"
echo ""
echo "Every terminal window can become a network node!"
echo ""
echo -e "\033[36mBotanical Metaphor:\033[0m"
echo "  🌱 Plant yourself - Terminal becomes a node"
echo "  🌳 Grow a tree - Terminal becomes master"
echo "  🌿 Join a garden - Connect to existing network"
echo "  🥀 Uproot - Stop network capability"
echo ""
sleep 3

echo "Each terminal instance can emit network capabilities,"
echo "creating a distributed FlowerOS across all your terminals!"
echo ""
sleep 2

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     TERMINAL NETWORK COMMANDS                             ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo -e "\033[33m🌱 PLANT YOURSELF\033[0m"
echo ""
echo "  Command: flower_plant [port]"
echo ""
echo "  What it does:"
echo "    • Starts network listener on this terminal"
echo "    • Makes terminal a PLANT (worker node)"
echo "    • Other FlowerOS instances can connect to you"
echo "    • Updates your prompt with 🪴 indicator"
echo ""
echo "  Example:"
echo -e "    \033[36m$ flower_plant\033[0m"
echo "    🌱 Terminal becoming network node..."
echo "    ✓ Planted successfully!"
echo ""
sleep 3

echo -e "\033[33m🌳 GROW TREE\033[0m"
echo ""
echo "  Command: flower_grow_tree [cluster_name] [port]"
echo ""
echo "  What it does:"
echo "    • Makes this terminal the master node"
echo "    • Terminal type becomes TREE"
echo "    • Forms a new cluster"
echo "    • Other nodes can join your garden"
echo "    • Updates prompt with 🌳 indicator"
echo ""
echo "  Example:"
echo -e "    \033[36m$ flower_grow_tree research_cluster\033[0m"
echo "    🌳 Growing into master node..."
echo "    ✓ Grown into TREE!"
echo ""
sleep 3

echo -e "\033[33m🌿 JOIN GARDEN\033[0m"
echo ""
echo "  Command: flower_join_garden <master_ip> [port]"
echo ""
echo "  What it does:"
echo "    • Connects this terminal to a master node"
echo "    • Establishes root connection"
echo "    • Sends ROOT_HELLO message"
echo "    • Joins the distributed network"
echo ""
echo "  Example:"
echo -e "    \033[36m$ flower_join_garden 192.168.1.100\033[0m"
echo "    🌿 Connecting to master garden..."
echo "    ✓ Joined garden!"
echo ""
sleep 3

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     PRACTICAL EXAMPLES                                    ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo -e "\033[33mExample 1: Single Terminal Planting\033[0m"
echo ""
echo "Terminal 1 (your main terminal):"
echo ""
echo "  $ source lib/terminal_network.sh"
echo "  🌱 FlowerOS Terminal Network Loaded"
echo ""
echo "  $ flower_plant"
echo "  🌱 Planting yourself as node..."
echo "  ✓ Planted successfully!"
echo "  Port: 7777"
echo ""
echo "Now this terminal is a network node!"
echo ""
sleep 3

echo -e "\033[33mExample 2: Master/Worker Setup\033[0m"
echo ""
echo "Terminal 1 (master):"
echo "  $ flower_grow_tree lab_cluster"
echo "  🌳 Growing into master node..."
echo "  ✓ Grown into TREE!"
echo "  Share: flower_join_garden 192.168.1.50"
echo ""
echo "Terminal 2 (worker):"
echo "  $ flower_join_garden 192.168.1.50"
echo "  🌿 Joining garden..."
echo "  ✓ Joined garden!"
echo ""
echo "Now you have a 2-node distributed FlowerOS!"
echo ""
sleep 3

echo -e "\033[33mExample 3: Multi-Terminal Cluster\033[0m"
echo ""
echo "Terminal 1 (master):"
echo "  $ flower_grow_tree research"
echo "  🌳 Master node ready"
echo ""
echo "Terminal 2 (worker 1):"
echo "  $ flower_plant"
echo "  $ flower_join_garden 192.168.1.50"
echo "  🪴 Connected to master"
echo ""
echo "Terminal 3 (worker 2):"
echo "  $ flower_plant"
echo "  $ flower_join_garden 192.168.1.50"
echo "  🪴 Connected to master"
echo ""
echo "Terminal 4 (worker 3):"
echo "  $ flower_plant"
echo "  $ flower_join_garden 192.168.1.50"
echo "  🪴 Connected to master"
echo ""
echo "Result: 4-node cluster across 4 terminal windows!"
echo ""
sleep 3

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     C++ TERMINAL NODE                                     ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo "For more power, use the C++ terminal node executable:"
echo ""
echo -e "\033[33mBuild:\033[0m"
echo "  cd network/"
echo "  make all"
echo "  make install"
echo ""
sleep 1

echo -e "\033[33mUsage:\033[0m"
echo ""
echo "  ./terminal_node plant"
echo "    → Become regular node"
echo ""
echo "  ./terminal_node grow_tree research"
echo "    → Become master of 'research' cluster"
echo ""
echo "  ./terminal_node join 192.168.1.100"
echo "    → Join master at IP address"
echo ""
echo "  ./terminal_node"
echo "    → Interactive mode (wizard)"
echo ""
sleep 3

echo -e "\033[33mExample Session:\033[0m"
echo ""
echo "  $ ./terminal_node grow_tree lab_cluster"
echo ""
echo "  🌱 FlowerOS Terminal Network Instance"
echo "     Version: 1.3.0-EXPERIMENTAL"
echo ""
echo "  🌳 GROWING INTO MASTER NODE"
echo ""
echo "  ⚠️  RED WARNING: Initializing EXPERIMENTAL network routing"
echo "     This feature is NOT production ready!"
echo ""
echo "  🌱 Root network initialized"
echo "     Node: mycomputer"
echo "     IP: 192.168.1.50"
echo "     Port: 7777"
echo ""
echo "  ✓ Cluster formed: lab_cluster"
echo "     Node type: TREE (master)"
echo ""
echo "  🌳 Terminal is now the master node."
echo "     Cluster: lab_cluster"
echo ""
echo "  Running... (Press Ctrl+C to stop)"
echo ""
sleep 3

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     NODE STATUS & MONITORING                              ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo "Check your network status:"
echo ""
echo "  $ flower_network_status"
echo ""
echo "  ╔═══════════════════════════════════════════════════════════════════╗"
echo "  ║              FlowerOS Network Status                              ║"
echo "  ╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "  🌱 Node Information:"
echo "    Hostname: mycomputer"
echo "    IP: 192.168.1.50"
echo ""
echo "  🌿 Network Status:"
echo "    Planted: ✓ Yes"
echo "    Type: PLANT"
echo "    Port: 7777"
echo "    Daemon: ✓ Running (PID: 12345)"
echo ""
echo "  🌳 Master Connection:"
echo "    Connected: ✓ Yes"
echo "    Master: 192.168.1.100:7777"
echo ""
echo "  📚 Available Commands:"
echo "    flower_plant              - Become network node"
echo "    flower_grow_tree [name]   - Become master node"
echo "    flower_join_garden <ip>   - Join existing network"
echo "    flower_uproot             - Stop network capability"
echo "    flower_network_status     - Show this status"
echo ""
sleep 3

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     NODE TYPES (BOTANICAL)                                ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo "🌱 SEED"
echo "  • Default state (not planted)"
echo "  • No network capability"
echo "  • Ready to be planted"
echo ""
sleep 1

echo "🌿 SPROUT"
echo "  • Establishing connections"
echo "  • Network initializing"
echo "  • Transitional state"
echo ""
sleep 1

echo "🪴 PLANT"
echo "  • Worker node"
echo "  • Established and connected"
echo "  • Can process distributed work"
echo ""
sleep 1

echo "🌸 FLOWER"
echo "  • GPU-capable node"
echo "  • Can process GPU batches"
echo "  • Produces results"
echo ""
sleep 1

echo "🌳 TREE"
echo "  • Master/coordinator node"
echo "  • Forms clusters"
echo "  • Manages other nodes"
echo "  • Distributes work"
echo ""
sleep 1

echo "🥀 WILTED"
echo "  • Disconnected/failed node"
echo "  • Lost connection"
echo "  • Needs to reconnect"
echo ""
sleep 2

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     USE CASES                                             ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo -e "\033[33m1. Development Environment\033[0m"
echo ""
echo "  All your terminal windows connected:"
echo "  • Terminal 1: Master node (code)"
echo "  • Terminal 2: Worker node (build)"
echo "  • Terminal 3: Worker node (test)"
echo "  • Terminal 4: Worker node (monitor)"
echo ""
echo "  All synchronized and networked!"
echo ""
sleep 2

echo -e "\033[33m2. Lab Environment\033[0m"
echo ""
echo "  Multiple machines in lab:"
echo "  • Workstation 1: Master (192.168.1.100)"
echo "  • Workstation 2: Worker (connects to master)"
echo "  • Workstation 3: Worker (connects to master)"
echo "  • Laptop: Worker (connects to master)"
echo ""
echo "  Distributed FlowerOS across entire lab!"
echo ""
sleep 2

echo -e "\033[33m3. Research Computing\033[0m"
echo ""
echo "  Form computational clusters:"
echo "  • Terminal on head node: Master"
echo "  • Terminals on compute nodes: Workers"
echo "  • All coordinated through root network"
echo "  • Distribute GPU processing"
echo ""
sleep 2

clear

echo ""
echo -e "\033[31m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[31m║                                                                           ║\033[0m"
echo -e "\033[31m║                     RED WARNINGS                                          ║\033[0m"
echo -e "\033[31m║                                                                           ║\033[0m"
echo -e "\033[31m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
sleep 1

echo -e "\033[31m⚠️  EXPERIMENTAL FEATURES\033[0m"
echo ""
echo "The terminal network capability is EXPERIMENTAL:"
echo ""
echo "  ✗ No encryption (plain text)"
echo "  ✗ No authentication (anyone can connect)"
echo "  ✗ No authorization (no access control)"
echo "  ✗ Limited error handling"
echo "  ✗ Not tested at scale"
echo "  ✗ Memory leaks possible"
echo "  ✗ Race conditions in threading"
echo ""
echo -e "\033[31mDO NOT USE IN PRODUCTION!\033[0m"
echo -e "\033[31mDO NOT USE ON UNTRUSTED NETWORKS!\033[0m"
echo ""
sleep 3

clear

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     QUICK START                                           ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo "Try it now in your current terminal:"
echo ""
echo "1. Load terminal network:"
echo -e "   \033[36m$ source lib/terminal_network.sh\033[0m"
echo ""
echo "2. Plant yourself:"
echo -e "   \033[36m$ flower_plant\033[0m"
echo ""
echo "3. Check status:"
echo -e "   \033[36m$ flower_network_status\033[0m"
echo ""
echo "4. When done:"
echo -e "   \033[36m$ flower_uproot\033[0m"
echo ""
sleep 2

echo "Or use the wizard:"
echo -e "   \033[36m$ flower_network_wizard\033[0m"
echo ""
sleep 2

echo "Or build C++ version:"
echo "   $ cd network/"
echo "   $ make all"
echo -e "   $ ./build/terminal_node\033[0m"
echo ""
sleep 2

clear

echo ""
echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[32m║                                                                           ║\033[0m"
echo -e "\033[32m║                     SUMMARY                                               ║\033[0m"
echo -e "\033[32m║                                                                           ║\033[0m"
echo -e "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
sleep 1

echo "FlowerOS Terminal Network:"
echo ""
echo "  ✓ Turn any terminal into a network node"
echo "  ✓ Plant yourself with one command"
echo "  ✓ Grow into master node (TREE)"
echo "  ✓ Join existing gardens"
echo "  ✓ Form distributed clusters"
echo "  ✓ Botanical node types"
echo "  ✓ Bash and C++ interfaces"
echo ""
echo -e "\033[31mStatus: EXPERIMENTAL - NOT PRODUCTION READY\033[0m"
echo ""
sleep 2

echo "Files created:"
echo "  • lib/terminal_network.sh    - Bash integration"
echo "  • network/terminal_node.cpp  - C++ executable"
echo "  • Updated network/Makefile   - Builds terminal node"
echo ""
sleep 2

echo ""
echo -e "\033[36m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║                                                                           ║\033[0m"
echo -e "\033[36m║  🌱 Every terminal is a seed waiting to be planted 🌱                     ║\033[0m"
echo -e "\033[36m║  🌳 Every terminal can grow into a tree 🌳                                ║\033[0m"
echo -e "\033[36m║  🌸 Every network is a garden 🌸                                          ║\033[0m"
echo -e "\033[36m║                                                                           ║\033[0m"
echo -e "\033[36m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

echo -e "\033[90m[Demo complete. Try: source lib/terminal_network.sh && flower_plant]\033[0m"
echo ""
