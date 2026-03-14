#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS - Buddy Window Presets
#  Different window configurations for different tests
# ═══════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/banners.sh"

show_menu() {
    clear
    fos_banner_box "FlowerOS Buddy Window Presets"
    echo "Choose a test configuration:"
    echo ""
    echo "  [1] Relay Test (3 windows)"
    echo "      Master → Relay → Worker"
    echo "      Ports: 7777, 7778, 7779"
    echo ""
    echo "  [2] Cluster Test (4 windows)"
    echo "      Master + 3 Workers"
    echo "      Ports: 7777, 7778, 7779, 7780"
    echo ""
    echo "  [3] Discovery Test (2 windows)"
    echo "      Monitor + Discovery"
    echo "      Interactive network exploration"
    echo ""
    echo "  [4] GPU Cluster (3 windows)"
    echo "      Master + GPU Worker + Monitor"
    echo "      For GPU batch testing"
    echo ""
    echo "  [5] Development (2 windows)"
    echo "      Code editor + Test terminal"
    echo "      Side-by-side development"
    echo ""
    echo "  [C] Close all windows"
    echo "  [Q] Quit"
    echo ""
    read -p "Your choice: " choice
}

# ═══════════════════════════════════════════════════════════════════════════
#  Preset 1: Relay Test
# ═══════════════════════════════════════════════════════════════════════════

preset_relay() {
    echo "Opening Relay Test configuration..."
    bash buddy-windows.sh open
}

# ═══════════════════════════════════════════════════════════════════════════
#  Preset 2: Cluster Test (4 windows)
# ═══════════════════════════════════════════════════════════════════════════

preset_cluster() {
    local terminal=$(bash buddy-windows.sh detect 2>/dev/null || echo "gnome-terminal")
    echo "Opening Cluster Test configuration (4 windows)..."
    
    # Master
    gnome-terminal --title="Master (7777)" --geometry=60x20+0+0 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_grow_tree cluster_test
        ./network/build/node_monitor 7777
    " &
    
    # Worker 1
    gnome-terminal --title="Worker-1 (7778)" --geometry=60x20+500+0 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_join_garden 127.0.0.1
        ./network/build/node_monitor 7778
    " &
    
    # Worker 2
    gnome-terminal --title="Worker-2 (7779)" --geometry=60x20+0+400 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_join_garden 127.0.0.1
        ./network/build/node_monitor 7779
    " &
    
    # Worker 3
    gnome-terminal --title="Worker-3 (7780)" --geometry=60x20+500+400 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_join_garden 127.0.0.1
        ./network/build/node_monitor 7780
    " &
    
    echo "✓ Cluster test windows opened (4 windows in 2x2 grid)"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Preset 3: Discovery Test
# ═══════════════════════════════════════════════════════════════════════════

preset_discovery() {
    echo "Opening Discovery Test configuration..."
    
    # Monitor
    gnome-terminal --title="Network Monitor" --geometry=80x30+0+0 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_plant
        ./network/build/node_monitor 7777
    " &
    
    # Discovery
    gnome-terminal --title="Node Discovery" --geometry=80x30+700+0 -- bash -c "
        cd '$SCRIPT_DIR'
        echo 'Interactive Node Discovery'
        echo ''
        ./network/build/node_discovery
    " &
    
    echo "✓ Discovery test windows opened (2 windows side-by-side)"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Preset 4: GPU Cluster
# ═══════════════════════════════════════════════════════════════════════════

preset_gpu() {
    echo "Opening GPU Cluster configuration..."
    
    # Master
    gnome-terminal --title="GPU Master (7777)" --geometry=70x24+0+0 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_grow_tree gpu_cluster
        ./network/build/node_monitor 7777
    " &
    
    # GPU Worker
    gnome-terminal --title="GPU Worker (7778)" --geometry=70x24+600+0 -- bash -c "
        cd '$SCRIPT_DIR'
        source lib/terminal_network.sh
        flower_join_garden 127.0.0.1
        echo ''
        echo 'GPU batch operations ready'
        echo ''
        ./network/build/node_monitor 7778
    " &
    
    # Batch Monitor
    gnome-terminal --title="Batch Monitor" --geometry=70x24+1200+0 -- bash -c "
        cd '$SCRIPT_DIR'
        echo 'GPU Batch Monitor'
        echo ''
        echo 'Commands:'
        echo '  flower_gpu_batch ascii 1000'
        echo '  flower_gpu_batch banner \"Test\" 500'
        echo ''
        bash
    " &
    
    echo "✓ GPU cluster windows opened (3 windows for GPU testing)"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Preset 5: Development
# ═══════════════════════════════════════════════════════════════════════════

preset_development() {
    echo "Opening Development configuration..."
    
    # Editor
    gnome-terminal --title="FlowerOS Editor" --geometry=120x40+0+0 -- bash -c "
        cd '$SCRIPT_DIR'
        echo 'FlowerOS Development Environment'
        echo ''
        echo 'Files ready to edit:'
        echo '  network/Rooting.cpp'
        echo '  network/Rooter.hpp'
        echo '  lib/terminal_network.sh'
        echo ''
        bash
    " &
    
    # Test Terminal
    gnome-terminal --title="Test Terminal" --geometry=80x40+1000+0 -- bash -c "
        cd '$SCRIPT_DIR'
        echo 'FlowerOS Test Terminal'
        echo ''
        echo 'Quick tests:'
        echo '  bash test-internet-relay.sh'
        echo '  bash relay-auto-test.sh'
        echo ''
        bash
    " &
    
    echo "✓ Development windows opened (editor + test terminal)"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main Loop
# ═══════════════════════════════════════════════════════════════════════════

while true; do
    show_menu
    
    case "$choice" in
        1)
            preset_relay
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            preset_cluster
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            preset_discovery
            echo ""
            read -p "Press Enter to continue..."
            ;;
        4)
            preset_gpu
            echo ""
            read -p "Press Enter to continue..."
            ;;
        5)
            preset_development
            echo ""
            read -p "Press Enter to continue..."
            ;;
        c|C)
            bash buddy-windows.sh close
            echo ""
            read -p "Press Enter to continue..."
            ;;
        q|Q)
            echo ""
            echo "Bye! 🌱"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            sleep 1
            ;;
    esac
done
